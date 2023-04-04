//
//  Throttler.swift
//  Throttler
//  
//  Created by seoksoon jang on 2022-01-03.
//

import Foundation
import Combine

/// struct throttling successive works with provided options.
@available(*, deprecated, message: "This struct is deprecated. Use throttle() function instead.")
public struct Throttler {
    
    typealias WorkIdentifier = String
    
    typealias Work = () -> Void
    typealias Subject = PassthroughSubject<Work, Never>?
    typealias Bag = Set<AnyCancellable>
    
    static private var subjects: [WorkIdentifier: Subject] = [:]
    static private var bags: [WorkIdentifier: Bag] = [:]
    
    /// Throttle a work
    ///
    ///     var sec = 0
    ///     for i in 0...1000000000 {
    ///         Throttler.throttle {
    ///             sec += 1
    ///             print("your work done : \(i)")
    ///         }
    ///     }
    ///
    ///     print("done!")
    ///
    ///
    ///     "your work done : 1"
    ///     (after a delay)
    ///     "your work done : x"
    ///     (after a delay)
    ///     "your work done : y"
    ///     (after a delay)
    ///     "your work done : z"
    ///     ....
    ///     ...
    ///     ..
    ///     .
    ///     "your work done : 1000000000"
    ///
    ///     "done!"
    ///
    /// - Note: Pay special attention to the identifier parameter. the default identifier is \("Thread.callStackSymbols") to make api trailing closure for one liner for the sake of brevity. However, it is highly recommend that a developer should provide explicit identifier for their work to debounce. Also, please note that the default queue is global queue, it may cause thread explosion issue if not explicitly specified , so use at your own risk.
    ///
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
    {
        let isFirstRun = subjects[identifier] == nil ? true : false
        
        if shouldRunImmediately && isFirstRun {
            work()
        }
        
        if let _ = subjects[identifier] {
            subjects[identifier]?!.send(work)
        } else {
            subjects[identifier] = PassthroughSubject<Work, Never>()
            bags[identifier] = Bag()
            
            let q = queue ?? .global()
            
            subjects[identifier]?!
                .throttle(for: delay, scheduler: q, latest: shouldRunLatest)
                .sink(receiveValue: { $0() })
                .store(in: &bags[identifier]!)
        }
    }

}
