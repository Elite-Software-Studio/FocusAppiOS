//
//  FocusSession.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import Foundation
// MARK: - Supporting Models

struct FocusSession: Codable {
    let id: UUID
    let mode: FocusMode
    let startTime: Date
    var endTime: Date?
    let plannedDuration: TimeInterval
    var notificationsBlocked: Int = 0
    
    var duration: TimeInterval {
        guard let endTime = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isCompleted: Bool {
        return endTime != nil
    }
    
    var effectiveness: Double {
        guard plannedDuration > 0 else { return 0 }
        return min(1.0, duration / plannedDuration)
    }
}
