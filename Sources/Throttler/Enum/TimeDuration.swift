//
//  TimeDuration.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-09-08.
//

import Foundation

public enum TimeDuration {
    case duration(Duration)
    case seconds(Double)
    
    var timeInterval: TimeInterval {
        switch self {
        case .duration(let duration):
            return duration.timeInterval
        case .seconds(let seconds):
            return seconds
        }
    }
    
    func wait() async {
        switch self {
        case .duration(let time):
            if #available(macOS 13.0, iOS 16.0, *) {
                try? await Task.sleep(for: time)
            }
        case .seconds(let seconds):
            try? await Task.sleep(seconds: seconds)
        }
    }
}

@available(macOS 13.0, *)
@available(iOS 16.0, *)
private extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + Double(components.attoseconds)/1e18
    }
}
