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
            Capsule()
                .fill(LiquidDesignSystem.Colors.glassBackground)
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    LiquidDesignSystem.Colors.surface.opacity(0.2),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.1),
            radius: 20,
            x: 0,
            y: 10
        )
        .padding(.horizontal, LiquidDesignSystem.Spacing.xl)
        .padding(.bottom, LiquidDesignSystem.Spacing.sm)
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

