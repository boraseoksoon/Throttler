//
//  Throttler.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-09-08.
//

import Foundation

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

public enum ActorType: Sendable {
    case currentActor
    case ownedActor
    case taskContext
    case mainActor

    func run(_ operation: LegacyOperation) async {
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

    @MainActor
    private static func runOnMainActor(_ operation: LegacyOperation) {
        operation.run()
    }

    @MainActor
    private static func runOnMainActor(_ operation: @escaping @Sendable () async -> Void) async {
        await operation()
    }

    private static func runOnOwnedActor(_ operation: LegacyOperation) async {
        await ownedActorExecutor.run(operation)
    }

    private static func runOnOwnedActor(_ operation: @escaping @Sendable () async -> Void) async {
        await ownedActorExecutor.run(operation)
    }
}

private let ownedActorExecutor = OwnedActorExecutor()

private actor OwnedActorExecutor {
    func run(_ operation: LegacyOperation) {
        operation.run()
    }

    func run(_ operation: @escaping @Sendable () async -> Void) async {
        await operation()
    }
}

let throttler = Throttler()

final class LegacyOperation: @unchecked Sendable {
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
    private struct DebounceEntry {
        var scheduled: Task<Void, Never>?
        var scheduledGeneration: UInt64 = 0
        var lastFire: ContinuousClock.Instant?
    }

    private struct ThrottleEntry {
        var trailing: Task<Void, Never>?
        var trailingGeneration: UInt64 = 0
        var lastFire: ContinuousClock.Instant?
    }

    private var debounceEntries: [String: DebounceEntry] = [:]
    private var throttleEntries: [String: ThrottleEntry] = [:]
    private let clock = ContinuousClock()
    private var nextGeneration: UInt64 = 0

    func debounce(
        _ duration: Duration = .seconds(1.0),
        identifier: String = "\(Thread.callStackSymbols)",
        by actor: ActorType = .mainActor,
        option: DebounceOptions = .default,
        operation: LegacyOperation
    ) async {
        let asyncOperation: @Sendable () async -> Void = {
            await actor.run(operation)
        }
        await debounce(duration, identifier: identifier, by: .taskContext, option: option, operation: asyncOperation)
    }

    func debounce(
        _ duration: Duration = .seconds(1.0),
        identifier: String = "\(Thread.callStackSymbols)",
        by actor: ActorType = .mainActor,
        option: DebounceOptions = .default,
        operation: @escaping @Sendable () async -> Void
    ) async {
        if duration <= .seconds(0.0) {
            await actor.run(operation)
            return
        }

        let now = clock.now
        var entry = debounceEntries[identifier] ?? DebounceEntry()

        switch option {
        case .default:
            break
        case .runFirst:
            if canRunDebounceImmediately(entry: entry, now: now, duration: duration) {
                entry.lastFire = now
                debounceEntries[identifier] = entry
                await actor.run(operation)
                markDebounceImmediateFired(identifier: identifier)
                return
            }
        }

        scheduleDebounceTrailing(
            entry: &entry,
            identifier: identifier,
            after: duration,
            actor: actor,
            operation: operation
        )
        debounceEntries[identifier] = entry
    }

    func throttle(
        _ duration: Duration = .seconds(1.0),
        identifier: String = "\(Thread.callStackSymbols)",
        by actor: ActorType = .mainActor,
        option: ThrottleOptions = .default,
        operation: LegacyOperation
    ) async {
        let asyncOperation: @Sendable () async -> Void = {
            await actor.run(operation)
        }
        await throttle(duration, identifier: identifier, by: .taskContext, option: option, operation: asyncOperation)
    }

    func throttle(
        _ duration: Duration = .seconds(1.0),
        identifier: String = "\(Thread.callStackSymbols)",
        by actor: ActorType = .mainActor,
        option: ThrottleOptions = .default,
        operation: @escaping @Sendable () async -> Void
    ) async {
        if duration <= .seconds(0.0) {
            await actor.run(operation)
            return
        }

        let now = clock.now
        var entry = throttleEntries[identifier] ?? ThrottleEntry()

        if canRunThrottleImmediately(entry: entry, now: now, duration: duration) {
            entry.trailing?.cancel()
            entry.trailing = nil
            entry.lastFire = now
            throttleEntries[identifier] = entry
            await actor.run(operation)
            return
        }

        guard option == .ensureLast else {
            throttleEntries[identifier] = entry
            return
        }

        scheduleThrottleTrailing(
            entry: &entry,
            identifier: identifier,
            after: remainingThrottleDuration(entry: entry, now: now, duration: duration),
            actor: actor,
            operation: operation
        )
        throttleEntries[identifier] = entry
    }

