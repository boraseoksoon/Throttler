//
//  delay.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

import Foundation

/**
 Delays the execution of a provided operation by a specified time duration.

 - Parameters:
   - duration: Foundation `Duration` type such as .seconds(2.0). By default, .seconds(1.0)
   - actorType: The actor type on which the operation should be executed (default is `.main`).
   - operation: The operation to be executed after the delay.

 - Note:
   - The `delay` function is non-blocking, meaning it will not hold up the main thread (or the thread it's invoked on if you specify a different `actorType`).
   - The delayed operation will be executed asynchronously, after the specified duration has passed.
   - Use this function cautiously to avoid creating race conditions or other timing-related issues in your code.

 - Example:

    ```swift
    // Delay execution by 2 seconds using a custom duration.
    delay(.seconds(2)) {
        print("Delayed operation")
    }
    
    // Alternatively, delay execution by 1.5 seconds using the .seconds convenience method.
    delay(.seconds(1.5)) {
        print("Another delayed operation")
    }
    ```
*/

public func delay(
    _ duration: Duration = .seconds(1.0),
    on actorType: ActorType = .main,
    operation: @escaping () -> Void
) {
    Task {
        await actor.delay(
            duration,
            on: actorType,
            operation: operation
        )
    }
}
