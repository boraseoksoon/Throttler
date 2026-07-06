//
//  Throttler.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-09-08.
//

/// Options for debouncing an operation.
public enum DebounceOptions: Sendable {
    /// The default debounce behavior.
    case `default`
    /// Run the operation immediately and debounce subsequent calls.
    case runFirst
}

/// Options for throttling an operation.
public enum ThrottleOptions: Sendable {
    /// The default throttle behavior.
    case `default`
    /// Guarantee that the last call is executed after the throttle window.
    case ensureLast
}

/// The execution context used to run a scheduled operation.
public enum ActorType: Sendable {
    /// A legacy alias for `.taskContext`. It does not hop back to the caller's actor.
    case currentActor
    /// A package-owned serial actor. Operations sharing it run serialized.
    case ownedActor
    /// The scheduled task's own context, with no extra actor hop.
    case taskContext
    /// The main actor. A synchronous closure is guaranteed to run on the main actor.
    /// An asynchronous closure is called from the main actor, but a nonisolated async
    /// closure body still runs on the global executor; isolate the closure with
    /// `@MainActor` at the call site when its body must be main-actor-isolated.
    case mainActor

    func run(_ operation: SynchronousOperation) async {
        switch self {
        case .mainActor:
            await Self.runOnMainActor(operation)
        case .ownedActor:
            await Self.runOnOwnedActor(operation)
        case .currentActor, .taskContext:
            operation.run()
        }
    }

    func run(_ operation: @escaping @Sendable () async -> Void) async {
        switch self {
        case .mainActor:
            await Self.runOnMainActor(operation)
        case .ownedActor:
            await Self.runOnOwnedActor(operation)
        case .currentActor, .taskContext:
            await operation()
        }
    }

    func run(_ operation: @escaping @Sendable () async throws -> Void) async throws {
        switch self {
        case .mainActor:
            try await Self.runOnMainActor(operation)
        case .ownedActor:
            try await Self.runOnOwnedActor(operation)
        case .currentActor, .taskContext:
            try await operation()
        }
    }

    @MainActor
    private static func runOnMainActor(_ operation: SynchronousOperation) {
        operation.run()
    }

    @MainActor
    private static func runOnMainActor(_ operation: @escaping @Sendable () async -> Void) async {
        await operation()
    }

    @MainActor
    private static func runOnMainActor(_ operation: @escaping @Sendable () async throws -> Void) async throws {
        try await operation()
    }

    private static func runOnOwnedActor(_ operation: SynchronousOperation) async {
        await ownedActorExecutor.run(operation)
    }

    private static func runOnOwnedActor(_ operation: @escaping @Sendable () async -> Void) async {
        await ownedActorExecutor.run(operation)
    }

    private static func runOnOwnedActor(_ operation: @escaping @Sendable () async throws -> Void) async throws {
        try await ownedActorExecutor.run(operation)
    }
}

private let ownedActorExecutor = OwnedActorExecutor()

private actor OwnedActorExecutor {
    func run(_ operation: SynchronousOperation) {
        operation.run()
    }

    func run(_ operation: @escaping @Sendable () async -> Void) async {
        await operation()
    }

    func run(_ operation: @escaping @Sendable () async throws -> Void) async throws {
        try await operation()
    }
}

let throttler = Throttler()

/// The sentinel default for `identifier`; it marks calls that should be grouped
/// by their call site (file, line, and column) instead of an explicit identifier.
public let callSiteDefaultIdentifier = "__throttler.call.site.default__"

func resolveCallSiteIdentifier(_ identifier: String, fileID: String, line: UInt, column: UInt) -> String {
    identifier == callSiteDefaultIdentifier ? "\(fileID):\(line):\(column)" : identifier
}

final class SynchronousOperation: @unchecked Sendable {
    let run: () -> Void

    init(_ run: @escaping () -> Void) {
        self.run = run
    }
}

func throttlerErrorWrapping(
    _ operation: @escaping @Sendable () async throws -> Void,
    onError: (@Sendable (Error) -> Void)?
) -> @Sendable () async -> Void {
    {
        do {
            try await operation()
        } catch {
            onError?(error)
        }
    }
}

