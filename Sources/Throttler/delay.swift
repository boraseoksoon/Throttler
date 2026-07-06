//
//  delay.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

/**
 Delays an operation by `duration`, then runs it.

 - Parameters:
   - duration: The delay, such as `.seconds(2.0)`. The default is `.seconds(1.0)`.
   - actor: The `ActorType` context the operation runs in. The default is `.mainActor`.
   - operation: The operation to run after the delay.

 - Example:
   ```swift
   delay(.seconds(2)) {
       print("Delayed 2 seconds")
   }
   ```
*/
public func delay(
    _ duration: Duration = .seconds(1.0),
    by `actor`: ActorType = .mainActor,
    operation: @escaping () -> Void
) {
    let synchronousOperation = SynchronousOperation(operation)
    Task {
        await throttler.delay(
            duration,
            by: .taskContext,
            operation: { await actor.run(synchronousOperation) }
        )
    }
}

/// Delays an async throwing operation and returns the delay task, which can be
/// cancelled before the operation starts. Errors thrown by `operation` are
/// delivered to `onError`.
@discardableResult
public func delay(
    _ duration: Duration = .seconds(1.0),
    by `actor`: ActorType = .mainActor,
    onError: (@Sendable (Error) -> Void)? = nil,
    operation: @escaping @Sendable () async throws -> Void
) -> Task<Void, Never> {
    Task {
        await throttler.delay(
            duration,
            by: actor,
            operation: throttlerErrorWrapping(operation, onError: onError)
        )
    }
}
