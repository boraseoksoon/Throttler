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
   - interval: A `TimeDuration` value representing the duration of the delay. You can use `.duration` with custom time intervals or `.seconds` with seconds as the interval.
   - actorType: The actor type on which the operation should be executed (default is `.main`).
   - operation: The operation to be executed after the delay.

 - Usage:
    ```swift
    // Delay execution by 2 seconds using a custom duration.
    delay(.duration(.seconds(2))) {
        print("Delayed operation")
    }
    
    // Alternatively, delay execution by 1.5 seconds using the .seconds convenience method.
    delay(.seconds(1.5)) {
        print("Another delayed operation")
    }
    ```
 */

public func delay(
    _ interval: TimeDuration = .seconds(1.0),
    on actorType: ActorType = .main,
    operation: @escaping () -> Void
) {
    Task {
        await actor.delay(
            interval,
            on: actorType,
            operation: operation
        )
    }
}
