//
//  Throttler.swift
//  Throttler
//
//  Created by Seoksun Jang on 2021/02/20.
//

import Foundation
import Combine

/// struct either throttling or debouncing successive works with provided options.
public struct Throttler {
    
    typealias WorkIdentifier = String
    
    static private var workers: [WorkIdentifier: Worker] = [:]
    
    /// Debounce a work
    ///
    ///     for i in 0...100000 {
    ///         Throttler.debounce {
    ///             print("your work : \(i)")
    ///         }
    ///     }
    ///
    ///     print("done!")
    ///
    ///     1. if shouldRunImmediately is true,
    ///     => "your work : 0"
    ///     otherwise, ignored.
    ///     2. .... suppressing all the works, and the last
    ///     3. "your work : 100000"
    ///     4. "done!"
    ///
    /// - Note: Pay special attention to the identifier parameter. the default identifier is \("Thread.callStackSymbols") to make api trailing closure for one liner for the sake of brevity. However, it is highly recommend that a developer should provide explicit identifier for their work to debounce.
    ///
    /// - Parameters:
    ///   - identifier: the identifier to group works to debounce. Throttler must have equivalent identifier to each work in a group to debounce.
    ///   - queue: a queue to run the work on.
    ///   - delay: delay for debounce. time unit is second. given default is 1.0 sec.
    ///   - shouldRunImmediately: a boolean type where true will run the first work immediately regardless.
    ///   - work: a work to run
    /// - Returns: Void
    static public func debounce(identifier: String = "\(Thread.callStackSymbols)",
                                queue: DispatchQueue? = nil,
                                delay: DispatchQueue.SchedulerTimeType.Stride = .seconds(1),
                                shouldRunImmediately: Bool = true,
                                work: @escaping () -> Void)
    {
        var worker: Worker? = nil
        let isFirstRun = workers[identifier] == nil ? true : false
        
        if  let w = workers[identifier] {
            worker = w
        } else {
            workers[identifier] = Worker(queue: queue, delay: delay)
            worker = workers[identifier]
        }

        worker!.deploy(
            work: work,
            shouldRunImmediately:shouldRunImmediately && isFirstRun
        )
    }

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
    /// - Note: Pay special attention to the identifier parameter. the default identifier is \("Thread.callStackSymbols") to make api trailing closure for one liner for the sake of brevity. However, it is highly recommend that a developer should provide explicit identifier for their work to debounce.
    ///
    /// - Parameters:
    ///   - identifier: the identifier to group works to throttle. Throttler must have equivalent identifier to each work in a group to throttle.
    ///   - queue: a queue to run the work on.
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

    private class Worker {
        
        private let queue: DispatchQueue?
        private let delay: DispatchQueue.SchedulerTimeType.Stride
        private var workItem: DispatchWorkItem?

        fileprivate init(queue: DispatchQueue? = nil,
                         delay: DispatchQueue.SchedulerTimeType.Stride) {
            self.queue = queue
            self.delay = delay
        }

        fileprivate func deploy(work: @escaping () -> Void,
                                shouldRunImmediately: Bool) {
            if shouldRunImmediately && workItem == nil {
                workItem = DispatchWorkItem(block: work)
                work()
            } else {
                debounce(work)
            }
        }

        private func debounce(_ work: @escaping () -> Void) {
            workItem?.cancel()
            workItem = DispatchWorkItem(block: work)

            let q = queue == nil ? DispatchQueue.global() : queue
            
            q?.asyncAfter(
                deadline: DispatchTime.now() + delay.timeInterval,
                execute: workItem!
            )
        }
    }
}
