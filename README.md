<p align="center">
<img src="https://cdn.icon-icons.com/icons2/390/PNG/512/grim-reaper_38285.png" alt="Throttler" title="Throttler" width="537"/>
</p>

<sub>Icon credits: [Lorc, Delapouite & contributors](https://game-icons.net)</sub>
<br>
<br>

# Throttler

Throttler is a library that throttles unnecessarily repeated and <br>massive inputs until the last in one liner API.

[How Throttler works in Yotube](https://www.youtube.com/watch?v=iER3GQ_X7X0)

<br>

# How to use

Just drop it.


```swift
import Throttler

for i in 1...1000 {
    Throttler.go {
        print("go! > \(i)")
    }
}

// go! > 1000
```

<br>

<p align="center">
<img src="https://firebasestorage.googleapis.com/v0/b/boraseoksoon-ff7d3.appspot.com/o/Throttler.png?alt=media&token=d59cd2dd-e2bc-4214-a1e3-7cd0390c1a5a" alt="Throttler" title="Throttler" width="1024"/>
</p>

<br>

[How to use in Yotube](https://youtu.be/UvWZ8uv0j0s)

<br>


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
        
        Throttler.go {
        
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
Your server will start to cry!
😂😂😂

*/
```

<br>

Fundamentally, Throttler can be used to solve various type of problems<br>related to any repeated and continuous input issue <br> usually iOS software engineers usually want to avoid.
<br><br>

It is a common situation I can meet in my daily work.<br>Think about how many lines you need to write without Throttler<br>to solve these repeatedly tedious and error-prone task!
<br>
<br>

## Why made?
Is it only me who always realized later on iOS I did not validate continuous and repeated input of users (who rapidly bash buttons like tap tap tap, click click click really in a 10 times in a row in few seconds) requesting pretty heavy HTTP request or some resource consuming task? and QA told me please it needs to be controlled on front-end in the first place.<br>
After that, I always repeatedly used to implement this task using DispatchWorkItem or Combine, Timer with isUserInteractionEnabled flags or <br> even worse,
UIApplication.shared.beginIgnoringInteractionEvents() <br>UIApplication.shared.endIgnoringInteractionEvents()
things like that... ( I know it should be only used when you have really no time under serious pressure)<br>

Again, this time while doing my own project, I met this issue again.<br>

So, I made up my mind to build my own yesterday.


## Advantages Versus Combine, RxSwift Throttle and Debounce
- Concise API, one liner, no brainer
- DispatchWorkItem does the job here. It can cancel http request not initiated out of box.
- Backward compatibility. Combine needs iOS 13 / macOS Catalina and its new runtime to work. There is no backward compatibility to earlier versions of their operating systems planned. (currently we are living 2021 though...;) 

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
