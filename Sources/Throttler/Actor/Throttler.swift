//
//  Throttler.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-09-08.
//

import Foundation

/// Options for debouncing an operation.
public enum DebounceOptions {
    case `default`         /// The default debounce behavior.
    case runFirst          /// Run the operation immediately and debounce subsequent calls.
}

/// Options for throttling an operation.
public enum ThrottleOptions {
    case `default`         /// The default throttle behavior.
    case ensureLast        /// Guarantee that the last call is executed even if it's after the throttle time.
}

/// a global actor variable for free functions (delay, debounce, throttle) to rely on. (internal use only)
let throttler = Throttler()

/// An actor for managing debouncing, throttling and delay operations designed to be the internal use.
actor Throttler {
    private lazy var cachedTask: [String: Task<(), Never>] = [:]
    private lazy var lastAttemptDate: [String: Date] = [:]
    
    /// Debounces an operation, ensuring it's executed only after a specified time interval
    /// has passed since the last call.
    ///
    /// - Parameters:
    ///   - duration: The time interval for debouncing.
    ///   - identifier: A custom identifier for distinguishing debounce tasks. It's recommended
    ///                 to use your own identifier for better control, but you can use the default
    ///                 which is based on the call stack symbols (use at your own risk).
    ///   - option: The debounce option (default or runFirstImmediately).
    ///   - operation: The operation to debounce.
    ///
    /// - Note: This method ensures that the operation is executed in a thread-safe manner
    ///         within the specified actor context.
    
    func debounce(
        _ duration: Duration = .seconds(1.0),
        identifier: String = "\(Thread.callStackSymbols)",
        option: DebounceOptions = .default,
        operation: @escaping () -> Void
    ) async {
        switch option {
        case .runFirst:
            if cachedTask[identifier] == nil {
                operation()
            }
            fallthrough
        default:
            cachedTask[identifier]?.cancel()
            cachedTask[identifier] = {
                Task {
                    try? await Task.sleep(for: duration)
                    guard !Task.isCancelled else { return }
                    operation()
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
    ///   - option: The throttle option (default or runFirstImmediately).
    ///   - operation: The operation to throttle.
    ///
    /// - Note: This method ensures that the operation is executed in a thread-safe manner
    ///         within the specified actor context.
    
    func throttle(
        _ duration: Duration = .seconds(1.0),
        identifier: String = "\(Thread.callStackSymbols)",
        option: ThrottleOptions = .default,
        operation: @escaping () -> Void
    ) async {
        let lastDate = lastAttemptDate[identifier]
        let lastTimeInterval = Date().timeIntervalSince(lastDate ?? .distantPast)

        let throttleRun = {
            guard lastTimeInterval > duration.timeInterval else { return }
            
            self.lastAttemptDate[identifier] = Date()
            
            try? await Task.sleep(for: duration)
            
            guard !Task.isCancelled else { return }
            
            operation()
            
            self.lastAttemptDate[identifier] = nil
        }

        switch option {
        case .ensureLast:
            await debounce(duration, identifier: identifier, operation: operation)
            
            await throttleRun()
        default:
            await throttleRun()
        }
    }

    /// Delays the execution of an operation by a specified time interval.
    ///
    /// - Parameters:
    ///   - duration: The time interval to delay execution.
    ///   - operation: The operation to delay.
    ///
    /// - Note: This method ensures that the operation is executed in a thread-safe manner
    ///         within the specified actor context.
    
    func delay(
        _ duration: Duration = .seconds(1.0),
        operation: @escaping () -> Void
    ) async {
        try? await Task.sleep(for: duration)
        operation()
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + Double(components.attoseconds)/1e18
    }
}
