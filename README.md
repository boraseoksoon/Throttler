<p align="center">
<img src="https://cdn.icon-icons.com/icons2/390/PNG/512/grim-reaper_38285.png" alt="Throttler" title="Throttler" width="537"/>
</p>

<sub>Icon credits: [Lorc, Delapouite & contributors](https://game-icons.net)</sub>
<br>
<br>

# Throttler

Drop one line to use throttle, debounce, and delay: say goodbye to reactive programming like RxSwift and Combine.

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

# 🌟 Features

- **Throttle**: Limit how often an operation can be triggered over time.
- **Debounce**: Delay the execution of an operation until a certain time has passed without any more triggers.
- **Delay**: Execute an operation after a certain amount of time.

# 💥 Basic Usage in SwiftUI

Here's how you can quickly get started.

```swift
import SwiftUI
import Throttler

struct ContentView: View {

    var body: some View {
        VStack(spacing: 20) {

            // Throttle Example
            Button(action: {
                for i in 1...10000000 {
                    throttle {
                        print("Throttle \(i)")
                    }
                }
            }) {
                Text("Throttle")
            }
            // Expected Output: Will print "Throttle" every 1 second (by default)

            // Delay Example
            Button(action: {
                delay(.seconds(2)) {
                    print("Delayed 2 seconds")
                }
            }) {
                Text("Delay")
            }
            // Expected Output: Will print "Delayed 2 seconds" after 2 seconds

            // Debounce Example
            Button(action: {
                for i in 1...10000000 {
                    debounce {
                        print("Debounce \(i)")
                    }
                }
            }) {
                Text("Debounce")
            }
            // Expected Output: Will print "Debounce" only after the button has not been clicked for 1 second
        }
    }
}
```

# 🚀 Advanced Features for Throttler

Throttler stands out not just for its advanced features, but also for its incredibly simple-to-use API. Here's how it gives you more, right out of the box, with just a **one-liner closure**:

#### Throttle Options

1. **default**: Standard throttling behavior without any fancy tricks. Simply include the throttle function with a one-liner closure, and you're good to go.
2. **runFirst**: Execute the first call instantly while throttling subsequent ones. Again, all it takes is a one-liner.
3. **ensureLast**: Ensures the last call within the interval gets executed. Just a single line of code.
4. **combined**: Enjoy the benefits of both 'Run First Immediately' and 'ensureLast', all in one simple line.

#### Debounce Options

1. **default**: Standard debounce behavior with just a one-liner closure. Include the debounce function, and it works like a charm.
2. **runFirst**: Get instant feedback with the first call executed immediately, then debounce later. All of this with a simple one-liner.

With Throttler, you get these advanced options natively, without the need for custom boilerplate and manual works often required by frameworks like RxSwift and Combine. **Simplicity and power, all in a one-liner closure.**

Unlike RxSwift and Combine, Throttler offers these advanced features natively, eliminating the need for custom configurations.

- **ThrottleOptions**:

default: The standard throttle behavior.
runFirst: Executes the operation immediately, then throttles subsequent calls.
ensureLast: Ensures that the last call is executed.
combined: Combines both runFirst and ensureLast.

- **DebounceOptions**:

default: The standard debounce behavior.
runFirst: Executes the operation immediately, then debounces subsequent calls.

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

// throttle: 41919
// throttle: 86807

```

2. **runFirst**: Executes the operation immediately, then throttles subsequent calls.

```swift

/// Executes the first operation immediately and then throttles subsequent calls for every 1 second.

for i in 1...100000 {
    throttle(option: .runFirst) {
        print("throttle : \(i)")
    }
}

// throttle : 1        => 💥
// throttle : 43584
// throttle : 88485
```

3. **ensureLast**: Guarantees that the last call within the interval will be executed.

```swift

/// Guarantees the last call no matter what even after a throttle duration and finished.

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

4. **combined**: Combines both `runFirst` and `ensureLast`.

```swift

// Combine all

import Throttler

for i in 1...100000 {
    throttle(option: .combined) {
        print("throttle : \(i)")
    }
}

// throttle : 1         => 💥
// throttle : 25045
// throttle : 30309
// throttle : 35717
// throttle : 48059
// throttle : 61806
// throttle : 75336
// throttle : 88585
// throttle : 100000    => 💥

```

## 🌟 Feature Comparison: Throttler vs. RxSwift vs. Combine

| Feature           | Throttler        | RxSwift          | Combine          |
|-------------------|------------------|------------------|------------------|
| Default Behavior  | ✅ One-liner      | Verbose           | Verbose           |
| RunFirst          | ✅ One-liner      | ❌ Custom needed  | ❌ Custom needed  |
| EnsureLast        | ✅ One-liner      | ❌ Custom needed  | ✅ Supported      |
| Combined          | ✅ One-liner      | ❌ Custom needed  | ❌ Custom needed  |

Throttler makes it extremely simple and easy to use advanced features with just a one-liner, unlike RxSwift and Combine where custom implementations are often required.

# Comparison with RxSwift and Combine for the advanced options in code

- **RxSwift**:

#### Throttle options

```swift

let disposeBag = DisposeBag()
let subject = PublishSubject<Int>()

// default ✅
subject
    .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
    .subscribe(onNext: { 
        print("default throttle: \($0)") 
    })
    .disposed(by: disposeBag)

// runFirst ❌:
    // RxSwift's throttle doesn't support this out-of-the-box. 
    // Custom implementation needed.

// ensureLast ❌: 
    // The throttle operation in RxSwift doesn't guarantee last emission. 
    // Custom implementation needed.

// combined ❌:
    // Custom implementation needed combining runFirst and ensureLast.
```

#### Debounce options

```swift

// default ✅
subject
    .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
    .subscribe(onNext: { 
        print("default debounce: \($0)") 
    })
    .disposed(by: disposeBag)

// runFirst ❌
    // RxSwift's debounce doesn't support this out-of-the-box.
    // Custom implementation needed.
```

- **Combine**:

#### Throttle options

```swift

let subject = PassthroughSubject<Int, Never>()

// default: ✅
let cancellable1 = subject
    .throttle(for: .milliseconds(500), scheduler: DispatchQueue.main, latest: true)
    .sink { 
        print("default throttle: \($0)") 
    }

// runFirst ❌
    // Combine's throttle doesn't support this out-of-the-box. 
    // Custom implementation needed.

// ensureLast ✅
let cancellable2 = subject
    .throttle(for: .milliseconds(500), scheduler: DispatchQueue.main, latest: false)
    .sink { 
        print("ensureLast throttle: \($0)") 
    }

// combined ❌
    // Custom implementation needed.

```

#### Debounce options

```swift

// default: ✅
let cancellable3 = subject
    .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    .sink { 
        print("default debounce: \($0)") 
    }

// runFirst
    // combine's debounce doesn't support this out-of-the-box. 
    // Custom implementation needed.
```

- **Throttler**:

✅
```swift 
throttle {
    print("hi")
}
```

✅
```swift
for i in 1...100000 {
    throttle(option: .runFirst) {
        print("throttle : \(i)")
    }
}

// throttle : 1        => 💥
// throttle : 43584
// throttle : 88485
```

✅
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

✅
```swift
for i in 1...100000 {
    throttle(option: .combined) {
        print("throttle : \(i)")
    }
}

// throttle : 1         => 💥
// throttle : 25045
// throttle : 30309
// throttle : 35717
// throttle : 48059
// throttle : 61806
// throttle : 75336
// throttle : 88585
// throttle : 100000    => 💥
```

✅
```
debounce {
    print("hi")
}
```

✅
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

- **Simple One-Liners**: The functions are straightforward and ready to use right out of the box. Just include a single line of code to get them up and running.
- **Advanced debounce and throttler options**: See examples above - they can often come handy.
- **No Need for Reactive Programming**: If you're not a fan of reactive programming paradigms, this approach offers an alternative that eliminates the need to adopt them.

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

As of V2.0.0, struct based way is removed as deprecated in favor of Swift actor type. 
Please migrate to functions. (throttle, debounce and delay) 

# Requirements

iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0

# Installation

## Swift Package Manager

To use the latest V2.0.0 version, add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YourRepo/Throttler.git", .upToNextMajor(from: "2.0.0"))
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
