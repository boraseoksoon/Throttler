//
//  Debouncer.swift
//  Throttler
//
//  Created by Seoksun Jang on 2021/02/20.
//

import Foundation

/// struct debouncing successive works with provided options.
public struct Debouncer {
    
    typealias WorkIdentifier = String
    
    static private var workers: [WorkIdentifier: Worker] = [:]
    
    /// Debounce a work
    ///
    ///     for i in 0...100000 {
    ///         Debouncer.debounce {
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
    /// - Note: Pay special attention to the identifier parameter. 
    ///         The default identifier is \("Thread.callStackSymbols") to make api trailing closure for one liner for the sake of brevity. 
    ///         However, it is highly recommend that a developer should provide explicit identifier for their work to debounce. 
    ///         Also, please note that the default queue is global queue, it may cause thread explosion issue if not explicitly specified, 
    ///         so use at your own risk.
    ///
    /// - Parameters:
    ///   - identifier: the identifier to group works to debounce. Throttler must have equivalent identifier to each work in a group to debounce.
    ///   - queue: a queue to run a work on. dispatch global queue will be chosen by default if not specified.
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
