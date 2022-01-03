<p align="center">
<img src="https://cdn.icon-icons.com/icons2/390/PNG/512/grim-reaper_38285.png" alt="Throttler" title="Throttler" width="537"/>
</p>

<sub>Icon credits: [Lorc, Delapouite & contributors](https://game-icons.net)</sub>
<br>
<br>

# Throttler

Throttler is a library to help you use throttle and debounce in one liner without having to go to reactive programming such as Combine, RxSwift.

# How to use throttle

Just drop it.

```swift
for i in 0...10 {
    Throttler.throttle {
       print("throttle : \(i)")
    }
}
```


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

# How to use debounce

Just drop it.

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

## Advanced debounce

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

## Migration 1.0.4 -> 1.0.6

Throttler.go does the equivalent job to Throttler.debounce(shouldRunImmediately: false)

```swift
// 1.0.4

for i in 1...1000 {
    Throttler.go {
        print("debounce! > \(i)")
    }
}

// debounce! > 1000

// 1.0.6

for i in 1...1000 {
    Debouncer.debounce(shouldRunImmediately: false) {
        print("debounce! > \(i)")
    }
}

// debounce! > 1000
```

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
- One liner, no brainer
- for those who don't prefer Reactive programming to do debounce and throttle operation, you don't have to go to reactive programming like black magic in some sense. 
- You can get advanced debounce out of box (see above)

## Requirements

iOS 13.0, macOS 10.15
        
## Note

Pay special attention to the identifier parameter. the default identifier is \("Thread.callStackSymbols") to make api trailing closure for one liner for the sake of brevity. However, it is highly recommend that a developer should provide explicit identifier for their work to debounce. Also, please note that the default queue is global queue, it may cause thread explosion issue if not explicitly specified, so use at your own risk.

```swift

    /// - Parameters:
    ///   - identifier: the identifier to group works to throttle. Throttler must have equivalent identifier to each work in a group to throttle.
    ///   - queue: a queue to run a work on. dispatch global queue will be chosen by default if not specified.
    ///   - delay: delay for throttle. time unit is second. given default is 1.0 sec.
    ///   - shouldRunImmediately: a boolean type where true will run the first work immediately regardless.
    ///   - shouldRunLatest: A Boolean value that indicates whether to publish the most recent element. If `false`, the publisher emits the first element received during the interval.
    ///   - work: a work to run
    /// - Returns: Void
    static public func throttle(identifier: String = "\(Thread.callStackSymbols)",
                                queue: DispatchQueue? = nil,
                                delay: DispatchQueue.SchedulerTimeType.Stride = .seconds(1),
                                shouldRunImmediately: Bool = true,
                                shouldRunLatest: Bool = true,
                                work: @escaping () -> Void)
```

### Installation

#### Swift Package Manager

- File > Swift Packages > Add Package Dependency
- Add `https://github.com/boraseoksoon/Throttler.git`
- Click Next.
- Done.


### Contact

boraseoksoon@gmail.com
<br>

https://boraseoksoon.com
<br>

https://hlvm.co.kr
<br>

Pull requests are warmly welcome as well.

### License

Throttler is released under the MIT license. See LICENSE for details.
