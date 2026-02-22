import Foundation
import SwiftUI

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    private static let darkModeKey = "app_dark_mode_enabled"
    
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: Self.darkModeKey)
        }
    }

    init() {
        self.isDarkMode = UserDefaults.standard.object(forKey: Self.darkModeKey) as? Bool ?? false
    }

    var currentBackground: Color {
        isDarkMode ? Color.black : Color.white
    }

    var currentTextColor: Color {
        isDarkMode ? AppColors.textPrimary : .black
    }

    func toggleTheme() {
        isDarkMode.toggle()
    }
    
    func resetToDefaults() {
        isDarkMode = false
        print("🎨 Theme reset to defaults")
    }
}
