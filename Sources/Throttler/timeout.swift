//
//  timeout.swift
//  Throttler
//
//  Created by seoksoon jang on 2026-07-06.
//

import Foundation

/// The error thrown by `timeout` when the deadline wins.
public enum TimeoutError: Error, Equatable, Sendable {
    /// The operation did not finish within the provided duration.
    case timedOut(Duration)
}

/**
 Runs an async operation with a maximum allowed duration and returns its value.

 - Parameters:
   - duration: The maximum duration the operation is allowed to take.
   - operation: The async throwing operation to run.

 - Returns: The operation result when it finishes before the timeout.
 - Throws:
   - `TimeoutError.timedOut(duration)` when the timeout wins.
   - The original operation error when the operation throws before the timeout.
   - `CancellationError` when the parent task is cancelled.

 - Behavior:
   - A non-positive `duration` times out immediately.
   - When the timeout wins, the operation child task is cancelled and `TimeoutError.timedOut(duration)` is thrown after structured child-task cleanup completes.
   - Swift task cancellation is cooperative. Blocking or cancellation-ignoring operations can delay cleanup.
 */
public func timeout<Value: Sendable>(
    _ duration: Duration,
    operation: @escaping @Sendable () async throws -> Value
) async throws -> Value {
    guard duration > .seconds(0.0) else {
        throw TimeoutError.timedOut(duration)
    }

    return try await withThrowingTaskGroup(of: Value.self, returning: Value.self) { group in
        defer {
            group.cancelAll()
        }

        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(for: duration)
            throw TimeoutError.timedOut(duration)
        }

        guard let value = try await group.next() else {
            throw CancellationError()
        }

        return value
    }
}
