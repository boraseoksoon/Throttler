//
//  Throttle.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

import Foundation

/**
 Limits the rate at which a closure is executed by delaying its execution until a specified amount of time has passed since the last execution.

 - Parameters:
    - interval: The minimum amount of time that must pass before the closure can be executed again. Default value is 1 sec.
    - actorType: The actor type to use for executing the closure. Default value is `.main`.
    - operation: The closure to execute.

 - Note: If the device is running iOS 16.0 or later, the closure will be executed on the main actor by default. If the device is running a version of iOS prior to 16.0, the closure will be executed on a background thread.

 - Important: If a new execution is requested before the interval has elapsed since the last execution, the previous execution will be cancelled and the closure will not be executed.

 - Example: This example throttles the execution of a closure, printing a message to the console each time the closure is executed, but ensuring that no more than one message is printed per 50 milliseconds:

 (0...100000).forEach { i in
     throttle(.seconds(0.01)) {
         print(i)
     }
 }
 
 //  0
 //  18133
 //  36058
 //  57501
 //  82851
 
*/

var lastExecutionDate: Date?

@available(iOS 16.0, *)
public func throttle(
    _ interval: Duration = .seconds(1),
    on actorType: ActorType = .main,
    operation: @escaping () -> Void
) {
    let now = Date()
    
    if let lastExecution = lastExecutionDate, now.timeIntervalSince(lastExecution) < interval.timeInterval { return }
    
    lastExecutionDate = now
    
    Task {
        actorType ~= .main ? await MainActor.run { operation() } : operation()
    }
}

/**
 Limits the rate at which a closure is executed by delaying its execution until a specified amount of time has passed since the last execution.

 - Parameters:
    - seconds: The minimum amount of time in seconds that must pass before the closure can be executed again. Default value is 1 seconds.
    - actorType: The actor type to use for executing the closure. Default value is `.main`.
    - operation: The closure to execute.

 - Precondition: `seconds` must be greater than or equal to zero.

 - Important: If a new execution is requested before the interval has elapsed since the last execution, the previous execution will be cancelled and the closure will not be executed.

 - Example: This example throttles the execution of a closure, printing a message to the console each time the closure is executed, but ensuring that no more than one message is printed per 0.1 seconds:

 (0...100000).forEach { i in
     throttle(seconds: 0.01) {
         print(i)
     }
 }
 
 //  0
 //  18133
 //  36058
 //  57501
 //  82851
 
*/

var compatibleLastExecutionDate: Date?

public func throttle(
    seconds: TimeInterval = 1.0,
    on actorType: ActorType = .main,
    operation: @escaping () -> Void
) {
    let now = Date()
    
    if let lastExecution = compatibleLastExecutionDate, now.timeIntervalSince(lastExecution) < seconds { return }

    compatibleLastExecutionDate = now
    
    Task {
        actorType ~= .main ? await MainActor.run { operation() } : operation()
    }
}

@available(iOS 16.0, *)
private extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + Double(components.attoseconds)/1e18
    }
}
