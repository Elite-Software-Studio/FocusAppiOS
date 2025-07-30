//
//  FocusConfigurationService.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import Foundation

class FocusConfigurationService {
    static let shared = FocusConfigurationService()
    
    private let userDefaults = UserDefaults.standard
    
    func getDefaultFocusSettings(for taskType: TaskType) -> FocusSettings {
        switch taskType {
        case .work:
            return FocusSettings(
                isEnabled: true,
                mode: .workMode,
                allowUrgentNotifications: true
            )
        case .study:
            return FocusSettings(
                isEnabled: true,
                mode: .deepWork,
                allowUrgentNotifications: false
            )
        case .exercise, .meal:
            return FocusSettings(
                isEnabled: true,
                mode: .lightFocus,
                allowUrgentNotifications: true
            )
        default:
            return FocusSettings.defaultSettings
        }
    }
    
    func saveUserFocusPreferences(_ settings: FocusSettings, for taskType: TaskType) {
        let key = "focus_preference_\(taskType.rawValue)"
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: key)
        }
    }
}
