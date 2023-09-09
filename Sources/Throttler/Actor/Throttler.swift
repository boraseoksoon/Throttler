//
//  Throttler.swift
//  DebounceTest
//
//  Created by seoksoon jang on 2023-09-08.
//

import Foundation

/// Options for debouncing an operation.
public enum DebounceOptions {
    /// The default debounce behavior.
    case `default`
    /// Run the operation immediately and debounce subsequent calls.
    case runFirstImmediately
}

/// Options for throttling an operation.
public enum ThrottleOptions {
    /// The default throttle behavior.
    case `default`
    /// Run the operation immediately and throttle subsequent calls.
    case runFirstImmediately
    /// Guarantee that the last call is executed even if it's after the throttle time.
    case lastGuaranteed
    /// Combine both runFirstImmediately and lastGuaranteed behaviors.
    case combined
}

public enum ActorType {
    case current
    case main
    
    @Sendable func run(_ operation: () -> Void) async {
        self == .main ? await MainActor.run { operation() } : operation()
    }
}

/// a global actor variable for free functions (delay, debounce, throttle) to rely on. (internal use only)
let actor = Throttler()

/// An actor for managing debouncing, throttling and delay operations designed to be the internal use.
actor Throttler {
    private var debounceTasksByIdentifier: [String: Task<(), Never>] = [:]
    private var lastThrottleRunDateByIdentifier: [String: Date] = [:]
    
    /// Debounces an operation, ensuring it's executed only after a specified time interval
    /// has passed since the last call.
    ///
    /// - Parameters:
    ///   - duration: The time interval for debouncing.
    ///   - identifier: A custom identifier for distinguishing debounce tasks. It's recommended
    ///                 to use your own identifier for better control, but you can use the default
    ///                 which is based on the call stack symbols (use at your own risk).
    ///   - actorType: The actor type on which to execute the operation (default is main actor).
    ///   - option: The debounce option (default or runFirstImmediately).
    ///   - operation: The operation to debounce.
    ///
    /// - Note: This method ensures that the operation is executed in a thread-safe manner
    ///         within the specified actor context.
    func debounce(
        _ duration: Duration = .seconds(1.0),
        identifier: String = "\(Thread.callStackSymbols)",
        on actorType: ActorType = .main,
        option: DebounceOptions = .default,
        operation: @escaping () -> Void
    ) async {
        switch option {
        case .runFirstImmediately:
            if debounceTasksByIdentifier[identifier] == nil {
                Task {
                    await actorType.run(operation)
                }
            }
            fallthrough
        default:
            debounceTasksByIdentifier[identifier]?.cancel()
            debounceTasksByIdentifier[identifier] = {
                Task {
                    try? await Task.sleep(for: duration)
                    
                    guard !Task.isCancelled else { return }
                    
                    await actorType.run(operation)
                }
            }()
        }
    }

    /// Throttles an operation, ensuring it's executed at most once within a specified time interval.
    ///
    /// - Parameters:
    ///   - duration: The time interval for throttling.
    ///   - identifier: A custom identifier for distinguishing throttle tasks. It's recommended
    ///                 to use your own identifier for better control, but you can use the default
    ///                 which is based on the call stack symbols (use at your own risk).
    ///   - actorType: The actor type on which to execute the operation (default is main actor).
    ///   - option: The throttle option (default or runFirstImmediately).
    ///   - operation: The operation to throttle.
    ///
    /// - Note: This method ensures that the operation is executed in a thread-safe manner
    ///         within the specified actor context.
    public func throttle(
        _ duration: Duration = .seconds(1.0),
        identifier: String = "\(Thread.callStackSymbols)",
        on actorType: ActorType = .main,
        option: ThrottleOptions = .default,
        operation: @escaping () -> Void
    ) async {
        let now = Date()
        
        let execute = {
            let lastRunDate = self.lastThrottleRunDateByIdentifier[identifier] ?? Date.distantPast
            
            if now.timeIntervalSince(lastRunDate) >= duration.timeInterval {
                self.lastThrottleRunDateByIdentifier[identifier] = Date()

                try? await Task.sleep(for: duration)
                
                guard !Task.isCancelled else { return }
                
                await actorType.run(operation)
                
                self.lastThrottleRunDateByIdentifier[identifier] = nil
            }
        }
        
        let runFirstImmediately = {
            guard self.lastThrottleRunDateByIdentifier[identifier] == nil else { return }
            
            self.lastThrottleRunDateByIdentifier[identifier] = Date()
            operation()
        }
        
        switch option {
        case .runFirstImmediately:
            runFirstImmediately()
            
            await execute()
        case .lastGuaranteed:
            await self.debounce(duration, identifier: identifier, on: actorType, operation: operation)
            
            await execute()
        case .combined:
            runFirstImmediately()

            await debounce(duration, identifier: identifier, on: actorType, operation: operation)
            
            await execute()
            
        default:
            await execute()
        }
    }

    /// Delays the execution of an operation by a specified time interval.
    ///
    /// - Parameters:
    ///   - duration: The time interval to delay execution.
    ///   - actorType: The actor type on which to execute the operation (default is main actor).
    ///   - operation: The operation to delay.
    ///
    /// - Note: This method ensures that the operation is executed in a thread-safe manner
    ///         within the specified actor context.
    public func delay(
        _ duration: Duration = .seconds(1.0),
        on actorType: ActorType = .main,
        operation: @escaping () -> Void
    ) async {
        try? await Task.sleep(for: duration)
        await actorType.run(operation)
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + Double(components.attoseconds)/1e18
    }
}
