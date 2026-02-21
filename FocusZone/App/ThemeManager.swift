import Foundation
import SwiftUI

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false 

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
