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

# Throttler V2.0.0 - Actor-based Update

## What's New in V2.0.0

This version introduces actor-based concurrency for better performance and safer code execution. The previous versions used standard Swift methods for task management, but this release leverages the new actor model introduced in Swift 5.5.


## Basic Usage in SwiftUI

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
                    throttle(identifier: "ThrottleExample") {
                        print("Throttle \(i)")
                    }
                }
            }) {
                Text("Throttle")
            }
            // Expected Output: Will print "Throttle" every 1 second (by default)

            // Delay Example
            Button(action: {
                delay(.duration(.seconds(2))) {
                    print("Delayed 2 seconds")
                }
            }) {
                Text("Delay")
            }
            // Expected Output: Will print "Delayed 2 seconds" after 2 seconds

            // Debounce Example
            Button(action: {
                for i in 1...10000000 {
                    debounce(.seconds(1), identifier: "DebounceExample") {
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

## DebounceOptions

1. **Default**: The standard debounce behavior by default.

```swift
/// by default: duration 1 sec and default debounce (not runFirstImmediately)

for i in Array(0...100) {
    debounce {
        print("debounce : \(i)")
    }
}

// debounce : 100
```

2. **RunFirstImmediately**: Executes the operation immediately, then debounces subsequent calls.

```swift
for i in 1...10000000 {
    debounce(option: .runFirstImmediately) {
        print("Run First Immediately \(i)")
    }
}

/// Expected Output: Executes a first task immediately, then debounce only after 1 second since the last operation.

for i in Array(0...100) {
    debounce(.duration(.seconds(1)), option: .runFirstImmediately) {
        print("debounce : \(i)")
    }
}

// debounce : 1
// debounce : 100
```

## ThrottleOptions

#### Options Explained

1. **Default**: The standard throttle behavior.

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

2. **RunFirstImmediately**: Executes the operation immediately, then throttles subsequent calls.

```swift

/// Executes the first operation immediately and then throttles subsequent calls for every 1 second.

for i in 1...100000 {
    throttle(option: .runFirstImmediately) {
        print("throttle : \(i)")
    }
}

// throttle : 1
// throttle : 43584
// throttle : 88485

```

3. **LastGuaranteed**: Guarantees that the last call within the interval will be executed.

```swift

/// Guarantees the last call no matter what even after a throttle duration and finished.

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

```

4. **Combined**: Combines both `RunFirstImmediately` and `LastGuaranteed`.

```swift

// Combine all

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

## :warning: Important Note on Identifiers parameters for debounce and throttle

> **Highly Recommended**: While the functions do work out of the box without specifying an identifier, it is **strongly recommended** to provide a custom identifier for `debounce` and `throttle` operations for better control and organization.

### Example with Custom Identifier

```swift

throttle(identifier: "custom_throttle_id") {
    print("This is a recommended way of using throttled.")
}

debounce(duration: .seconds(2), identifier: "custom_debounce_id") {
    print("This is a recommended way of using debounced.")
}
```

# Struct based (Deprecated)

As of V2.0.0, struct based way is removed as deprecated in favor of Swift actor type. 
Please migrate to functions. (throttle, debounce and delay) 

## Use case

Let's take a look at what it will look like when with and without Throttler.

<b> With Throttler, </b>
```swift
import UIKit

import Throttler

class ViewController: UIViewController {
    @IBOutlet var button: UIButton!
    
    var index = 0
    
    /********
    Assuming your users will tap the button, and 
    request asyncronous network call 10 times(maybe more?) in a row within very short time nonstop.
    *********/
    
    @IBAction func click(_ sender: Any) {
        print("click1!")
        
        debounce {        
            // Imaging this is a time-consuming and resource-heavy task that takes an unknown amount of time!
            
            let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                self.index += 1
                print("click1 : \(self.index) :  \(String(data: data, encoding: .utf8)!)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}

```

<b> Output: </b>
```swift
click1!
click1!
click1!
click1!
click1!
click1!
click1!
click1!
click1!
click1!
2021-02-20 23:16:50.255273-0500 iOSThrottleTest[24776:813744] 
click1 : 1 :  {
  "userId": 1,
  "id": 1,
  "title": "delectus aut autem",
  "completed": false
}
```

<b>Without Throttler</b>

```swift
class ViewController: UIViewController {
    @IBOutlet var button: UIButton!
    
    var index = 0
    
    /********
    Assuming your users will tap the button, and 
    request asyncronous network call 10 times(maybe more?) in a row within very short time nonstop.
    *********/
    
    @IBAction func click(_ sender: Any) {
        print("click1!")
        
        // Imaging this is a time-consuming and resource-heavy task that takes an unknown amount of time!
        
        let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            self.index += 1
            print("click1 : \(self.index) :  \(String(data: data, encoding: .utf8)!)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}
```

<b>if you don't use Throttler, output is as follows:</b>
```swift
/* 
click1!
2021-02-20 23:16:50.255273-0500 iOSThrottleTest[24776:813744] 
click1 : 1 :  {
  "userId": 1,
  "id": 1,
  "title": "delectus aut autem",
  "completed": false
}
click1!
2021-02-20 23:16:50.255273-0500 iOSThrottleTest[24776:813744] 
click1 : 1 :  {
  "userId": 1,
  "id": 1,
  "title": "delectus aut autem",
  "completed": false
}
click1!
2021-02-20 23:16:50.255273-0500 iOSThrottleTest[24776:813744] 
click1 : 1 :  {
  "userId": 1,
  "id": 1,
  "title": "delectus aut autem",
  "completed": false
}
click1!
2021-02-20 23:16:50.255273-0500 iOSThrottleTest[24776:813744] 
click1 : 1 :  {
  "userId": 1,
  "id": 1,
  "title": "delectus aut autem",
  "completed": false
}
.......
......
.....
...
..
.
😂😂😂

*/
```

<br>

## Advantages over Combine and RxSwift's Throttle and Debounce

- **Simple One-Liners**: The functions are straightforward and ready to use right out of the box. Just include a single line of code to get them up and running.
  
- **No Need for Reactive Programming**: If you're not a fan of reactive programming paradigms, this approach offers an alternative that eliminates the need to adopt them

## Requirements

iOS 13.0, macOS 10.15

### Installation

#### Swift Package Manager

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

### Contact

boraseoksoon@gmail.com

Pull requests are warmly welcome as well.

### License

Throttler is released under the MIT license. See LICENSE for details.
