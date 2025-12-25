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
        TabItem(title: NSLocalizedString("timeline", comment: "Timeline tab"), icon: "calendar"),
        TabItem(title: NSLocalizedString("insights", comment: "Insights tab"), icon: "brain.head.profile", badge: "PRO"),
        TabItem(title: NSLocalizedString("settings", comment: "Settings tab"), icon: "gear")
    ]
    
    var body: some View {
        ZStack {
            // Main content area
            Group {
                switch selectedTab {
                case 0:
                    LiquidTimelineView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                case 1:
                    FocusInsightsView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                case 2:
                    LiquidSettingsView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                default:
                    LiquidTimelineView()
                }
            }
            .animation(LiquidDesignSystem.Animation.smooth, value: selectedTab)
            
            // Bottom navigation container
            VStack {
                Spacer()
                
                ZStack(alignment: .bottom) {
                    // Floating Action Button (positioned above tab bar)
                    VStack {
                        Spacer()
                        
                        LiquidFloatingSeparatedActionButton(
                            icon: "plus",
                            size: 64
                        ) {
                            showAddTaskForm = true
                        }
                        .offset(y: -25) // Float above the tab bar
                    }
                    
                    // Custom Tab Bar
                    LiquidTabBar(
                        selectedTab: $selectedTab,
                        tabs: tabs
                    )
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .environmentObject(subscriptionManager)
        .sheet(isPresented: $showAddTaskForm, onDismiss: {
            // Refresh timeline after adding task
            NotificationCenter.default.post(name: NSNotification.Name("RefreshTimeline"), object: nil)
        }) {
            LiquidTaskFormView()
                .environment(\.modelContext, modelContext)
        }
    }
}

// MARK: - Preview

#Preview {
    LiquidMainTabView()
        .environmentObject(SubscriptionManager.shared)
}

