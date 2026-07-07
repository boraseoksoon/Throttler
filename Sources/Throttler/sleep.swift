//
//  sleep.swift
//  Throttler
//
//  Created by seoksoon jang on 2026-07-06.
//

public func sleep(_ duration: Duration = .seconds(1.0)) async {
    guard duration > .seconds(0.0) else { return }
    try? await Task.sleep(for: duration)
}

@discardableResult
public func execute(
    with delay: Duration = .seconds(0.0),
    on actor: ActorType = .mainActor,
    operation: @escaping @Sendable () async -> Void
) -> Task<Void, Never> {
    Task {
        if delay > .seconds(0.0) {
            try? await Task.sleep(for: delay)
        }
        guard !Task.isCancelled else { return }
        await actor.run(operation)
    }
}

@discardableResult
public func execute(
    with delay: Duration = .seconds(0.0),
    operation: @escaping @MainActor @Sendable () async -> Void
) -> Task<Void, Never> {
    Task {
        if delay > .seconds(0.0) {
            try? await Task.sleep(for: delay)
        }
        guard !Task.isCancelled else { return }
        await operation()
    }
}
