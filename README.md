<p align="center">
<img src="https://cdn.icon-icons.com/icons2/390/PNG/512/grim-reaper_38285.png" alt="Throttler" title="Throttler" width="537"/>
</p>

<sub>Icon credits: [Lorc, Delapouite & contributors](https://game-icons.net)</sub>
<br>
<br>

# Throttler

Drop one line to use throttle, debounce, and delay with full thread safety: say goodbye to reactive programming like RxSwift and Combine.

# At a glance

```swift

import Throttler

debounce {
    print("debounce 1 sec")
}

throttle {
    print("throttle 1 sec")
}

delay {
    print("delay 1 sec")
}

```

# 💥 Basic Usage in SwiftUI

Here's how you can quickly get started.

```swift
import SwiftUI
import Throttler

struct ContentView: View {
    var body: some View {
        VStack {
            Button(action: {
                for i in 1...10000000 {
                    throttle {
                        print("throttle: \(i)")
                    }
                }
            }) {
                Text("throttle")
            }
            // Expected Output: Will print "throttle : \(i)" every 1 second (by default)

            Button(action: {
                delay {
                    print("delayed 2 seconds")
                }
            }) {
                Text("delay")
            }
            // Expected Output: Will print "Delayed 2 seconds" after 2 seconds

            Button(action: {
                for i in 1...10000000 {
                    debounce {
                        print("debounce \(i)")
                    }
                }
            }) {
                Text("debounce")
            }
            // Expected Output: Will print "debounce" only after the button has not been clicked for 1 second
        }
    }
}
```

# 🌟 Features
- **Throttle**: Limit how often an operation can be triggered over time. Thanks to Swift's actor model, this operation is thread-safe.
- **Debounce**: Delay the execution of an operation until a certain time has passed without any more triggers. This operation is also thread-safe, courtesy of Swift's actor model.
- **Delay**: Execute an operation after a certain amount of time. With Swift's actor model, you can rest assured that this operation is thread-safe too.

# 🦾 Thread Safety
All of these operations are executed in a thread-safe manner, leveraging the Swift actor model that Throttler utilizes. 
This guarantees safe access and modification of shared mutable state within the closure of throttle, debounce, and delay functions, regardless of the number of threads involved.

Feed any shared resource into them (debounce, throttle, debounce). The functions will handle everything out of box.

```swift
import Foundation

/* a simple thread safe test. */

var counter = 0

DispatchQueue.concurrentPerform(iterations: 10000) { i in
    throttle(.seconds(0.1), identifier: "throttle1") {
        counter += 1
        print("\(i) >> throttle1 : \(counter)")
    }
    
    throttle(.seconds(0.1), identifier: "throttle2") {
        counter += 1
        print("\(i) >> throttle2 : \(counter)")
    }
    
    debounce(.seconds(0.1), identifier: "debounce1") {
        counter += 1
        print("\(i) >> debounce1 : \(counter)")
    }
    
    debounce(identifier: "debounce2") {
        counter += 1
        print("\(i) >> debounce2 : \(counter)")
    }
}

//2 >> throttle1 : 2
//7 >> throttle2 : 1
//3570 >> throttle1 : 3
//3571 >> throttle2 : 4
//4885 >> throttle1 : 5
//4884 >> throttle2 : 6
//5838 >> throttle1 : 7
//5848 >> throttle2 : 8
//6685 >> throttle1 : 9
//6691 >> throttle2 : 10
//7450 >> throttle1 : 11
//7454 >> throttle2 : 12
//8173 >> throttle1 : 13
//8179 >> throttle2 : 14
//8831 >> throttle1 : 15
//8837 >> throttle2 : 16
//9467 >> throttle1 : 17
//9472 >> throttle2 : 18
//9670 >> debounce1 : 19
//9457 >> debounce2 : 20

/// safe from race condition => ✅
/// safe from data race      => ✅

```

# 🚀 Advanced Features for Throttler

Throttler stands out not just for its advanced features, but also for its incredibly simple-to-use API. Here's how it gives you more, right out of the box, with just a **one-liner closure**:

#### Throttle Options

1. **default**: Standard throttling behavior without any fancy tricks. Simply include the throttle function with a one-liner closure, and you're good to go.
2. **ensureLast**: Ensures the last call within the interval gets executed. Just a single line of code.

#### Debounce Options

1. **default**: Standard debounce behavior with just a one-liner closure. Include the debounce function, and it works like a charm.
2. **runFirst**: Get instant feedback with the first call executed immediately, then debounce later. All of this with a simple one-liner.

## DebounceOptions

1. **default**: The standard debounce behavior by default.

```swift
/// by default: duration 1 sec and default debounce (not runFirst)

for i in Array(0...100) {
    debounce {
        print("debounce : \(i)")
    }
}

// debounce : 100
```

2. **runFirst**: Executes the operation immediately, then debounces subsequent calls.

```swift
/// Expected Output: Executes a first task immediately, then debounce only after 1 second since the last operation.

for i in Array(0...100) {
    debounce(.seconds(2), option: .runFirst) {
        print("debounce : \(i)")
    }
}

// debounce : 1        => 💥
// debounce : 100
```

## ThrottleOptions

#### Options Explained

1. **default**: The standard throttle behavior.

```swift

/// Throttle and executes once every 1 second.

for i in 1...100000 {
    throttle {
        print("throttle: \(i)")
    }
}

// throttle: 0
// throttle: 41919
// throttle: 86807

```

2. **ensureLast**: Guarantees that the last call within the interval will be executed.

```swift
/// Guarantees the last call no matter what even after a throttle duration and finished.

for i in 1...100000 {
    throttle(option: .ensureLast) {
        print("throttle : \(i)")
    }
}

// throttle : 0 
// throttle : 16363 
// throttle : 52307
// throttle : 74711
// throttle : 95747
// throttle : 100000    => 💥

```

Throttler makes it extremely simple and easy to use advanced features with just a one-liner, unlike RxSwift and Combine where custom implementations are often required.

# Comparison with RxSwift and Combine for the advanced options in code

- **RxSwift**:

```swift
import RxSwift

let disposeBag = DisposeBag()
Observable.from(1...100000)
    .throttle(RxTimeInterval.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
    .subscribe(onNext: { i in
        print("throttle : \(i)")
    })
    .disposed(by: disposeBag)
```


- **Combine**:

#### Throttle options

```swift
import Combine

var cancellables = Set<AnyCancellable>()
Publishers.Sequence(sequence: 1...100000)
    .throttle(for: .milliseconds(500), scheduler: DispatchQueue.main, latest: false)
    .sink(receiveValue: { i in
        print("throttle : \(i)")
    })
    .store(in: &cancellables)
```

- **Throttler**:
  
```swift 
throttle {
    print("hi")
}
```

```swift
debounce {
    print("hi")
}
```

```swift
for i in 1...100000 {
    throttle(option: .ensureLast) {
        print("throttle : \(i)")
    }
}

// throttle : 16363 
// throttle : 52307
// throttle : 74711
// throttle : 95747
// throttle : 100000    => 💥
```

```swift
for i in Array(0...100) {
    debounce(option: .runFirst) {
        print("debounce : \(i)")
    }
}

// debounce : 1        => 💥
// debounce : 100
```

# Advantages over Combine and RxSwift's Throttle and Debounce
- **Simplicity**: These functions are designed to be straightforward and easy to use. With just a single line of code, you can have them up and running.
- **Out-of-the-Box Thread Safety**: Simply pass any shared resource into the debounce, throttle, or delay functions without any concerns. The implementation leverages the Swift actor model, providing robust protection against data races for mutable states. This ensures that you can safely access and modify shared mutable state without any worries about thread safety. It will handle everything in a thread-safe manner out of box.
- **No Need for Reactive Programming**: If you prefer not to use reactive programming paradigms, this approach provides an excellent alternative. It allows you to enjoy the benefits of throttling and debouncing without having to adopt a reactive programming style.

# :warning: Important Note on Identifiers parameters for debounce and throttle

> **Highly Recommended**: While the functions are intentionally designed to run out of the box without specifying an identifier in favor of brevity, it is **strongly recommended** to provide a custom identifier for `debounce` and `throttle` operations for better control and organization.

### Example with Custom Identifier

```swift

// simple and come in handy by default

throttle {
    print("simple")
}

// recommended

throttle(identifier: "custom_throttle_id") {
    print("This is a recommended way of using throttled.")
}

// simple and come in handy by default

debounce {
    print("simple")
}

// recommended

debounce(.seconds(2), identifier: "custom_debounce_id") {
    print("This is a recommended way of using debounced.")
}

```

# Throttler V2.0.0 - Actor-based Update

## What's New in V2.0.0

In favor of new Swift concurrency, this release completely relies on and leverages the new actor model introduced in Swift 5.5 for better performance and safer code execution.
The previous versions that used standard Swift methods for task management such as GCD has been completely removed as deprecated to emphasize the use of the actor in a unified way.

**(Please be aware that the minimum version requirement has been raised to iOS 16.0, macOS 13.0, watchOS 9.0, and tvOS 16.0.)**

# Struct based (Deprecated)

As of V2.0.0, struct based way was removed as deprecated in favor of Swift actor type. 
Please migrate to functions. (throttle, debounce and delay) 

# Requirements

iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0

# Installation

## Swift Package Manager

To use the latest V2.0.9 version, add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YourRepo/Throttler.git", .upToNextMajor(from: "2.0.9"))
]
```

or in **Xcode**: 
- File > Swift Packages > Add Package Dependency
- Add `https://github.com/boraseoksoon/Throttler.git`
- Click Next.
- Done.

# Contact

boraseoksoon@gmail.com

Pull requests are warmly welcome as well.

# License

Throttler is released under the MIT license. See LICENSE for details.