    func delay(
        _ duration: Duration = .seconds(1.0),
        by actor: ActorType = .mainActor,
        operation: LegacyOperation
    ) async {
        let asyncOperation: @Sendable () async -> Void = {
            await actor.run(operation)
        }
        await delay(duration, by: .taskContext, operation: asyncOperation)
    }

    func delay(
        _ duration: Duration = .seconds(1.0),
        by actor: ActorType = .mainActor,
        operation: @escaping @Sendable () async -> Void
    ) async {
        if duration <= .seconds(0.0) {
            await actor.run(operation)
            return
        }

        let clock = self.clock
        await sleep(for: duration, clock: clock)
        guard !Task.isCancelled else { return }
        await actor.run(operation)
    }

    private func canRunDebounceImmediately(
        entry: DebounceEntry,
        now: ContinuousClock.Instant,
        duration: Duration
    ) -> Bool {
        guard entry.scheduled == nil else { return false }
        guard let lastFire = entry.lastFire else { return true }
        return (now - lastFire) >= duration
    }

    private func canRunThrottleImmediately(
        entry: ThrottleEntry,
        now: ContinuousClock.Instant,
        duration: Duration
    ) -> Bool {
        guard let lastFire = entry.lastFire else { return true }
        return (now - lastFire) >= duration
    }

    private func remainingThrottleDuration(
        entry: ThrottleEntry,
        now: ContinuousClock.Instant,
        duration: Duration
    ) -> Duration {
        guard let lastFire = entry.lastFire else { return .seconds(0.0) }
        return duration - (now - lastFire)
    }

    private func scheduleDebounceTrailing(
        entry: inout DebounceEntry,
        identifier: String,
        after duration: Duration,
        actor: ActorType,
        operation: @escaping @Sendable () async -> Void
    ) {
        entry.scheduled?.cancel()
        let generation = nextScheduledGeneration()
        entry.scheduledGeneration = generation

        let clock = self.clock
        entry.scheduled = Task { [weak self] in
            await sleep(for: duration, clock: clock)
            guard !Task.isCancelled else { return }
            guard let self else { return }
            guard await self.markDebounceReady(identifier: identifier, generation: generation) else { return }

            await actor.run(operation)
        }
    }

    private func scheduleThrottleTrailing(
        entry: inout ThrottleEntry,
        identifier: String,
        after duration: Duration,
        actor: ActorType,
        operation: @escaping @Sendable () async -> Void
    ) {
        entry.trailing?.cancel()
        let generation = nextScheduledGeneration()
        entry.trailingGeneration = generation

        let clock = self.clock
        entry.trailing = Task { [weak self] in
            await sleep(for: duration, clock: clock)
            guard !Task.isCancelled else { return }
            guard let self else { return }
            guard await self.markThrottleTrailingReady(identifier: identifier, generation: generation) else { return }

            await actor.run(operation)
        }
    }

    private func markDebounceReady(identifier: String, generation: UInt64) -> Bool {
        guard var entry = debounceEntries[identifier] else { return false }
        guard entry.scheduledGeneration == generation else { return false }
        entry.scheduled = nil
        entry.lastFire = clock.now
        debounceEntries[identifier] = entry
        return true
    }

    private func markThrottleTrailingReady(identifier: String, generation: UInt64) -> Bool {
        guard var entry = throttleEntries[identifier] else { return false }
        guard entry.trailingGeneration == generation else { return false }
        entry.trailing = nil
        entry.lastFire = clock.now
        throttleEntries[identifier] = entry
        return true
    }

    private func markDebounceImmediateFired(identifier: String) {
        guard var entry = debounceEntries[identifier] else { return }
        entry.lastFire = clock.now
        debounceEntries[identifier] = entry
    }

    private func nextScheduledGeneration() -> UInt64 {
        nextGeneration &+= 1
        return nextGeneration
    }
}

@Sendable
func sleep(for duration: Duration, clock: ContinuousClock) async {
    guard duration > .seconds(0.0) else { return }
    try? await clock.sleep(for: duration)
}
