import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @State private var notificationsEnabled = true
    @State private var showingAbout = false
    @State private var showingContact = false
    @State private var enableFocusMode = true
    @State private var showPaywall = false
    
    @State private var showingClearDataConfirmation = false
    @State private var showingClearDataAlert = false
    @State private var clearDataMessage = ""
    @State private var showingDeleteTaskAlert = false
    @StateObject private var focusManager = FocusModeManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @StateObject private var languageManager = LanguageManager.shared
    @EnvironmentObject private var firebaseAuth: FirebaseAuthService
    @EnvironmentObject private var firebaseSync: FirebaseSyncService
    @State private var showingLanguageSelection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Header
                    appHeader
                    
                    // Settings Sections
                    VStack(spacing: 20) {
                        subscriptionSection
                        accountSection
                        appearanceSection
                        notificationSection
                        dataSection
                        focusSection
                        aboutSection
                        syncSection
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
        .sheet(isPresented: $showingContact) {
            ContactSheet()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingLanguageSelection) {
            LanguageSelectionSheet(languageManager: languageManager)
        }
        
        .confirmationDialog(
            LanguageManager.localized("clear_all_data_confirmation", comment: "Clear all data confirmation dialog title"),
            isPresented: $showingClearDataConfirmation,
            titleVisibility: .visible
        ) {
            Button(LanguageManager.localized("clear_all_data", comment: "Clear all data button title"), role: .destructive) {
                clearAllData()
            }
            Button(LanguageManager.localized("cancel", comment: "Cancel button title"), role: .cancel) { }
        } message: {
            Text(LanguageManager.localized("clear_all_data_warning", comment: "Clear all data warning message"))
        }
        .alert(LanguageManager.localized("data_cleared", comment: "Data cleared alert title"), isPresented: $showingClearDataAlert) {
            Button(LanguageManager.localized("ok", comment: "OK button title")) { }
        } message: {
            Text(clearDataMessage)
        }
        .alert("🧪 Delete All Tasks for Testing", isPresented: $showingDeleteTaskAlert) {
            Button("Delete All Tasks", role: .destructive) {
                deleteTaskForTesting()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete ALL tasks from local data. This action cannot be undone and is for testing purposes only.")
        }
        
    }
    
    // MARK: - App Header
    private var appHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                
                Text(LanguageManager.localized("settings", comment: "Settings screen title"))
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
                    Text("FocusZen+")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text(LanguageManager.localized("stay_focused_achieve_more", comment: "App tagline"))
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
    
    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        VStack(spacing: 16) {
            // Subscription status card
            SubscriptionStatusView()
            
            if !subscriptionManager.isProUser {
                // Upgrade prompt for free users
                Button(action: {
                    showPaywall = true
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.red]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LanguageManager.localized("upgrade_to_pro", comment: "Upgrade to Pro button title"))
                                .font(AppFonts.headline())
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(LanguageManager.localized("unlock_all_features_boost_productivity", comment: "Upgrade to Pro description"))
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.accent)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.orange.opacity(0.1),
                                    Color.red.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.orange.opacity(0.3),
                                            Color.red.opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ), lineWidth: 1)
                            )
                    )
                }
            } else {
                // Pro user management options
                SettingsSection(title: LanguageManager.localized("subscription", comment: "Subscription section title"), icon: "crown.fill") {
                    VStack(spacing: 0) {
                        Button(action: {
                            _Concurrency.Task {
                                await subscriptionManager.restorePurchases()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(AppColors.accent)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LanguageManager.localized("restore_purchases", comment: "Restore purchases button title"))
                                        .font(AppFonts.body())
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(LanguageManager.localized("restore_subscription_another_device", comment: "Restore purchases description"))
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        
                        Divider()
                            .padding(.leading, 52)
                        
                        Button(action: {
                            // TODO: Open subscription management in App Store
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "gear.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(AppColors.accent)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LanguageManager.localized("manage_subscription", comment: "Manage subscription button title"))
                                        .font(AppFonts.body())
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(LanguageManager.localized("change_cancel_your_subscription", comment: "Manage subscription description"))
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        SettingsSection(title: LanguageManager.localized("appearance", comment: "Appearance section title"), icon: "paintbrush") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: LanguageManager.localized("dark_mode", comment: "Dark mode toggle title"),
                    subtitle: LanguageManager.localized("switch_light_dark_themes", comment: "Dark mode toggle description"),
                    icon: "moon.circle.fill",
                    isOn: $theme.isDarkMode
                )
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsNavigationRow(
                    title: LanguageManager.localized("language", comment: "Language selection button title"),
                    subtitle: "\(languageManager.getCurrentLanguageFlag()) \(languageManager.getCurrentLanguageDisplayName())",
                    icon: "globe",
                    action: { showingLanguageSelection = true }
                )
            }
        }
    }
    
    
    
    // Focus  Section
    private var focusSection: some View {
        SettingsSection(title: LanguageManager.localized("focus", comment: "Focus section title"), icon: "target") {
            VStack(spacing: 0) {
                
                SettingsToggleRow(
                    title: LanguageManager.localized("focus_concentration", comment: "Focus concentration toggle title"),
                    subtitle: LanguageManager.localized("get_notified_tasks_starting", comment: "Focus concentration toggle description"),
                    icon: "bell.circle.fill",
                    isOn: $enableFocusMode
                )
                
            }
            
        }
    }
    
    // MARK: - Notifications Section
    private var notificationSection: some View {
        SettingsSection(title: LanguageManager.localized("notifications", comment: "Notifications section title"), icon: "bell") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: LanguageManager.localized("task_reminders", comment: "Task reminders toggle title"),
                    subtitle: LanguageManager.localized("get_notified_tasks_starting", comment: "Task reminders toggle description"),
                    icon: "bell.circle.fill",
                    isOn: $notificationsEnabled
                )
            }
        }
    }
    
    // MARK: - Data Section
    private var dataSection: some View {
        SettingsSection(title: LanguageManager.localized("data", comment: "Data section title"), icon: "internaldrive") {
            VStack(spacing: 0) {
                
                
                SettingsNavigationRow(
                    title: LanguageManager.localized("clear_all_data", comment: "Clear all data button title"),
                    subtitle: LanguageManager.localized("reset_all_tasks_settings", comment: "Clear all data description"),
                    icon: "trash.circle.fill",
                    isDestructive: true,
                    action: { showingClearDataConfirmation = true }
                )
                
                Divider()
                    .padding(.leading, 52)
                
                // Debug Delete All Button (only in debug mode)
            #if DEBUG
                SettingsNavigationRow(
                    title: "🧪 Delete All Tasks for Testing",
                    subtitle: "Delete all tasks from local data for testing purposes",
                    icon: "trash.circle.fill",
                    isDestructive: true,
                    action: { showingDeleteTaskAlert = true }
                )
            #endif
            }
        }
    }
    
    // MARK: - Account Section (Sign in with Apple)
    private var accountSection: some View {
        SettingsSection(title: LanguageManager.localized("account", comment: "Account section title"), icon: "person.crop.circle") {
            AccountSectionView(authService: firebaseAuth)
        }
    }

    // MARK: - Sync Section (Firebase)
    private var syncSection: some View {
        SettingsSection(title: LanguageManager.localized("sync", comment: "Sync section title"), icon: "arrow.triangle.2.circlepath") {
            FirebaseSyncStatusView(syncService: firebaseSync)
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        SettingsSection(title: LanguageManager.localized("about", comment: "About section title"), icon: "info.circle") {
            VStack(spacing: 0) {
                SettingsNavigationRow(
                    title: LanguageManager.localized("about_us", comment: "About us button title"),
                    subtitle: LanguageManager.localized("version_1_0", comment: "App version"),
                    icon: "app.badge.checkmark",
                    action: { showingAbout = true }
                )
                
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsNavigationRow(
                    title: LanguageManager.localized("contact_support", comment: "Contact support button title"),
                    subtitle: LanguageManager.localized("get_help_send_feedback", comment: "Contact support description"),
                    icon: "envelope.circle.fill",
                    action: { showingContact = true }
                )
            }
        }
    }
    
    private func clearAllData() {
        _Concurrency.Task {
            do {
                // Clear SwiftData - Delete all tasks
                let taskDescriptor = FetchDescriptor<Task>()
                let allTasks = try modelContext.fetch(taskDescriptor)
                
                for task in allTasks {
                    modelContext.delete(task)
                }
                
                // Save the context to persist deletions
                try modelContext.save()
                
                // Clear UserDefaults data
                let defaults = UserDefaults.standard
                let domain = Bundle.main.bundleIdentifier!
                defaults.removePersistentDomain(forName: domain)
                
                // Clear specific UserDefaults keys that might not be in the domain
                let keysToRemove = [
                    "active_focus_session",
                    "focus_session_history",
                    "focus_mode_preferences",
                    "notification_preferences",
                    "theme_preferences",
                    "last_analytics_date",
                    "user_preferences"
                ]
                
                for key in keysToRemove {
                    defaults.removeObject(forKey: key)
                }
                
                // Clear all pending notifications
                await UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                await UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                
                // Clear analytics data
                focusManager.clearFocusSessionHistory()
                
                // Reset local state variables
                await MainActor.run {
                    notificationsEnabled = true
                    enableFocusMode = true
                    theme.resetToDefaults()
                    
                    clearDataMessage = LanguageManager.localized("all_data_successfully_cleared", comment: "Success message when data is cleared")
                    showingClearDataAlert = true
                }
                
                // Restart the app after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    exit(0)
                }
                
            } catch {
                await MainActor.run {
                    clearDataMessage = String(format: LanguageManager.localized("error_clearing_data", comment: "Error message when clearing data fails"), error.localizedDescription)
                    showingClearDataAlert = true
                }
            }
        }
    }
    
    private func deleteTaskForTesting() {
        _Concurrency.Task {
            do {
                // Fetch all tasks
                let taskDescriptor = FetchDescriptor<Task>()
                let allTasks = try modelContext.fetch(taskDescriptor)
                
                let taskCount = allTasks.count
                print("🧪 Testing: Found \(taskCount) tasks to delete")
                
                if taskCount > 0 {
                    // Delete all tasks from local SwiftData
                    for task in allTasks {
                        modelContext.delete(task)
                    }
                    try modelContext.save()
                    
                    await MainActor.run {
                        clearDataMessage = "✅ Successfully deleted \(taskCount) tasks from local data"
                        showingClearDataAlert = true
                    }
                    
                    print("🧪 Testing: All \(taskCount) tasks deleted successfully")
                    
                } else {
                    await MainActor.run {
                        clearDataMessage = "ℹ️ No tasks found to delete"
                        showingClearDataAlert = true
                    }
                }
                
            } catch {
                await MainActor.run {
                    clearDataMessage = "❌ Error deleting tasks: \(error.localizedDescription)"
                    showingClearDataAlert = true
                }
            }
        }
    }
    
    private func contactSupport() {
        // TODO: Implement contact support functionality
        print("Contact support requested")
    }
}

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
                    // App Header
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.accent)
                        
                        Text("Focus")
                            .font(AppFonts.title())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.secondary)
                    }
                    
                    // About Us Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LanguageManager.localized("about_focuszen_plus", comment: "About FocusZen+ title"))
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        Text(LanguageManager.localized("focuszen_plus_description", comment: "About FocusZen+ description"))
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Mission Statement
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LanguageManager.localized("our_mission", comment: "Our mission title"))
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        Text(LanguageManager.localized("our_mission_description", comment: "Our mission description"))
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Key Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LanguageManager.localized("key_features", comment: "Key features title"))
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            _FeatureRow(icon: "target", title: LanguageManager.localized("focus_sessions", comment: "Focus sessions feature"), description: LanguageManager.localized("focus_sessions_description", comment: "Focus sessions description"))
                            _FeatureRow(icon: "brain.head.profile", title: LanguageManager.localized("ai_powered_insights", comment: "AI-powered insights feature"), description: LanguageManager.localized("ai_powered_insights_description", comment: "AI-powered insights description"))
                            _FeatureRow(icon: "bell.badge", title: LanguageManager.localized("smart_notifications", comment: "Smart notifications feature"), description: LanguageManager.localized("smart_notifications_description", comment: "Smart notifications description"))
                            _FeatureRow(icon: "chart.line.uptrend.xyaxis", title: LanguageManager.localized("progress_tracking", comment: "Progress tracking feature"), description: LanguageManager.localized("progress_tracking_description", comment: "Progress tracking description"))
                            _FeatureRow(icon: "gear", title: LanguageManager.localized("customizable_focus_modes", comment: "Customizable focus modes feature"), description: LanguageManager.localized("customizable_focus_modes_description", comment: "Customizable focus modes description"))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Technology Stack
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LanguageManager.localized("built_with", comment: "Built with title"))
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LanguageManager.localized("swiftui_ios_15", comment: "SwiftUI iOS 15+"))
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                            Text(LanguageManager.localized("core_data_persistence", comment: "Core Data persistence"))
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                            Text(LanguageManager.localized("widgetkit_home_screen", comment: "WidgetKit home screen"))
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                            Text(LanguageManager.localized("localization_global_users", comment: "Localization for global users"))
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Contact & Support
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LanguageManager.localized("get_in_touch", comment: "Get in touch title"))
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                if let url = URL(string: "mailto:support@focuszenplus.app") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(AppColors.accent)
                                    Text("support@focuszenplus.app")
                                        .foregroundColor(AppColors.accent)
                                    Spacer()
                                }
                            }
                            
                            Button(action: {
                                if let url = URL(string: "https://focuszenplus.app") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "globe")
                                        .foregroundColor(AppColors.accent)
                                    Text("focuszenplus.app")
                                        .foregroundColor(AppColors.accent)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Copyright
                    VStack(spacing: 8) {
                        Text(LanguageManager.localized("copyright_2024", comment: "Copyright text"))
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(LanguageManager.localized("made_with_love_productivity", comment: "Made with love for productivity"))
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 16)
                }
                .padding()
            }
            .navigationTitle(LanguageManager.localized("about", comment: "About navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageManager.localized("done", comment: "Done button title")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct _FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.accent)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct ContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Contact Header
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.accent)
                        
                        Text(LanguageManager.localized("contact_support", comment: "Contact & Support title"))
                            .font(AppFonts.title())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.bold)
                        
                        Text(LanguageManager.localized("contact_support_description", comment: "Contact & Support description"))
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, 20)
                    
                    // Support Options
                    VStack(spacing: 16) {
                        Text(LanguageManager.localized("support_options", comment: "Support options title"))
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ContactOptionRow(
                                icon: "envelope.fill",
                                title: LanguageManager.localized("email_support", comment: "Email support option"),
                                subtitle: LanguageManager.localized("get_help_via_email", comment: "Email support description"),
                                action: {
                                    if let url = URL(string: "mailto:support@focuszenplus.app") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            
                            ContactOptionRow(
                                icon: "globe",
                                title: LanguageManager.localized("website", comment: "Website option"),
                                subtitle: LanguageManager.localized("visit_website_help", comment: "Website help description"),
                                action: {
                                    if let url = URL(string: "https://focuszenplus.app") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            
                            ContactOptionRow(
                                icon: "questionmark.circle.fill",
                                title: LanguageManager.localized("faq_help_center", comment: "FAQ & Help Center option"),
                                subtitle: LanguageManager.localized("find_answers_common_questions", comment: "FAQ help description"),
                                action: {
                                    if let url = URL(string: "https://focuszenplus.app/help") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Feedback Section
                    VStack(spacing: 16) {
                        Text(LanguageManager.localized("send_feedback", comment: "Send feedback title"))
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ContactOptionRow(
                                icon: "star.fill",
                                title: LanguageManager.localized("rate_app", comment: "Rate the app option"),
                                subtitle: LanguageManager.localized("share_experience_app_store", comment: "Rate app description"),
                                action: {
                                    rateApp()
                                }
                            )
                            
                            ContactOptionRow(
                                icon: "paperplane.fill",
                                title: LanguageManager.localized("feature_request", comment: "Feature request option"),
                                subtitle: LanguageManager.localized("suggest_new_features_improvements", comment: "Feature request description"),
                                action: {
                                    if let url = URL(string: "mailto:feedback@focuszenplus.app?subject=Feature%20Request") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            
                            ContactOptionRow(
                                icon: "exclamationmark.triangle.fill",
                                title: LanguageManager.localized("report_bug", comment: "Report bug option"),
                                subtitle: LanguageManager.localized("help_us_fix_issues", comment: "Report bug description"),
                                action: {
                                    if let url = URL(string: "mailto:bugs@focuszenplus.app?subject=Bug%20Report") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Response Time
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.accent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(LanguageManager.localized("response_time", comment: "Response time title"))
                                    .font(AppFonts.body())
                                    .foregroundColor(AppColors.textPrimary)
                                    .fontWeight(.medium)
                                
                                Text(LanguageManager.localized("response_time_description", comment: "Response time description"))
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.card)
                        )
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(LanguageManager.localized("contact_support", comment: "Contact & Support navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageManager.localized("done", comment: "Done button title")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func rateApp() {
        // Get the app's bundle identifier
        let bundleId = Bundle.main.bundleIdentifier ?? "ios.focus.jf.com.Focus"
        
        // Create the App Store URL for rating
        let appStoreURL = "https://apps.apple.com/app/id[APP_ID]?action=write-review"
        
        // Alternative: Use the app's name to search (more reliable)
        let searchURL = "https://apps.apple.com/search?term=FocusZen%2B&media=software"
        
        // Try to open the App Store rating page
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback to search page if rating page fails
                    if let searchURL = URL(string: searchURL) {
                        UIApplication.shared.open(searchURL)
                    }
                }
            }
        } else {
            // Fallback to search page
            if let searchURL = URL(string: searchURL) {
                UIApplication.shared.open(searchURL)
            }
        }
    }
}

struct ContactOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.background)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
        .environmentObject(FirebaseAuthService.shared)
        .environmentObject(FirebaseSyncService.shared)
}

// MARK: - Language Selection Sheet
struct LanguageSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var languageManager: LanguageManager
    @State private var selectedLanguage: String
    
    init(languageManager: LanguageManager) {
        self.languageManager = languageManager
        self._selectedLanguage = State(initialValue: languageManager.currentLanguage)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languageManager.supportedLanguages, id: \.0) { language in
                    Button(action: {
                        selectedLanguage = language.0
                    }) {
                        HStack(spacing: 16) {
                            Text(language.2)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(language.1)
                                    .font(AppFonts.body())
                                    .foregroundColor(AppColors.textPrimary)
                                    .fontWeight(.medium)
                                
                                if language.0 == "en" {
                                    Text(LanguageManager.localized("system_default", comment: "System default language description"))
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedLanguage == language.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.accent)
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle(LanguageManager.localized("language", comment: "Language selection navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LanguageManager.localized("cancel", comment: "Cancel button title")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageManager.localized("done", comment: "Done button title")) {
                        if selectedLanguage != languageManager.currentLanguage {
                            languageManager.currentLanguage = selectedLanguage
                        }
                        dismiss()
                    }
                    .disabled(selectedLanguage == languageManager.currentLanguage)
                }
            }
        }
    }
}
