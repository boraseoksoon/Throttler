//
//  ActorType.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

import Foundation

public enum ActorType {
    case current
    case main
    
    @Sendable func run(_ operation: () -> Void) async {
        self == .main ? await MainActor.run { operation() } : operation()
    }
}