actor Throttler {
    private enum ScheduleKind {
        case debounce
        case throttle
    }

    private struct ScheduleKey: Hashable {
        let kind: ScheduleKind
        let identifier: String
    }

    private struct ScheduleEntry {
        var pending: Task<Void, Never>?
        var pendingGeneration: UInt64 = 0
        var lastFire: ContinuousClock.Instant?
    }

    private var entries: [ScheduleKey: ScheduleEntry] = [:]
    private let clock = ContinuousClock()
    private var nextGeneration: UInt64 = 0

    func debounce(
        _ duration: Duration,
        identifier: String,
        by actor: ActorType,
        option: DebounceOptions,
        operation: @escaping @Sendable () async -> Void
    ) async {
        if duration <= .zero {
            await actor.run(operation)
            return
        }

        let key = ScheduleKey(kind: .debounce, identifier: identifier)
        let now = clock.now

        if option == .runFirst, canRunDebounceImmediately(entry: entries[key], now: now, duration: duration) {
            stampLastFire(key: key, at: now)
            await actor.run(operation)
            stampLastFire(key: key, at: clock.now)
            return
        }

        scheduleTrailing(key: key, after: duration, actor: actor, operation: operation)
    }

    func throttle(
        _ duration: Duration,
        identifier: String,
        by actor: ActorType,
        option: ThrottleOptions,
        operation: @escaping @Sendable () async -> Void
    ) async {
        if duration <= .zero {
            await actor.run(operation)
            return
        }

        let key = ScheduleKey(kind: .throttle, identifier: identifier)
        let now = clock.now
        let entry = entries[key]

        if canRunThrottleImmediately(entry: entry, now: now, duration: duration) {
            cancelPending(key: key)
            stampLastFire(key: key, at: now)
            await actor.run(operation)
            return
        }

        guard option == .ensureLast else { return }

        scheduleTrailing(
            key: key,
            after: remainingThrottleDuration(entry: entry, now: now, duration: duration),
            actor: actor,
            operation: operation
        )
    }

    func delay(
        _ duration: Duration,
        by actor: ActorType,
        operation: @escaping @Sendable () async -> Void
    ) async {
        if duration <= .zero {
            await actor.run(operation)
            return
        }

        await sleep(for: duration, clock: clock)
        guard !Task.isCancelled else { return }
        await actor.run(operation)
    }

    private func canRunDebounceImmediately(
        entry: ScheduleEntry?,
        now: ContinuousClock.Instant,
        duration: Duration
    ) -> Bool {
        guard let entry else { return true }
        guard entry.pending == nil else { return false }
        guard let lastFire = entry.lastFire else { return true }
        return (now - lastFire) >= duration
    }

    private func canRunThrottleImmediately(
        entry: ScheduleEntry?,
        now: ContinuousClock.Instant,
        duration: Duration
    ) -> Bool {
        guard let lastFire = entry?.lastFire else { return true }
        return (now - lastFire) >= duration
    }

    private func remainingThrottleDuration(
        entry: ScheduleEntry?,
        now: ContinuousClock.Instant,
        duration: Duration
    ) -> Duration {
        guard let lastFire = entry?.lastFire else { return .zero }
        return duration - (now - lastFire)
    }

    private func scheduleTrailing(
        key: ScheduleKey,
        after duration: Duration,
        actor: ActorType,
        operation: @escaping @Sendable () async -> Void
    ) {
        var entry = entries[key] ?? ScheduleEntry()
        entry.pending?.cancel()

        nextGeneration &+= 1
        let generation = nextGeneration
        entry.pendingGeneration = generation

        let clock = self.clock
        entry.pending = Task { [weak self] in
            await sleep(for: duration, clock: clock)
            guard !Task.isCancelled else { return }
            guard let self else { return }
            guard await self.markPendingReady(key: key, generation: generation) else { return }

            await actor.run(operation)
        }
        entries[key] = entry
    }

    private func markPendingReady(key: ScheduleKey, generation: UInt64) -> Bool {
        guard var entry = entries[key] else { return false }
        guard entry.pendingGeneration == generation else { return false }
        entry.pending = nil
        entry.lastFire = clock.now
        entries[key] = entry
        return true
    }

    private func stampLastFire(key: ScheduleKey, at instant: ContinuousClock.Instant) {
        var entry = entries[key] ?? ScheduleEntry()
        entry.lastFire = instant
        entries[key] = entry
    }

    private func cancelPending(key: ScheduleKey) {
        guard var entry = entries[key] else { return }
        entry.pending?.cancel()
        entry.pending = nil
        entries[key] = entry
    }
}

@Sendable
func sleep(for duration: Duration, clock: ContinuousClock) async {
    guard duration > .zero else { return }
    try? await clock.sleep(for: duration)
}
