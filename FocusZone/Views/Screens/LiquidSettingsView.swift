import SwiftUI

/// Liquid-styled settings view
struct LiquidSettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LiquidDesignSystem.Gradients.meshBackground(colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: LiquidDesignSystem.Spacing.lg) {
                        // Header
                        VStack(spacing: LiquidDesignSystem.Spacing.sm) {
                            Text("Settings")
                                .font(LiquidDesignSystem.Typography.displayMedium)
                                .foregroundStyle(LiquidDesignSystem.Colors.textPrimary)
                            
                            Text("Customize your focus experience")
                                .font(LiquidDesignSystem.Typography.body)
                                .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                        }
                        .padding(.top, LiquidDesignSystem.Spacing.xl)
                        
                        // Settings sections
                        VStack(spacing: LiquidDesignSystem.Spacing.md) {
                            // General Section
                            settingsSection(
                                title: "General",
                                items: [
                                    SettingItem(icon: "bell.fill", title: "Notifications", subtitle: "Manage alerts"),
                                    SettingItem(icon: "moon.fill", title: "Focus Mode", subtitle: "Do Not Disturb"),
                                    SettingItem(icon: "globe", title: "Language", subtitle: languageManager.currentLanguage.rawValue.uppercased())
                                ]
                            )
                            
                            // Premium Section
                            if !subscriptionManager.isProUser {
                                premiumBanner
                            }
                            
                            // About Section
                            settingsSection(
                                title: "About",
                                items: [
                                    SettingItem(icon: "info.circle.fill", title: "Help & Support", subtitle: nil),
                                    SettingItem(icon: "star.fill", title: "Rate App", subtitle: nil),
                                    SettingItem(icon: "doc.text.fill", title: "Privacy Policy", subtitle: nil)
                                ]
                            )
                        }
                        .padding(.horizontal, LiquidDesignSystem.Spacing.lg)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Settings Section
    
    private func settingsSection(title: String, items: [SettingItem]) -> some View {
        VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.xs) {
            Text(title)
                .font(LiquidDesignSystem.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, LiquidDesignSystem.Spacing.sm)
                .padding(.bottom, LiquidDesignSystem.Spacing.xs)
            
            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    settingRow(item: items[index])
                    
                    if index < items.count - 1 {
                        Divider()
                            .overlay(LiquidDesignSystem.Colors.surface.opacity(0.2))
                            .padding(.leading, 56)
                    }
                }
            }
            .glassSurface()
        }
    }
    
    private func settingRow(item: SettingItem) -> some View {
        Button(action: {
            // Handle setting tap
        }) {
            HStack(spacing: LiquidDesignSystem.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LiquidDesignSystem.Colors.primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(LiquidDesignSystem.Colors.primary)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(LiquidDesignSystem.Typography.body)
                        .foregroundStyle(LiquidDesignSystem.Colors.textPrimary)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(LiquidDesignSystem.Typography.caption)
                            .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
            }
            .padding(LiquidDesignSystem.Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Premium Banner
    
    private var premiumBanner: some View {
        Button(action: {
            // Show paywall
        }) {
            HStack(spacing: LiquidDesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Upgrade to Pro")
                        .font(LiquidDesignSystem.Typography.headlineSmall)
                        .foregroundStyle(LiquidDesignSystem.Colors.textPrimary)
                    
                    Text("Unlock all features")
                        .font(LiquidDesignSystem.Typography.caption)
                        .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(LiquidDesignSystem.Colors.primary)
            }
            .padding(LiquidDesignSystem.Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
        .glassSurface()
    }
}

// MARK: - Setting Item Model

private struct SettingItem {
    let icon: String
    let title: String
    let subtitle: String?
}

// MARK: - Preview

#Preview {
    LiquidSettingsView()
        .environmentObject(LanguageManager.shared)
}

