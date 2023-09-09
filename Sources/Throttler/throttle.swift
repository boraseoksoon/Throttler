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
   - duration: Foundation `Duration` type such as `.seconds(2.0)`. By default, .seconds(1.0)
   - identifier: (Optional) An identifier to distinguish between throttled operations. It is highly recommended to provide a custom identifier for clarity and to avoid potential issues with long call stack symbols. Use at your own risk with internal stack traces.
   - actorType: The actor type on which the operation should be executed (default is `.main`).
   - option: An option to customize the behavior of the throttle (default is `.default`).
   - operation: The operation to be executed when throttled.

 - Note:
   - The provided `identifier` is used to group related throttle operations. If multiple throttle calls share the same identifier, they will be considered as part of the same group, and the throttle behavior will apply collectively.
   - This method ensures that the operation is executed in a thread-safe manner within the specified actor context.

 - Usage:
    ```swift
    // Throttle a button tap action to prevent rapid execution.
    @IBAction func buttonTapped(_ sender: UIButton) {
        // Basic usage with default options
 
         throttle {
             print("hi")
         }

        // Using custom identifiers to distinguish between throttled operations
 
        throttle(identifier: "customIdentifier") {
            print("identifier is recommended way")
        }

        // Using 'runFirst' option to execute the first call immediately and throttle the rest
 
         for i in 1...100000 {
             throttle(option: .runFirst) {
                 print("throttle : \(i)")
             }
         }

         // throttle : 1        => 💥
         // throttle : 43584
         // throttle : 88485

        // Using 'ensureLast' option to guarantee that the last call is executed
 
         for i in 1...100000 {
             throttle(option: .ensureLast) {
                 print("throttle : \(i)")
             }
         }

         // throttle : 16363
         // throttle : 52307
         // throttle : 74711
         // throttle : 95747
         // throttle : 100000    => 💥

        // Using 'combined' option to combine 'runFirst' and 'ensureLast' behaviors
 
         for i in 1...100000 {
             throttle(option: .combined) {
                 print("throttle : \(i)")
             }
         }

         // throttle : 1         => 💥
         // throttle : 25045
         // throttle : 30309
         // throttle : 35717
         // throttle : 48059
         // throttle : 61806
         // throttle : 75336
         // throttle : 88585
         // throttle : 100000    => 💥
    }
   ```
 
 - See Also:
    - ThrottleOptions: Enum that defines various options for controlling throttle behavior.
 
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
