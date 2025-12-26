import SwiftUI
import SwiftData

/// Main tab view with liquid design - features a floating separated action button
/// and a pill-shaped glass bottom navigation bar
struct LiquidMainTabView: View {
    @State private var selectedTab = 0
    @State private var showAddTaskForm = false
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Tab configuration
    private let tabs: [TabItem] = [
        TabItem(title: NSLocalizedString("timeline", comment: "Timeline tab"), icon: "calendar", selectedIcon: "calendar.circle.fill"),
        TabItem(title: NSLocalizedString("insights", comment: "Insights tab"), icon: "brain.head.profile", selectedIcon: "brain.head.profile.fill", badge: "PRO"),
        TabItem(title: NSLocalizedString("settings", comment: "Settings tab"), icon: "gear", selectedIcon: "gearshape.fill")
    ]
    
    var body: some View {
        ZStack {
            // Main content area
            Group {
                switch selectedTab {
                case 0:
                    TimelineView()
                case 1:
                    FocusInsightsView()
                case 2:
                    SettingsView()
                default:
                    TimelineView()
                }
            }
            
            // Bottom navigation container
            VStack {
                Spacer()
                
                // Horizontal layout: Tab Bar + FAB aligned
                HStack(spacing: LiquidDesignSystem.Spacing.md) {
                    // Custom Tab Bar (takes most space)
                    LiquidTabBar(
                        selectedTab: $selectedTab,
                        tabs: tabs
                    )
                    
                    // Floating Action Button (aligned at same level)
                    LiquidFloatingSeparatedActionButton(
                        icon: "plus",
                        size: 56
                    ) {
                        showAddTaskForm = true
                    }
                    .padding(.trailing, LiquidDesignSystem.Spacing.lg)
                }
                .padding(.bottom, LiquidDesignSystem.Spacing.sm)
            }
            .ignoresSafeArea(.keyboard)
        }
        .environmentObject(subscriptionManager)
        .sheet(isPresented: $showAddTaskForm, onDismiss: {
            // Refresh timeline after adding task
            NotificationCenter.default.post(name: NSNotification.Name("RefreshTimeline"), object: nil)
        }) {
            TaskFormView()
                .environment(\.modelContext, modelContext)
        }
    }
}

// MARK: - Preview

#Preview {
    LiquidMainTabView()
        .environmentObject(SubscriptionManager.shared)
}

