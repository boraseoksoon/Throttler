//
//  debounce.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

import Foundation

/**
 Debounce Function

 - Parameters:
   - duration: The time duration for which to debounce the operation. It specifies the time interval during which repeated calls to the operation will be ignored.
   - identifier: A unique identifier for this debounce operation. By default, it uses the call stack symbols as the identifier. You can provide a custom identifier to group related debounce operations. It is highly recommended to use your own identifier to avoid unexpected behavior, but you can use the internal stack trace identifier at your own risk.
   - actorType: The actor context in which to run the operation. Use `.main` to run the operation on the main actor or `.current` for the current actor context.
   - option: The debounce option to control the behavior of the debounce operation. You can choose between `.default` and `.runFirstImmediately`. The default behavior delays the operation execution by the specified duration, while `runFirstImmediately` executes the operation immediately and applies debounce to subsequent calls.
   - operation: The operation to debounce. This is a closure that contains the code to be executed when the debounce conditions are met.

 - Note:
   - Debouncing is a technique to limit the rate at which a function is called. It ensures that the operation is executed only once after a series of rapid calls within the specified duration.
   - The provided `identifier` is used to group related debounce operations. If multiple debounce calls share the same identifier, they will be considered as part of the same group, and the debounce behavior will apply collectively.

 - Example:
   ```swift
   // Debounce a button tap action to prevent rapid execution.
   @IBAction func buttonTapped(_ sender: UIButton) {
       debounce {
           print("Button tapped")
       }
 
       for _ in Array(0...1000) {
           debounce(.duration(.microseconds(100)), identifier: "your.identifier.0") {
               print("hi")
           }
       }
 
       for _ in Array(0...1000) {
           debounce(.seconds(3.3), identifier: "your.identifier.1") {
               print("hi")
           }
       }
   }
 */

public func debounce(
    _ duration: TimeDuration = .seconds(1.0),
    identifier: String = "\(Thread.callStackSymbols)",
    on actorType: ActorType = .main,
    option: DebounceOptions = .default,
    operation: @escaping () -> Void
) {
    Task {
        await actor.debounce(
            duration,
            identifier: identifier,
            on: actorType,
            option: option,
            operation: operation
        )
    }
}
