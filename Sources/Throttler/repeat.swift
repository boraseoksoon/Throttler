//
//  repeat.swift
//  Throttler
//
//  Created by seoksoon jang on 2026-07-06.
//

import Foundation

/**
 Repeats an async operation on a serial cadence and returns the task that owns the loop.

 - Parameters:
   - interval: The positive delay before each scheduled run. The default is 1 second.
   - times: The maximum number of times to run the operation. `nil` repeats until the returned task is cancelled. Values less than or equal to zero complete without running.
   - startingImmediately: When `true`, the first run starts right away. When `false`, the first run waits for `interval`.
   - actor: The actor context used to run each iteration. The default is `.mainActor`.
   - onError: Called when an iteration throws. After an error, the repeat loop stops.
   - operation: The operation to run repeatedly.

 - Behavior:
   - The returned task is the cancellation handle. Call `cancel()` on it to stop future iterations.
   - Iterations never overlap. The next wait starts after the current operation finishes.
   - A non-positive `interval` completes without running to avoid a busy loop.
   - Cancellation during the wait or operation stops the loop without calling `onError`.
 */
@discardableResult
public func `repeat`(
    every interval: Duration = .seconds(1.0),
    times limit: Int? = nil,
    startingImmediately: Bool = false,
    by actor: ActorType = .mainActor,
    onError: (@Sendable (Error) -> Void)? = nil,
    operation: @escaping @Sendable () async throws -> Void
) -> Task<Void, Never> {
    Task {
        guard interval > .seconds(0.0) else { return }
        guard limit.map({ $0 > 0 }) ?? true else { return }

        var completedRuns = 0

        if startingImmediately {
            guard await runRepeatIteration(by: actor, onError: onError, operation: operation) else { return }
            completedRuns += 1
        }

        while !Task.isCancelled {
            guard limit.map({ completedRuns < $0 }) ?? true else { return }

            do {
                try await Task.sleep(for: interval)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            guard await runRepeatIteration(by: actor, onError: onError, operation: operation) else { return }
            completedRuns += 1
        }
    }
}

private func runRepeatIteration(
    by actor: ActorType,
    onError: (@Sendable (Error) -> Void)?,
    operation: @escaping @Sendable () async throws -> Void
) async -> Bool {
    do {
        try await actor.run(operation)
        return true
    } catch is CancellationError {
        return false
    } catch {
        onError?(error)
        return false
    }
}
