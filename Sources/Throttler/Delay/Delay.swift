//
//  Delay.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

import Foundation

/**
 Delays the execution of a closure by a specified interval.

 - Parameters:
    - interval: The time interval to delay execution by. Default value is 1 second.
    - actorType: The actor type to use for executing the closure. Default value is `.main`.
    - operation: The closure to execute after the delay.

 - Precondition: `interval` must be greater than or equal to zero.

 - Note: If the device is running iOS 16.0 or later, the closure will be executed on the main actor by default. If the device is running a version of iOS prior to 16.0, the closure will be executed on a background thread.

 - Important: If a new delay is requested before a previous delay has completed, the previous delay will be cancelled and the closure will not be executed.

 - Example: This example delays the execution of a closure by 1 second:

        delay {
            print("fired after 1 second.")
        }

    This example delays the execution of a closure by 2 seconds and executes it on a current actor:

        delay(.seconds(2), on: .current) {
            print("fired after 2 seconds.")
        }
*/

var delayTask: Task<(), Never>?

@available(macOS 13.0, *)
@available(iOS, introduced: 16.0)
public func delay(
    _ interval: Duration = .seconds(1),
    on actorType: ActorType = .main,
    operation: @escaping () -> Void
) {
    delayTask = Task {
        do {
            try await Task.sleep(for: interval)
            actorType ~= .main ? await MainActor.run { operation() } : operation()
        } catch {}
    }
}

/**
 Delays the execution of a closure by a specified number of seconds.

 - Parameters:
    - seconds: The number of seconds to delay execution by.
    - actorType: The actor type to use for executing the closure. Default value is `.main`.
    - operation: The closure to execute after the delay.

 - Precondition: `seconds` must be greater than or equal to zero.

 - Important: If a new delay is requested before a previous delay has completed, the previous delay will be cancelled and the closure will not be executed.

 - Example: This example delays the execution of a closure by 2 seconds:

        delay(seconds: 2) {
            print("fired after 2 seconds.")
        }
*/

var compatibleDelayTask: Task<(), Never>?

public func delay(seconds: Double, on actorType: ActorType = .main, operation: @escaping () -> Void) {
    compatibleDelayTask = Task {
        do {
            try await Task.sleep(seconds: seconds)
            actorType ~= .main ? await MainActor.run { operation() } : operation()
        } catch {}
    }
}

