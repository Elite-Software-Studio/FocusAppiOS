import Foundation

// MARK: - iOS Version Checks
struct FocusCapabilities {
    static let isSystemFocusAvailable = {
        if #available(iOS 15.0, *) {
            return true
        }
        return false
    }()
    
    static let isAppIntentsAvailable = {
        if #available(iOS 16.0, *) {
            return true
        }
        return false
    }()
}

// MARK: - Fallback Implementation
// For when Intents framework is not available or not needed
struct FocusModeFallback {
    static func activateCustomFocus(mode: FocusMode) -> Bool {
        print("🎯 Activating custom focus mode: \(mode.displayName)")
        UserDefaults.standard.set(true, forKey: "custom_focus_active")
        UserDefaults.standard.set(mode.rawValue, forKey: "custom_focus_mode")
        return true
    }
    
    static func deactivateCustomFocus() -> Bool {
        print("🎯 Deactivating custom focus mode")
        UserDefaults.standard.removeObject(forKey: "custom_focus_active")
        UserDefaults.standard.removeObject(forKey: "custom_focus_mode")
        return true
    }
    
    static func isCustomFocusActive() -> Bool {
        return UserDefaults.standard.bool(forKey: "custom_focus_active")
    }
    
    static func getCurrentCustomFocusMode() -> FocusMode? {
        guard let modeString = UserDefaults.standard.string(forKey: "custom_focus_mode"),
              let mode = FocusMode(rawValue: modeString) else {
            return nil
        }
        return mode
    }
}
