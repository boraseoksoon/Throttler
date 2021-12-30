//
//  Throttler.swift
//  Throttler
//
//  Created by Seoksun Jang on 2021/02/20.
//

import Foundation
import Combine

/// struct either throttling or debouncing successive works
public struct Throttler {
    
    static private var workers: [String: Worker] = [:]
    static private var debounceImmediatelyPerformed = false
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
    ///     "your work : 0"
    ///     "your work : 100000"
    ///     "done!"
    ///
    /// - Note: Pay special attention to the identifier parameter. the default identifier is \("Thread.callStackSymbols") to make api trailing closure for one liner for the sake of brevity. However, it is highly recommend that a developer should provide explicit identifier for their work to debounce.
    ///
    /// - Parameters:
    ///   - identifier: the identifier to group works to debounce. Throttler must have equivalent identifier to each work in a group to debounce in a group.
    ///   - queue: queue to run the work on.
    ///   - delay: delay for debounce. time unit is second. given default is 1.0 sec.
    ///   - shouldStartImmediately: A boolean type where true will run the first work immediately regardless.
    ///   - work: the work to run
    /// - Returns: Void
    static public func debounce(identifier: String = "\(Thread.callStackSymbols)",
                                queue: DispatchQueue? = nil,
                                delay: DispatchQueue.SchedulerTimeType.Stride = .seconds(1),
                                shouldStartImmediately: Bool = true,
                                work: @escaping () -> Void) {
        var worker: Worker? = nil
        
        if let w = workers[identifier] {
            worker = w
        } else {
            let w = Worker(queue: queue, delay: delay)
            workers[identifier] = w
            worker = workers[identifier]
        }

        let canRunImmediately = shouldStartImmediately && !Self.debounceImmediatelyPerformed
        
        worker!.deploy(
            shouldStartImmediately:canRunImmediately,
            work: work
        )
        
        if canRunImmediately {
            Self.debounceImmediatelyPerformed = true
        }
    }

    typealias Work = () -> Void
    typealias Subject = PassthroughSubject<Work, Never>?
    typealias Bag = Set<AnyCancellable>
    static private var subjects: [String: (Subject, Bag)] = [:]
    static private var throttleImmediatelyPerformed = false
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
    ///   - queue: queue to run the work on.
    ///   - delay: delay for throttle. time unit is second. given default is 1.0 sec.
    ///   - shouldStartImmediately: A boolean type where true will run the first work immediately regardless.
    ///   - work: the work to run
    /// - Returns: Void
    static public func throttle(identifier: String = "\(Thread.callStackSymbols)",
                                queue: DispatchQueue? = nil,
                                delay: DispatchQueue.SchedulerTimeType.Stride = .seconds(1),
                                shouldStartImmediately: Bool = true,
                                shouldRunLatest: Bool = true,
                                work: @escaping () -> Void) {
        let canRunImmediately = shouldStartImmediately && !Self.throttleImmediatelyPerformed
        if canRunImmediately {
            work()
            Self.throttleImmediatelyPerformed = true
        }
        
        if let (_, _) = subjects[identifier] {
            subjects[identifier]?.0!.send(work)
        } else {
            subjects[identifier] = (PassthroughSubject<Work, Never>(), Bag())
            subjects[identifier]?.0!
                .throttle(for: delay, scheduler: queue ?? .global(), latest: shouldRunLatest)
                .sink(receiveValue: { $0() })
                .store(in: &subjects[identifier]!.1)
        }
    }

    private class Worker {
        
        private let queue: DispatchQueue?
        private let delay: DispatchQueue.SchedulerTimeType.Stride
        private var workItem: DispatchWorkItem?

        fileprivate init(queue: DispatchQueue? = nil, delay: DispatchQueue.SchedulerTimeType.Stride) {
            self.queue = queue
            self.delay = delay
        }

        fileprivate func deploy(shouldStartImmediately: Bool, work: @escaping () -> Void) {
            let canStartImmediately = shouldStartImmediately && workItem == nil
            
            if canStartImmediately {
                workItem = DispatchWorkItem(block: work)
                work()
            } else {
                debounce(work: work)
            }
        }

        private func debounce(work: @escaping () -> Void) {
            let q = queue == nil ? DispatchQueue.global() : queue

            workItem?.cancel()
            workItem = DispatchWorkItem(block: work)

            let deadline = DispatchTime.now() + delay.timeInterval
            
            q?.asyncAfter(
                deadline: deadline,
                execute: workItem!
            )
        }
    }
}
