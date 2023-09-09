//
//  throttle.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

import Foundation

/**
 Limits the frequency of executing a given operation to ensure it is not called more frequently than a specified duration.

 - Parameters:
   - duration: Foundation `Duration` type such sa .seconds(2.0). By default, .seconds(1.0)
   - identifier: (Optional) An identifier to distinguish between throttled operations. It is highly recommended to provide a custom identifier for clarity and to avoid potential issues with long call stack symbols. Use at your own risk with internal stack traces.
   - actorType: The actor type on which the operation should be executed (default is `.main`).
   - option: An option to customize the behavior of the throttle (default is `.default`).
   - operation: The operation to be executed when throttled.
 
 - Note:
   - The provided `identifier` is used to group related debounce operations. If multiple debounce calls share the same identifier, they will be considered as part of the same group, and the debounce behavior will apply collectively.
   - This method ensures that the operation is executed in a thread-safe manner within the specified actor context.

 - Usage:
   ```swift
   // Debounce a button tap action to prevent rapid execution.
   @IBAction func buttonTapped(_ sender: UIButton) {
       // Delay execution by a custom duration.
       throttle(.duration(.milliseconds(500))) {
           print("Button tapped (throttled with custom duration)")
       }
       
       // You can use custom identifiers to distinguish between throttled operations.
       throttle(.seconds(3.0), identifier: "customIdentifier") {
           print("Custom throttled operation")
       }
   }
   ```
*/

public func throttle(
    _ duration: Duration = .seconds(1.0),
    identifier: String = "\(Thread.callStackSymbols)",
    by `actor`: ActorType = .mainActor,
    option: ThrottleOptions = .default,
    operation: @escaping () -> Void
) {
    Task {
        await throttler.throttle(
            duration,
            identifier: identifier,
            by: actor,
            option: option,
            operation: operation
        )
    }
}
