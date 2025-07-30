import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeManager
    @State private var notificationsEnabled = true
    @State private var autoSaveEnabled = true
    @State private var showingAbout = false
    @State private var enableFocusMode = true
    @StateObject private var focusManager = FocusModeManager()
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Header
                    appHeader
                    
                    // Settings Sections
                    VStack(spacing: 20) {
                        appearanceSection
                        notificationSection
                        dataSection
                        focusSection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
                }
                .padding(.top, 20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .onChange(of: theme.currentBackground) { newValue in
            // TODO Store preference
        }
        .sheet(isPresented: $showingAbout) {
            AboutSheet()
        }
    }
    
    // MARK: - App Header
    private var appHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                
                Text("Settings")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // App Icon and Info
            VStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(AppColors.accent.opacity(0.1))
                    )
                
                VStack(spacing: 4) {
                    Text("FocusZone")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text("Stay focused, achieve more")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondary)
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.card)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Dark Mode",
                    subtitle: "Switch between light and dark themes",
                    icon: "moon.circle.fill",
                    isOn: $theme.isDarkMode
                )
            }
        }
    }
    // Focus  Section
    private var focusSection: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush") {
            VStack(spacing: 0) {
                
                SettingsToggleRow(
                    title: "Focus & Concentration",
                    subtitle: "Get notified when tasks are starting",
                    icon: "bell.circle.fill",
                    isOn: $enableFocusMode
                )
                
            }
            
        }
    }
    
    // MARK: - Notifications Section
    private var notificationSection: some View {
        SettingsSection(title: "Notifications", icon: "bell") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Task Reminders",
                    subtitle: "Get notified when tasks are starting",
                    icon: "bell.circle.fill",
                    isOn: $notificationsEnabled
                )
            }
        }
        
        
    }
    
    // MARK: - Data Section
    private var dataSection: some View {
        SettingsSection(title: "Data", icon: "internaldrive") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Auto-Save Tasks",
                    subtitle: "Automatically save your task changes",
                    icon: "square.and.arrow.down.circle.fill",
                    isOn: $autoSaveEnabled
                )
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsNavigationRow(
                    title: "Clear All Data",
                    subtitle: "Reset all tasks and settings",
                    icon: "trash.circle.fill",
                    isDestructive: true,
                    action: { clearAllData() }
                )
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle") {
            VStack(spacing: 0) {
                SettingsNavigationRow(
                    title: "Version",
                    subtitle: "1.0.0",
                    icon: "app.badge.checkmark",
                    action: { showingAbout = true }
                )
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsNavigationRow(
                    title: "Contact Support",
                    subtitle: "Get help or send feedback",
                    icon: "envelope.circle.fill",
                    action: { contactSupport() }
                )
            }
        }
    }
    
    // MARK: - Actions
    private func clearAllData() {
        // TODO: Implement clear data functionality
        print("Clear all data requested")
    }
    
    private func contactSupport() {
        // TODO: Implement contact support functionality
        print("Contact support requested")
    }
}

// MARK: - Supporting Views
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                //                Image(systemName: icon)
                //                    .font(.system(size: 18))
                //                    .foregroundColor(AppColors.accent)
                
                //                Text(title)
                //                    .font(AppFonts.headline())
                //                    .foregroundColor(AppColors.textPrimary)
                //                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.card)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let subtitle: String
    let icon: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isDestructive ? .red : AppColors.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.body())
                        .foregroundColor(isDestructive ? .red : AppColors.textPrimary)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .onChange(of: isDestructive) { newValue in
          
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.accent)
                        
                        Text("FocusZone")
                            .font(AppFonts.title())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Built with SwiftUI")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("FocusZone helps you stay focused and achieve more by organizing your tasks and managing your time effectively. Built with modern SwiftUI and SwiftData for a smooth, native experience.")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                }
                .padding()
            }
            .navigationTitle("About FocusZone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
