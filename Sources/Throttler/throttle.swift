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
   - duration: Foundation `Duration` type such sa .seconds(2.0). By default, .seconds(1.0)
   - identifier: (Optional) An identifier to distinguish between throttled operations. It is highly recommended to provide a custom identifier for clarity and to avoid potential issues with long call stack symbols. Use at your own risk with internal stack traces.
   - actorType: The actor type on which the operation should be executed (default is `.main`).
   - option: An option to customize the behavior of the throttle (default is `.default`).
   - operation: The operation to be executed when throttled.

 - Note:
   - Throttling is a technique to limit the rate at which a function is called. It ensures that the operation is executed no more often than the specified duration.
   - The provided `identifier` is used to group related debounce operations. If multiple debounce calls share the same identifier, they will be considered as part of the same group, and the debounce behavior will apply collectively.

 - Example:

```swift

/// Throttle Options

/// 1. Default: Executes the first operation immediately and then throttles subsequent calls for every 1 second.

for i in 1...100000 {
    throttle(option: .runFirstImmediately) {
        print("throttle : \(i)")
    }
}

// throttle : 1
// throttle : 43584
// throttle : 88485

/// 2. RunFirstImmediately: Executes the first operation immediately and then throttles subsequent calls for every 1 second.

for i in 1...100000 {
    throttle(option: .runFirstImmediately) {
        print("throttle : \(i)")
    }
}

// throttle : 1
// throttle : 43584
// throttle : 88485

/// 3. LastGuaranteed: Guarantees the last call no matter what even after a throttle duration and finished.

for i in 1...100000 {
    throttle(.seconds(2), option: .lastGuaranteed) {
        print("throttle : \(i)")
    }
}

// throttle : 16363
// throttle : 52307
// throttle : 74711
// throttle : 95747
// throttle : 100000

// 4. Combined: Combine all (RunFirstImmediately + LastGuaranteed)

import Throttler

for i in 1...100000 {
    throttle(option: .combined) {
        print("throttle : \(i)")
    }
}

// throttle : 1
// throttle : 25045
// throttle : 30309
// throttle : 35717
// throttle : 48059
// throttle : 61806
// throttle : 75336
// throttle : 88585
// throttle : 100000
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
