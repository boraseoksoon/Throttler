<p align="center">
<img src="https://cdn.icon-icons.com/icons2/390/PNG/512/grim-reaper_38285.png" alt="Throttler" title="Throttler" width="537"/>
</p>

<sub>Icon credits: [Lorc, Delapouite & contributors](https://game-icons.net)</sub>
<br>
<br>

# Throttler

Throttler is a library to help you use throttle and debounce in one liner without having to go to reactive programming such as Combine, RxSwift.

<br>

# How to use debounce

Just drop it.

```swift
import Throttler

// advanced debounce, running a first task immediately before initiating debounce.

for i in 1...1000 {
    Throttler.debounce {
        print("debounce! > \(i)")
    }
}

// debounce! > 1
// debounce! > 1000


// equivalent to debounce of Combine, RxSwift.

for i in 1...1000 {
    Throttler.debounce(shouldRunImmediately: false) {
        print("debounce! > \(i)")
    }
}

// debounce! > 1000

```

# How to use throttle

Just drop it.


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

<br>

<p align="center">
<img src="https://firebasestorage.googleapis.com/v0/b/boraseoksoon-ff7d3.appspot.com/o/Throttler.png?alt=media&token=d59cd2dd-e2bc-4214-a1e3-7cd0390c1a5a" alt="Throttler" title="Throttler" width="1024"/>
</p>

<br>

## Advanced debounce

Throttler can do advanced debounce feature, running a first event immediately before initiating debounce that Combine and RxSwift don't have by default.

You could, but you may need a complex implementation yourself for that.

For example, 
Throttler can abstract away this kind of implementation 
https://stackoverflow.com/questions/60295544/how-do-you-apply-a-combine-operator-only-after-the-first-message-has-been-receiv

into 

```swift
import Throttler

for i in 1...1000 {
    Throttler.debounce {
        print("debounce! > \(i)")
    }
}

// debounce! > 1
// debounce! > 1000

```
That's it

## Migration 1.0.4 -> 1.0.5

Throttler.go is equivalent to Throttler.debounce(shouldRunImmediately: false)

```swift
Throttler.go {
    print("your work!")
}

Throttler.debounce(shouldRunImmediately: false) {
    print("your work!")
}
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
        
        Throttler.debounce {
        
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
- To debounce and throttle tasks, you don't have to go to reactive programming like black magic in some sense 😅. 
- You can get advanced debounce out of box (see above)
- For those who hate learning Reactive programming

## Requirements
- Swift 5.3+

### Installation


#### Swift Package Manager

- File > Swift Packages > Add Package Dependency
- Add `https://github.com/boraseoksoon/Throttler.git`
- Click Next.
- Done :)


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
