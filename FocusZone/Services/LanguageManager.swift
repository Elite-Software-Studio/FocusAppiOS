import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String {
        didSet {
            setLanguagePreference()
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    /// Bundle for the given language code (e.g. "en", "pt-PT"). Use for runtime localization without app restart.
    func bundle(for languageCode: String) -> Bundle {
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
    
    /// Current bundle for the selected app language. Use for localized strings at runtime.
    var currentBundle: Bundle {
        bundle(for: currentLanguage)
    }
    
    /// Returns localized string for key using the currently selected language (no app restart needed).
    static func localized(_ key: String, comment: String = "") -> String {
        NSLocalizedString(key, bundle: shared.currentBundle, comment: comment)
    }
    
    let supportedLanguages = [
        ("en", "English", "🇺🇸"),
        ("fr", "Français", "🇫🇷"),
        ("pt-PT", "Português", "🇵🇹"),
        ("it", "Italiano", "🇮🇹"),
        ("ja", "日本語", "🇯🇵")
    ]
    
    private init() {
        // Get saved language or use system language
        if let savedLanguage = UserDefaults.standard.string(forKey: "selected_language") {
            self.currentLanguage = savedLanguage
        } else {
            // Use system language if supported, otherwise default to English
            let systemLanguage = Locale.current.languageCode ?? "en"
            let supportedCodes = supportedLanguages.map { $0.0 }
            self.currentLanguage = supportedCodes.contains(systemLanguage) ? systemLanguage : "en"
        }
        
        // Immediately set the language preference to ensure proper localization
        setLanguagePreference()
    }
    
    private func setLanguagePreference() {
        UserDefaults.standard.set(currentLanguage, forKey: "selected_language")
        UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    func getLanguageDisplayName(for code: String) -> String {
        return supportedLanguages.first { $0.0 == code }?.1 ?? code
    }
    
    func getLanguageFlag(for code: String) -> String {
        return supportedLanguages.first { $0.0 == code }?.2 ?? "🌐"
    }
    
    func getCurrentLanguageDisplayName() -> String {
        return getLanguageDisplayName(for: currentLanguage)
    }
    
    func getCurrentLanguageFlag() -> String {
        return getLanguageFlag(for: currentLanguage)
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
