import SwiftUI

/// Liquid-styled custom tab bar with pill shape and glass surface
struct LiquidTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    
    let tabs: [TabItem]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                TabBarButton(
                    tab: tabs[index],
                    isSelected: selectedTab == index,
                    action: {
                        withAnimation(LiquidDesignSystem.Animation.smooth) {
                            selectedTab = index
                        }
                    }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, LiquidDesignSystem.Spacing.md)
        .padding(.vertical, LiquidDesignSystem.Spacing.sm)
        .background(
            ZStack {
                // True glass material with real blur
                Capsule()
                    .fill(.ultraThinMaterial)
                
                // Subtle tint overlay
                Capsule()
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.05)
                            : Color.white.opacity(0.3)
                    )
                
                // Light reflection highlight
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .overlay(
            // Glassy border
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.3 : 0.5),
                            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.15),
            radius: 25,
            x: 0,
            y: 12
        )
        .shadow(
            color: LiquidDesignSystem.Colors.primary.opacity(0.1),
            radius: 15,
            x: 0,
            y: 5
        )
        .padding(.leading, LiquidDesignSystem.Spacing.lg)
    }
}

// MARK: - Tab Bar Button

private struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(
                        isSelected
                            ? LiquidDesignSystem.Colors.primary
                            : LiquidDesignSystem.Colors.textSecondary
                    )
                    .frame(height: 24)
                
                Text(tab.title)
                    .font(LiquidDesignSystem.Typography.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(
                        isSelected
                            ? LiquidDesignSystem.Colors.primary
                            : LiquidDesignSystem.Colors.textSecondary
                    )
            }
            .padding(.vertical, 6)
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(LiquidDesignSystem.Animation.quick, value: isPressed)
            .animation(LiquidDesignSystem.Animation.smooth, value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tab Item Model

struct TabItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let selectedIcon: String
    let badge: String?
    
    init(title: String, icon: String, selectedIcon: String? = nil, badge: String? = nil) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? "\(icon).fill"
        self.badge = badge
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        
        LiquidTabBar(
            selectedTab: .constant(0),
            tabs: [
                TabItem(title: "Timeline", icon: "calendar"),
                TabItem(title: "Insights", icon: "chart.bar", badge: "PRO"),
                TabItem(title: "Settings", icon: "gear")
            ]
        )
    }
    .background(LiquidDesignSystem.Gradients.meshBackground(.light))
}


