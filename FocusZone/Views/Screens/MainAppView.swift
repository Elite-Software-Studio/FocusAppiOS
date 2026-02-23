import SwiftUI

struct MainAppView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showOnboarding = false
    @State private var showMainApp = false
    
    var body: some View {
        let _ = languageManager.currentLanguage // Refresh entire UI when language changes (no restart needed)
        return Group {
            if showMainApp {
                // Show main app after splash screen
                if hasSeenOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            } else {
                // Always show splash screen first
                SplashScreen()
                    .onAppear {
                        // After splash screen, decide what to show next
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                showMainApp = true
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    MainAppView()
        .environmentObject(LanguageManager.shared)
}
