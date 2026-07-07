//
//  debounce.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

/**
 Debounces an operation: of the calls made within `duration`, only the latest one runs.

 - Parameters:
   - duration: The debounce window, such as `.seconds(2.0)`. The default is `.seconds(1.0)`.
   - identifier: The identifier that groups related debounce calls. When omitted, calls are
     grouped by call site (file, line, and column), so repeated calls from the same source
     location share one debounce group. Provide a custom identifier to group calls across
     call sites or to debounce per dynamic value.
   - actor: The `ActorType` context the operation runs in. The default is `.mainActor`.
   - option: `.default` delays every call; `.runFirst` runs the first eligible call
     immediately and debounces subsequent calls.
   - fileID: Populated automatically to derive the default call-site identifier. Do not pass.
   - line: Populated automatically to derive the default call-site identifier. Do not pass.
   - column: Populated automatically to derive the default call-site identifier. Do not pass.
   - operation: The operation to debounce.

 - Note:
   - Calls that share an identifier form one debounce group; the latest call wins.
   - An operation that already started running is never cancelled by a newer call.

 - Example:
   ```swift
   debounce {
       print("debounced")
   }

   debounce(.seconds(1.0), identifier: "customIdentifier") {
       print("debounced with a custom identifier")
   }

   debounce(.seconds(1.0), identifier: "runFirstExample", option: .runFirst) {
       print("first call runs immediately, the rest debounce")
   }
   ```

 - See Also: `DebounceOptions`
*/
public func debounce(
    _ duration: Duration = .seconds(1.0),
    identifier: String = callSiteDefaultIdentifier,
    by `actor`: ActorType = .mainActor,
    option: DebounceOptions = .default,
    fileID: String = #fileID,
    line: UInt = #line,
    column: UInt = #column,
    operation: @escaping @Sendable () -> Void
) {
    let identifier = resolveCallSiteIdentifier(identifier, fileID: fileID, line: line, column: column)
    Task {
        await throttler.debounce(
            duration,
            identifier: identifier,
            by: .taskContext,
            option: option,
            operation: { await actor.run(operation) }
        )
    }
}

/// Debounces a main-actor synchronous operation.
public func debounce(
    _ duration: Duration = .seconds(1.0),
    identifier: String = callSiteDefaultIdentifier,
    option: DebounceOptions = .default,
    fileID: String = #fileID,
    line: UInt = #line,
    column: UInt = #column,
    operation: @escaping @MainActor @Sendable () -> Void
) {
    let identifier = resolveCallSiteIdentifier(identifier, fileID: fileID, line: line, column: column)
    Task {
        await throttler.debounce(
            duration,
            identifier: identifier,
            by: .mainActor,
            option: option,
            operation: { await operation() }
        )
    }
}

/// Debounces an async throwing operation and returns the scheduling task.
/// Errors thrown by `operation` are delivered to `onError`.
@discardableResult
public func debounce(
    _ duration: Duration = .seconds(1.0),
    identifier: String = callSiteDefaultIdentifier,
    by `actor`: ActorType = .mainActor,
    option: DebounceOptions = .default,
    fileID: String = #fileID,
    line: UInt = #line,
    column: UInt = #column,
    onError: (@Sendable (Error) -> Void)? = nil,
    operation: @escaping @Sendable () async throws -> Void
) -> Task<Void, Never> {
    let identifier = resolveCallSiteIdentifier(identifier, fileID: fileID, line: line, column: column)
    return Task {
        await throttler.debounce(
            duration,
            identifier: identifier,
            by: actor,
            option: option,
            operation: throttlerErrorWrapping(operation, onError: onError)
        )
    }
}
