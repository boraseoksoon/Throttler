//
//  throttle.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

/**
 Throttles an operation: the first eligible call runs immediately, and further calls
 within `duration` are suppressed.

 - Parameters:
   - duration: The throttle window, such as `.seconds(2.0)`. The default is `.seconds(1.0)`.
   - identifier: The identifier that groups related throttle calls. When omitted, calls are
     grouped by call site (file, line, and column), so repeated calls from the same source
     location share one throttle group. Provide a custom identifier to group calls across
     call sites or to throttle per dynamic value.
   - actor: The `ActorType` context the operation runs in. The default is `.mainActor`.
   - option: `.default` drops suppressed calls; `.ensureLast` runs the latest suppressed
     call at the end of the throttle window.
   - fileID: Populated automatically to derive the default call-site identifier. Do not pass.
   - line: Populated automatically to derive the default call-site identifier. Do not pass.
   - column: Populated automatically to derive the default call-site identifier. Do not pass.
   - operation: The operation to throttle.

 - Note:
   - Calls that share an identifier form one throttle group.

 - Example:
   ```swift
   throttle {
       print("throttled")
   }

   throttle(.seconds(3.0), identifier: "customIdentifier") {
       print("throttled with a custom identifier")
   }

   throttle(.seconds(3.0), identifier: "ensureLastExample", option: .ensureLast) {
       print("the latest suppressed call also runs")
   }
   ```

 - See Also: `ThrottleOptions`
*/
public func throttle(
    _ duration: Duration = .seconds(1.0),
    identifier: String = callSiteDefaultIdentifier,
    by `actor`: ActorType = .mainActor,
    option: ThrottleOptions = .default,
    fileID: String = #fileID,
    line: UInt = #line,
    column: UInt = #column,
    operation: @escaping @Sendable () -> Void
) {
    let identifier = resolveCallSiteIdentifier(identifier, fileID: fileID, line: line, column: column)
    Task {
        await throttler.throttle(
            duration,
            identifier: identifier,
            by: .taskContext,
            option: option,
            operation: { await actor.run(operation) }
        )
    }
}

/// Throttles a main-actor synchronous operation.
public func throttle(
    _ duration: Duration = .seconds(1.0),
    identifier: String = callSiteDefaultIdentifier,
    option: ThrottleOptions = .default,
    fileID: String = #fileID,
    line: UInt = #line,
    column: UInt = #column,
    operation: @escaping @MainActor @Sendable () -> Void
) {
    let identifier = resolveCallSiteIdentifier(identifier, fileID: fileID, line: line, column: column)
    Task {
        await throttler.throttle(
            duration,
            identifier: identifier,
            by: .mainActor,
            option: option,
            operation: { await operation() }
        )
    }
}

/// Throttles an async throwing operation and returns the scheduling task.
/// Errors thrown by `operation` are delivered to `onError`.
@discardableResult
public func throttle(
    _ duration: Duration = .seconds(1.0),
    identifier: String = callSiteDefaultIdentifier,
    by `actor`: ActorType = .mainActor,
    option: ThrottleOptions = .default,
    fileID: String = #fileID,
    line: UInt = #line,
    column: UInt = #column,
    onError: (@Sendable (Error) -> Void)? = nil,
    operation: @escaping @Sendable () async throws -> Void
) -> Task<Void, Never> {
    let identifier = resolveCallSiteIdentifier(identifier, fileID: fileID, line: line, column: column)
    return Task {
        await throttler.throttle(
            duration,
            identifier: identifier,
            by: actor,
            option: option,
            operation: throttlerErrorWrapping(operation, onError: onError)
        )
    }
}
