//
//  debounce.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

import Foundation

/**
 Delays the execution of a closure until a specified amount of time has passed since the last time the closure was executed.

 - Parameters:
    - interval: The minimum amount of time that must pass before the closure can be executed again. Default value is 1 sec.
    - actorType: The actor type to use for executing the closure. Default value is `.main`.
    - operation: The closure to execute.

 - Note: If the device is running iOS 16.0 or later, the closure will be executed on the main actor by default. If the device is running a version of iOS prior to 16.0, the closure will be executed on a background thread.

 - Important: If a new execution is requested before the interval has elapsed since the last execution, the previous execution will be cancelled and the closure will not be executed.

 - Example: This example debounces the execution of a closure, printing a message to the console each time the closure is executed, but ensuring that no more than one message is printed per 100 milliseconds:

 debounce {
     print("fired after 1 sec")
 }
 
 debounce(.seconds(2)) {
    print("fired after 2 seconds")
 }
 
*/

var debounceTask: Task<(), Never>?

@available(iOS 16.0, *)
public func debounce(
    _ interval: Duration = .seconds(1),
    on actorType: ActorType = .main,
    operation: @escaping () -> Void
) {
    debounceTask?.cancel()

    debounceTask = Task {
        do {
            try await Task.sleep(for: interval)
            actorType ~= .main ? await MainActor.run { operation() } : operation()
        } catch {}
    }
}

/**
 Delays the execution of a closure until a specified amount of time has passed since the last time the closure was executed.

 - Parameters:
    - seconds: The minimum amount of time in seconds that must pass before the closure can be executed again. Default value is 1.0 seconds.
    - actorType: The actor type to use for executing the closure. Default value is `.main`.
    - operation: The closure to execute.

 - Precondition: `seconds` must be greater than or equal to zero.

 - Important: If a new execution is requested before the interval has elapsed since the last execution, the previous execution will be cancelled and the closure will not be executed.

 - Example: This example debounces the execution of a closure, printing a message to the console each time the closure is executed, but ensuring that no more than one message is printed per 0.1 seconds:

 debounce(seconds: 2.0, on: .main) {
     print("fired after 2 seconds")
 }
*/

var compatibleDebounceTask: Task<(), Never>?

public func debounce(
    seconds: Double = 1.0,
    on actorType: ActorType,
    operation: @escaping () -> Void
) {
    compatibleDebounceTask?.cancel()

    compatibleDebounceTask = Task {
        do {
            try await Task.sleep(seconds: seconds)
            actorType ~= .main ? await MainActor.run { operation() } : operation()
        } catch {}
    }
}

