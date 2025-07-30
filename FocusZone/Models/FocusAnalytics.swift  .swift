//
//  FocusAnalytics.swift  .swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import Foundation
import SwiftUI


struct FocusAnalytics: Codable {
    let sessionId: UUID
    let startTime: Date
    let endTime: Date?
    let mode: FocusMode
    let notificationsBlocked: Int
    let focusBreaks: Int
    let taskCompleted: Bool
    let effectiveness: Double // 0-1 score
    
    enum FocusMode: String, Codable {
        case lightFocus
        case mediumFocus
        case strictFocus
    }
    
    var duration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }
}
