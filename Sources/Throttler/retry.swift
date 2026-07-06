//
//  retry.swift
//  Throttler
//
//  Created by seoksoon jang on 2026-07-06.
//

import Foundation

/// The error thrown by `retry` before running when its arguments are invalid.
public enum RetryError: Error, Equatable, Sendable {
    /// The maximum attempt count was less than or equal to zero.
    case invalidAttemptCount(Int)
}

/**
 Retries an async operation until it succeeds or the maximum attempt count is reached.

 - Parameters:
   - maxAttempts: The maximum total number of attempts. The default is 3. The first attempt runs immediately.
   - delay: The delay between failed attempts. A non-positive delay retries immediately.
   - operation: The async throwing operation to retry.

 - Returns: The first successful operation result.
 - Throws:
   - `RetryError.invalidAttemptCount(maxAttempts)` when `maxAttempts` is less than or equal to zero.
   - `CancellationError` when the operation or parent task is cancelled.
   - The last operation error when all attempts fail.

 - Behavior:
   - `retry(3, every: .milliseconds(300))` means 3 total attempts, not 1 initial attempt plus 3 retries.
   - Attempts never overlap.
   - Cancellation is not retried.
   - The delay happens only after a failed attempt when another attempt remains.
 */
public func retry<Value: Sendable>(
    _ maxAttempts: Int = 3,
    every delay: Duration = .seconds(1.0),
    operation: @Sendable () async throws -> Value
) async throws -> Value {
    guard maxAttempts > 0 else {
        throw RetryError.invalidAttemptCount(maxAttempts)
    }

    for attempt in 1...maxAttempts {
        do {
            try Task.checkCancellation()
            return try await operation()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()

            guard attempt < maxAttempts else {
                throw error
            }

            if delay > .seconds(0.0) {
                try await Task.sleep(for: delay)
            } else {
                try Task.checkCancellation()
            }
        }
    }

    throw RetryError.invalidAttemptCount(maxAttempts)
}
