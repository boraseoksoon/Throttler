<p align="center">
<img src="https://cdn.icon-icons.com/icons2/390/PNG/512/grim-reaper_38285.png" alt="Throttler" title="Throttler" width="537"/>
</p>

<sub>Icon credits: [Lorc, Delapouite & contributors](https://game-icons.net)</sub>

# Throttler

Throttler is a small Swift concurrency package for scheduling and measuring work:
`debounce`, `throttle`, `delay`, `` `repeat` ``, `timeout`, `time`, and `retry`.

It is useful when you want direct closure-based helpers instead of building a
reactive pipeline for simple timing behavior.

## Requirements

- Swift 5.9+
- iOS 16.0+
- macOS 13.0+
- watchOS 9.0+
- tvOS 16.0+

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/boraseoksoon/Throttler.git", .upToNextMajor(from: "2.2.6"))
]
```

In Xcode, add this package URL:

```text
https://github.com/boraseoksoon/Throttler.git
```

## Quick Start

```swift
import Throttler

debounce {
    print("runs after 1 second without another call from this call site")
}

throttle {
    print("runs immediately, then suppresses calls from this call site for 1 second")
}

delay(.seconds(2)) {
    print("runs after 2 seconds")
}

`repeat`(every: .seconds(1), times: 3) {
    await refreshStatus()
}

Task {
    let value = try await timeout(.seconds(3)) {
        try await fetchValue()
    }

    let measured = try await time("fetch") {
        try await fetchValue()
    }

    let retried = try await retry(3, every: .milliseconds(300)) {
        try await fetchValue()
    }
}
```

## Identifiers

`debounce` and `throttle` group calls by `identifier`.

When `identifier` is omitted, the package derives one from the call site
(`fileID:line:column`). Repeated calls from the same source location share one
group. Calls from different source locations are separate.

Use an explicit identifier when calls from different locations should share one
group, or when grouping should depend on a dynamic value.

```swift
debounce(.milliseconds(300), identifier: "search") {
    performSearch()
}

throttle(.seconds(1), identifier: "row:\(rowID)") {
    refreshRow(rowID)
}
```

The default identifier path avoids stack-symbol capture. It still performs the
normal work needed to build and compare the call-site identifier.

## ActorType

The scheduling helpers that accept `by actor: ActorType` use that value to run
the scheduled closure.

- `.mainActor`: sync closures run on the main actor. Async closures are invoked
  from the main actor, but normal Swift actor isolation still applies inside the
  async body.
- `.ownedActor`: closures run through a package-owned serial actor.
- `.taskContext`: closures run directly in the scheduled task context.
- `.currentActor`: legacy alias for `.taskContext`; it does not hop back to the
  caller's actor.

The package's scheduling state is actor-backed. Shared mutable state inside your
operation still needs the right actor context or normal Swift synchronization.

## Debounce

`debounce` runs only the latest call in a burst.

```swift
for value in 1...5 {
    debounce(.milliseconds(300), identifier: "input") {
        print(value)
    }
}

// Later, after the debounce window, prints:
// 5
```

Behavior contract:

- The default duration is 1 second.
- Calls with the same resolved identifier share one debounce group.
- `.default` delays each call; a newer pending call replaces the older pending
  call.
- `.runFirst` runs the first eligible call immediately, then debounces later
  calls in the same window.
- A non-positive duration runs immediately.
- An operation that has already started is not cancelled by a newer call.
- The sync overload is fire-and-forget.
- The async throwing overload returns the task that submits the scheduling
  request. Thrown errors are delivered to `onError`.

## Throttle

`throttle` runs the first eligible call immediately and suppresses later calls
until the window has elapsed.

```swift
for value in 1...5 {
    throttle(.seconds(1), identifier: "save") {
        print(value)
    }
}

// In a tight burst with the default option, prints only the first eligible call.
```

Behavior contract:

- The default duration is 1 second.
- Calls with the same resolved identifier share one throttle group.
- `.default` drops suppressed calls.
- `.ensureLast` schedules the latest suppressed call to run after the remaining
  throttle window.
- A non-positive duration runs immediately.
- The sync overload is fire-and-forget.
- The async throwing overload returns the task that submits the scheduling
  request. Thrown errors are delivered to `onError`.

## Delay

`delay` runs an operation after a duration.

```swift
delay(.seconds(2)) {
    print("runs after 2 seconds")
}

let task = delay(.seconds(2), by: .taskContext) {
    await refreshStatus()
}

