//
//  Throttler.swift
//  Throttler
//
//  Created by Seoksun Jang on 2021/02/20.
//

import Foundation

public struct Throttler {
    static private var workers: [String: Worker] = [:]
    
    static public func go(identifier: String = "\(Thread.callStackSymbols)",
                   delay: TimeInterval = 1.0,
                   action: @escaping () -> Void) {
        var worker: Worker? = nil
        
        if let w = workers[identifier] {
            worker = w
        } else {
            workers[identifier] = Worker(delay: delay)
            worker = workers[identifier]
        }
        
        worker!.go(action)
    }
    
    private class Worker {
        private let delay: TimeInterval
        private var workItem: DispatchWorkItem?

        public init(delay: TimeInterval) {
            self.delay = delay
        }

        public func go(_ action: @escaping () -> Void) {
            workItem?.cancel()
            workItem = DispatchWorkItem(block: action)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay,
                                          execute: workItem!)
        }
    }
}
