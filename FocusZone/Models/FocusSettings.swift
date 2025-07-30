//
//  FocusSettings.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import Foundation
import SwiftUI

struct FocusSettings: Codable, Equatable {
    let isEnabled: Bool
    let mode: FocusMode
    let allowUrgentNotifications: Bool
    let customAllowedApps: [String] // Bundle identifiers
    let autoActivate: Bool
    let scheduledActivation: Date?
    
    init(
        isEnabled: Bool = false,
        mode: FocusMode = .lightFocus,
        allowUrgentNotifications: Bool = true,
        customAllowedApps: [String] = [],
        autoActivate: Bool = true,
        scheduledActivation: Date? = nil
    ) {
        self.isEnabled = isEnabled
        self.mode = mode
        self.allowUrgentNotifications = allowUrgentNotifications
        self.customAllowedApps = customAllowedApps
        self.autoActivate = autoActivate
        self.scheduledActivation = scheduledActivation
    }
    
    static let defaultSettings = FocusSettings()
}

// Supporting models
enum FocusMode: String, CaseIterable , Codable {
    case deepWork = "deep_work"
    case lightFocus = "light_focus"
    case workMode = "work"
    case doNotDisturb = "dnd"
    
    var displayName: String {
        switch self {
        case .deepWork: return "Deep Work"
        case .lightFocus: return "Light Focus"
        case .workMode: return "Work"
        case .doNotDisturb: return "Do Not Disturb"
        }
    }
    
    var systemFocusIdentifier: String? {
        switch self {
        case .workMode: return "com.apple.focus.work"
        case .doNotDisturb: return "com.apple.donotdisturb"
        default: return nil // Custom modes
        }
    }
}

extension FocusMode {
    var iconName: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .lightFocus: return "moon.circle"
        case .workMode: return "laptopcomputer"
        case .doNotDisturb: return "moon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .deepWork: return .purple
        case .lightFocus: return .blue
        case .workMode: return .green
        case .doNotDisturb: return .indigo
        }
    }
    
    var description: String {
        switch self {
        case .deepWork: return "Maximum focus - blocks all non-essential notifications"
        case .lightFocus: return "Gentle focus - allows important notifications"
        case .workMode: return "Work focus - uses your iOS Work focus mode"
        case .doNotDisturb: return "Complete silence - blocks all notifications"
        }
    }
}
