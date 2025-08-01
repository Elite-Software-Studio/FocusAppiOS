import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }
                .tag(0)

            FocusInsightsView()
                .tabItem {
                    Label("Insights", systemImage: selectedTab == 1 ? "brain.head.profile.fill" : "brain.head.profile")
                }
                .tag(1)
                .overlay(
                    // Pro badge overlay
                    proTabBadge,
                    alignment: .topTrailing
                )

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .environmentObject(subscriptionManager)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    @ViewBuilder
    private var proTabBadge: some View {
        if !subscriptionManager.isSubscribed && selectedTab != 1 {
            Text("PRO")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .offset(x: -10, y: 10)
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Selected item
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemPurple
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemPurple
        ]
        
        // Normal item
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}


#Preview {
    MainTabView()
        .modelContainer(for: [Task.self])
}
