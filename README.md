<p align="center">
<img src="https://cdn.icon-icons.com/icons2/390/PNG/512/grim-reaper_38285.png" alt="Throttler" title="Throttler" width="537"/>
</p>

<sub>Icon credits: [Lorc, Delapouite & contributors](https://game-icons.net)</sub>
<br>
<br>

# Throttler

Drop one line to use throttle, debounce, delay, repeat, timeout, time, and retry with Swift concurrency: say goodbye to reactive programming like RxSwift and Combine.

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

`repeat`(every: .seconds(1), times: 3) {
    print("repeat every 1 sec, 3 times")
}

let value = try await timeout(.seconds(3)) {
    try await fetchValue()
}

let measured = try await time("fetch") {
    try await fetchValue()
}

let retried = try await retry(3, every: .milliseconds(300)) {
    try await fetchValue()
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
- **Repeat**: Run an operation on a serial cadence for a fixed number of times or until the returned task is cancelled.
- **Timeout**: Put a maximum duration around async work and cancel the operation task when the deadline wins.
- **Time**: Measure work without changing its return value or thrown error.
- **Retry**: Retry temporary async failures with a simple attempt count and delay.

# 🦾 Thread Safety
`throttle`, `debounce`, `delay`, and `repeat` can run their operations through `ActorType`, leveraging the Swift actor model.
This supports safe access and modification of shared mutable state within those scheduled closures when you choose the right actor context.
`timeout`, `time`, and `retry` wrap async work directly; use normal Swift actor isolation for mutable state inside those operations.

Feed shared resources into the actor-backed scheduling functions. They will handle actor execution out of box.

```swift
import Foundation

/* a simple thread safe test. */

var a = 0

DispatchQueue.global().async {
    for _ in Array(0...10000) {
        throttle(.seconds(0.1), by: .ownedActor) {
            a+=1
            print("throttle1 : \(a)")
        }
    }
}

DispatchQueue.global().async {
    for _ in Array(0...100) {
        throttle(.seconds(0.01), by: .ownedActor) {
            a+=1
            print("throttle2 : \(a)")
        }
    }
}

DispatchQueue.global().async {
    for _ in Array(0...100) {
        throttle(.seconds(0.001), by: .ownedActor) {
            a+=1
            print("throttle3 : \(a)")
        }
    }
}

DispatchQueue.global().async {
    for _ in Array(0...100) {
        debounce(.seconds(0.001), by: .ownedActor) {
            a+=1
            print("debounce1 : \(a)")
        }
    }
}

//throttle3 : 1
//throttle3 : 2
//throttle3 : 3
//throttle3 : 4
//throttle3 : 5
//throttle3 : 6
//throttle3 : 7
//throttle3 : 8
//throttle3 : 9
//throttle3 : 10
//throttle3 : 11
//debounce1 : 12
//throttle3 : 13
//throttle2 : 14
//throttle1 : 15
//throttle1 : 16
//throttle1 : 17
//throttle1 : 18
//throttle1 : 19
//throttle1 : 20
//throttle1 : 21
//throttle1 : 22
//throttle1 : 23
//throttle1 : 24
//throttle1 : 25
//throttle1 : 26
//throttle1 : 27

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

## Repeat

`repeat` is for periodic work. Because `repeat` is a Swift keyword, call it with backticks.

```swift
let task = `repeat`(every: .seconds(5), times: 3, by: .mainActor) {
    await refreshStatus()
}

// Stop future iterations when needed.
task.cancel()
```

Behavior contract:

- `times: nil` repeats until the returned task is cancelled.
- `times: 3` runs exactly three successful iterations unless cancelled or an iteration throws.
- `startingImmediately: true` runs once right away, then waits before future iterations.
- `startingImmediately: false` waits first, then runs.
- Iterations never overlap. The next wait starts after the current operation finishes.
- A non-positive interval completes without running to avoid a busy loop.
- If an iteration throws, `onError` is called and the repeat loop stops.

## Timeout

`timeout` is for bounding async work that has already started.

```swift
do {
    let response = try await timeout(.seconds(3)) {
        try await api.fetch()
    }
    print(response)
} catch TimeoutError.timedOut(_) {
    print("request timed out")
}
```

Behavior contract:

- If the operation finishes first, `timeout` returns the operation value.
- If the operation throws first, `timeout` throws the operation error.
- If the deadline wins, `timeout` cancels the operation child task and throws `TimeoutError.timedOut(duration)` after structured child-task cleanup completes.
- A non-positive timeout duration throws `TimeoutError.timedOut(duration)` immediately.
- Swift task cancellation is cooperative, so blocking or cancellation-ignoring operations can delay cleanup.

## Time

`time` is for measuring work without changing the work.

```swift
let user = try await time("fetch user") {
    try await api.fetchUser()
}
```

Default compact output:

```text
[Throttler] fetch user completed in 124.3 ms
[Throttler] fetch user failed in 2.100 s: NetworkError.timeout
[Throttler] completed in 8.7 ms
```

Verbose output:

```swift
try await time("fetch user", style: .verbose) {
    try await api.fetchUser()
}
```

```text
[Throttler] label="fetch user" result=success duration="124.3 ms"
[Throttler] label="fetch user" result=failure duration="2.100 s" error="NetworkError.timeout"
```

Custom reporting destination:

```swift
try await time("fetch user", report: { logger.info("\($0)") }) {
    try await api.fetchUser()
}
```

Behavior contract:

- Sync and async overloads are available.
- The async overload uses `@Sendable` closures for Swift 6 concurrency safety.
- The operation starts immediately.
- The operation return value is returned unchanged, including `Void`.
- The original operation error is rethrown unchanged.
- Duration is reported after success and after failure.
- Measurement uses `ContinuousClock`, not wall-clock time.
- `time` does not change actor context.

## Retry

`retry` is for temporary async failures.

```swift
let user = try await retry(3, every: .milliseconds(300)) {
    try await api.fetchUser()
}
```

Behavior contract:

- The first attempt runs immediately.
- `retry(3, every: .milliseconds(300))` means 3 total attempts.
- The delay happens only after a failed attempt when another attempt remains.
- The first successful attempt returns immediately.
- If every attempt fails, the last operation error is thrown.
- `CancellationError` is not retried.
- Parent-task cancellation during the operation or delay throws cancellation.
- Attempts never overlap.
- The operation closure and returned value are `Sendable` for Swift 6 concurrency safety.
- A non-positive delay retries immediately.
- A non-positive attempt count throws `RetryError.invalidAttemptCount(maxAttempts)`.

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
import Throttler

throttle {
    print("hi")
}
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

# Throttler V2.2.3 - Time and retry update

## What's New in V2.2.3

- Added `time` sync and async wrappers for measuring work while preserving the original return value and thrown error.
- Added `TimeReportStyle.compact` and `.verbose`.
- Added custom `report` destination support for `time`.
- Added `retry(_:every:operation:)` for async retry with total attempt count and delay.
- Added `RetryError.invalidAttemptCount(Int)`.
- Added tests for time success, failure, `Void`, verbose output, retry success, retry failure, retry delay, invalid count, and cancellation.
- Documented exact behavior contracts for time and retry.

# Throttler V2.2.2 - Repeat and timeout update

## What's New in V2.2.2

- Added `` `repeat`(every:times:startingImmediately:by:onError:operation:) `` for serial periodic work.
- Added `timeout(_:operation:)` for value-returning async operations with a maximum duration.
- Added `TimeoutError.timedOut(Duration)` so timeout failures can be matched directly.
- Added tests for repeat count, immediate start, repeat cancellation, repeat error handling, timeout success, timeout cancellation, and operation-error propagation.
- Documented exact behavior contracts for repeat and timeout so future agents can verify changes against the intended API.

# Throttler V2.2.1 - Safer scheduling update

## What's New in V2.2.1

This release keeps the existing public `throttle`, `debounce`, and `delay` APIs while replacing the internal scheduling with a monotonic-clock actor implementation.

- `debounce(.runFirst)` no longer schedules a duplicate trailing run after the immediate run.
- `debounce` protects scheduled work with generation checks so older tasks cannot clear newer scheduled work.
- `debounce` no longer cancels an operation that has already started running when a newer call arrives.
- `throttle` now runs the first eligible call immediately and uses `.ensureLast` to schedule the latest suppressed call at the end of the throttle window.
- `delay` has an additive async/throws overload that returns `Task<Void, Never>` for cancellation.
- `sleep(_:)` and `execute(with:on:)` are available as convenience helpers.
- `ActorType.ownedActor` runs operations on a package-owned serial actor.
- `ActorType.taskContext` runs operations directly in the scheduled task context.
- `ActorType.mainActor` dispatches legacy synchronous closures to the main actor. Async closures that need main-actor isolation should still use Swift's normal `@MainActor` isolation at the call site.
- Legacy synchronous closures keep their source-compatible `() -> Void` API while using an internal Sendable wrapper for Swift 6 builds.

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

To use the latest V2.2.3 version, add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/boraseoksoon/Throttler.git", .upToNextMajor(from: "2.2.3"))
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
