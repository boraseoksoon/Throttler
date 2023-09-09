//
//  Throttle.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

import Foundation

/**
 Limits the frequency of executing a given operation to ensure it is not called more frequently than a specified duration.

 - Parameters:
   - duration: A `TimeDuration` value representing the minimum time interval between operation executions. You can use `.duration` with custom time intervals or `.seconds` with seconds as the interval.
   - identifier: (Optional) An identifier to distinguish between throttled operations. It is highly recommended to provide a custom identifier for clarity and to avoid potential issues with long call stack symbols. Use at your own risk with internal stack traces.
   - actorType: The actor type on which the operation should be executed (default is `.main`).
   - option: An option to customize the behavior of the throttle (default is `.default`).
   - operation: The operation to be executed when throttled.

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
    _ duration: TimeDuration = .seconds(1.0),
    identifier: String = "\(Thread.callStackSymbols)",
    on actorType: ActorType = .main,
    option: ThrottleOptions = .default,
    operation: @escaping () -> Void
) {
    Task {
        await actor.throttle(
            duration,
            identifier: identifier,
            on: actorType,
            option: option,
            operation: operation
        )
    }
}
