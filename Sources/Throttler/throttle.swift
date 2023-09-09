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
   - duration: Foundation `Duration` type such as .seconds(2.0). By default, .seconds(1.0)
   - identifier: (Optional) An identifier to distinguish between throttled operations. It is highly recommended to provide a custom identifier for clarity and to avoid potential issues with long call stack symbols. Use at your own risk with internal stack traces.
   - actorType: The actor type on which the operation should be executed (default is `.main`).
   - option: An option to customize the behavior of the throttle (default is `.default`).
   - operation: The operation to be executed when throttled.

 - Note:
   - Throttling is a technique to limit the rate at which a function is called. It ensures that the operation is executed no more often than the specified duration.
   - The provided `identifier` is used to group related throttle operations. If multiple throttle calls share the same identifier, they will be considered as part of the same group, and the throttle behavior will apply collectively. 

 - Example:
    ```swift
    // Using Default option to throttle function calls.
    for i in 1...10 {
        throttle(.seconds(1), option: .default) {
            print("throttle : \(i)")
        }
    }
    
    // Using RunFirstImmediately option to execute the first operation immediately.
    for i in 1...10 {
        throttle(.seconds(1), option: .runFirstImmediately) {
            print("throttle : \(i)")
        }
    }
    
    // Using LastGuaranteed option to ensure the last function call is executed.
    for i in 1...10 {
        throttle(.seconds(1), option: .lastGuaranteed) {
            print("throttle : \(i)")
        }
    }
    
    // Using Combined option to combine RunFirstImmediately and LastGuaranteed behaviors.
    for i in 1...10 {
        throttle(.seconds(1), option: .combined) {
            print("throttle : \(i)")
        }
    }
    ```
*/

public func throttle(
    _ duration: Duration = .seconds(1.0),
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
