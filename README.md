<p align="center">
<img src="https://cdn.icon-icons.com/icons2/390/PNG/512/grim-reaper_38285.png" alt="Throttler" title="Throttler" width="537"/>
</p>

<sub>Icon credits: [Lorc, Delapouite & contributors](https://game-icons.net)</sub>
<br>
<br>

# Throttler

One Line to throttle, debounce and delay: Say Goodbye to Reactive Programming such as RxSwift and Combine.

# At a glance

```swift

/// throttle

for i in (0...10000000) {
    throttle {
        print(i)
    }
}

//  0
//  3210779
//  6509981
//  9809756

// specify an interval

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

/// debounce

debounce {
    print("debounce with 1 second interval")
}

debounce(.seconds(3)) {
    print("debounce with 3 seconds interval")
}

/// delay

delay {
    print("fired after 1 sec")
}

delay(.seconds(2)) {
    print("fired after 2 sec")
}
```

# What functions look like in SwiftUI: 

```swift
import SwiftUI
import Throttler

struct ContentView: View {
  
  var body: some View {
    VStack(spacing: 20) {
      Button(action: {
        if #available(iOS 16.0, *) {
         for i in (0...10000000) {
            throttle {
              print(i)
            }
          }
        } else {
          for i in (0...10000000) {
            throttle(seconds: 0.01) {
              print(i)
            }
          }
        }
        
//          0
//          3210779
//          6509981
//          9809756
        
      }) {
        Text("throttle")
      }
      
      Button(action: {
        if #available(iOS 16.0, *) {
          delay(.seconds(2)) {
            print("fired after 2 sec")
          }
          
          //                    delay {
          //                        print("fired after 1 sec")
          //                    }
          
        } else {
          delay(seconds: 2) {
            print("fired after 2 sec")
          }
        }
        
        // (delay 2 second..)
        // ...
        // fired after 2 sec
        
      }) {
        Text("delay")
      }
      
      Button(action: {
        if #available(iOS 16.0, *) {
          debounce {
            print("fired after 1 second")
          }
        } else {
          debounce(seconds: 1.0, on: .main) {
            print("fired after 1 second")
          }
        }
        
        // (click a button as fast as you can)
        // ....
        // ....
        // ....
        // fired after 1 second
        
      }) {
        Text("""
          debounce
          (click a button continuously as fast as you can)
        """)
      }
    }
  }
}
```

# Struct based (Deprecated, not recommended)

* Throttler

```swift
var sum = 0

for i in 0...10 {
    print("for loop : \(i)")

    // equivalent to throttle RxSwift and Combine provides by default.
    Throttler.throttle(delay: .milliseconds(10)) {
        sum += 1
        print("sum : \(sum)")
    }
}

// for loop : 0
// sum : 1
// for loop : 1
// for loop : 2
// sum : 2
// for loop : 3
// for loop : 4
// for loop : 5
// for loop : 6
// sum : 3
// for loop : 7
// for loop : 8
// for loop : 9
// for loop : 10
// sum : 4

```

* Debouncer

```swift
import Throttler

// advanced debounce, running a first task immediately before initiating debounce.

for i in 1...1000 {
    Debouncer.debounce {
        print("debounce! > \(i)")
    }
}

// debounce! > 1
// debounce! > 1000


// equivalent to debounce of Combine, RxSwift.

for i in 1...1000 {
    Debouncer.debounce(shouldRunImmediately: false) {
        print("debounce! > \(i)")
    }
}

// debounce! > 1000

```

<br>

## Advanced struct-based debounce

Throttler can do advanced debounce feature, running a first event immediately before initiating debounce that Combine and RxSwift don't have by default.

You could, but you may need a complex implementation yourself for that.

For example, 
Throttler can abstract away this kind of implementation 
https://stackoverflow.com/a/60307697/3426053

into 

```swift
import Throttler

for i in 1...1000 {
    Debouncer.debounce {
        print("debounce! > \(i)")
    }
}

// debounce! > 1
// debounce! > 1000

```
That's it

## Use case

While it is originally developed to solve the problem where vast number of user typing input<br>involving CPU intensive tasks have be to performed repeatedly and constantly<br>on [HLVM,](https://hlvm.co.kr)

A common problem that Throttler can solve is <br>a user taps a button that requests asynchronous network call a massive number of times <br>
within few seconds. 

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
        
        Debouncer.debounce {
        
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

<b>if you don't use Throttler, Output is as follows:</b>
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
Your server will be hell busy trying to response all the time (putting cache aside)
😂😂😂

*/
```

<br>

## Advantages Versus Combine, RxSwift Throttle and Debounce
- One liner, no brainer. you can just drop the one line code and it will get up and running out of box.
- For those who don't prefer Reactive programming to do debounce and throttle operation, you don't have to go to reactive programming like black magic in some sense. 

## Requirements

iOS 13.0, macOS 10.15
(To use latest version API, iOS 16.0 and macOS 13.0 are required.) 

``` swift

if #available(iOS 16.0, *) {
     for i in (0...10000000) {
        throttle {
            print(i)
        }
    }
} else {
    for i in (0...10000000) {
        throttle(seconds: 0.01) {
            print(i)
        }
    }
}

@available(macOS 13.0, *)
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
```

### Installation

#### Swift Package Manager

- File > Swift Packages > Add Package Dependency
- Add `https://github.com/boraseoksoon/Throttler.git`
- Click Next.
- Done.

### To-Do:

1. Provide an option that ensures the final execution of a job, regardless of whether it has been throttled or debounced.
2. Write more useful functions that can accomplish tasks in a single line of code.

### Contact

boraseoksoon@gmail.com

Pull requests are warmly welcome as well.

### License

Throttler is released under the MIT license. See LICENSE for details.