task.cancel()
```

Behavior contract:

- The default duration is 1 second.
- A non-positive duration runs immediately.
- The sync overload is fire-and-forget.
- The async throwing overload returns the delay task. Cancelling it before the
  operation starts prevents the operation from running.
- Thrown errors from the async overload are delivered to `onError`.

## Sleep and Execute

`sleep(_:)` waits for a positive duration and returns early when the task is
cancelled. Non-positive durations return immediately.

```swift
await sleep(.milliseconds(250))
```

`execute(with:on:operation:)` returns a task that optionally waits, then runs the
operation through the selected `ActorType`.

```swift
let task = execute(with: .milliseconds(250), on: .taskContext) {
    await refreshStatus()
}
```

Cancelling the returned task before the operation starts prevents the operation
from running.

## Repeat

`` `repeat` `` runs async work on a serial cadence. Because `repeat` is a Swift
keyword, call it with backticks.

```swift
let task = `repeat`(every: .seconds(5), times: 3, by: .mainActor) {
    await refreshStatus()
}

task.cancel()
```

Behavior contract:

- `times: nil` repeats until the returned task is cancelled.
- `times: 3` runs exactly three successful iterations unless cancelled or an
  iteration throws.
- `startingImmediately: true` runs once right away, then waits before future
  iterations.
- `startingImmediately: false` waits first, then runs.
- Iterations never overlap. The next wait starts after the current operation
  finishes.
- A non-positive interval completes without running.
- A non-positive `times` value completes without running.
- If an iteration throws, `onError` is called and the repeat loop stops.
- `CancellationError` stops the loop without calling `onError`.

## Timeout

`timeout` bounds async work with a maximum duration.

```swift
do {
    let response = try await timeout(.seconds(3)) {
        try await api.fetch()
    }
    print(response)
} catch TimeoutError.timedOut(let duration) {
    print("timed out after \(duration)")
}
```

Behavior contract:

- If the operation finishes first, `timeout` returns the operation value.
- If the operation throws first, `timeout` throws the operation error.
- If the deadline wins, `timeout` cancels the operation child task and throws
  `TimeoutError.timedOut(duration)` after structured child-task cleanup
  completes.
- A non-positive duration throws `TimeoutError.timedOut(duration)` immediately.
- Swift task cancellation is cooperative, so blocking or cancellation-ignoring
  operations can delay cleanup.

## Time

`time` measures work, reports the elapsed duration, and returns or throws exactly
as the operation does.

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
- The async overload uses `@Sendable` closures.
- The operation starts immediately.
- The operation return value is returned unchanged, including `Void`.
- The original operation error is rethrown unchanged.
- Duration is reported after success and after failure.
- Measurement uses `ContinuousClock`, not wall-clock time.
- `time` does not change actor context.

## Retry

`retry` reruns async work until it succeeds or the attempt limit is reached.

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
- The operation closure and returned value are `Sendable`.
- A non-positive delay retries immediately.
- A non-positive attempt count throws `RetryError.invalidAttemptCount(maxAttempts)`.

## Version Notes

### 2.2.6

- Rewrote the README around current behavior contracts.
- Removed stale examples, stale installation version text, and broad thread-safety
  claims that were easy to misread.

### 2.2.5

- Async `debounce` and `throttle` calls can omit `identifier`, matching the sync
  API.
- Default async identifiers are derived from the call site.
- Explicit `identifier` async calls keep the same source shape as 2.2.4.
- The internal synchronous-closure wrapper was renamed from the stale
  `LegacyOperation` name to `SynchronousOperation`.

### 2.2.4

- Default sync `debounce` and `throttle` identifiers moved from
  `Thread.callStackSymbols` to call-site magic-literal parameters.
- The internal debounce/throttle scheduling state was unified.
- Debounce and throttle state remain independent for the same identifier.
- `ActorType` docs were corrected for `.mainActor` and `.currentActor`.
- Stale Linux XCTest manifest files were removed.

### 2.2.3

- Added `time`.
- Added `TimeReportStyle.compact` and `.verbose`.
- Added custom `report` destinations for `time`.
- Added `retry(_:every:operation:)`.
- Added `RetryError.invalidAttemptCount(Int)`.

### 2.2.2

- Added `` `repeat`(every:times:startingImmediately:by:onError:operation:) ``.
- Added `timeout(_:operation:)`.
- Added `TimeoutError.timedOut(Duration)`.

### 2.2.1

- Reworked debounce/throttle/delay internals around a monotonic-clock actor.
- Fixed duplicate trailing execution for `debounce(.runFirst)`.
- Added generation checks so older scheduled debounce work cannot clear newer
  scheduled work.
- Added the async/throws `delay` overload that returns `Task<Void, Never>`.
- Added `sleep(_:)` and `execute(with:on:)`.
- Added `.ownedActor` and `.taskContext`.

### 2.0.0

- Raised platform requirements to iOS 16.0, macOS 13.0, watchOS 9.0, and
  tvOS 16.0.
- Removed the older struct-based API in favor of the closure helper functions.

## Contact

boraseoksoon@gmail.com

Pull requests are welcome.

## License

Throttler is released under the MIT license. See LICENSE for details.
