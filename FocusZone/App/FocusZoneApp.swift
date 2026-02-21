//
//  FocusZoneApp.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/12/25.
//  Local-first: SwiftData is local-only. Firebase sync will be added as optional background layer.
//

import SwiftUI
import SwiftData
import FirebaseCore

// Inbox uses a local-only container (separate from Task store).
private enum InboxModelContextKey: EnvironmentKey {
    static let defaultValue: ModelContext? = nil
}
extension EnvironmentValues {
    var inboxModelContext: ModelContext? {
        get { self[InboxModelContextKey.self] }
        set { self[InboxModelContextKey.self] = newValue }
    }
}

@main
struct FocusZoneApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var firebaseAuth = FirebaseAuthService.shared

    init() {
        FirebaseApp.configure()
    }

    /// Task container: local-only (Firebase sync will be added in a later phase).
    let modelContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration(cloudKitDatabase: .none)
            return try ModelContainer(for: Task.self, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    /// Inbox (QuickNote) container: separate from Task, local-only.
    let inboxModelContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration(cloudKitDatabase: .none)
            return try ModelContainer(for: QuickNote.self, configurations: configuration)
        } catch {
            fatalError("Failed to create Inbox ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(themeManager)
                .environmentObject(notificationService)
                .environmentObject(languageManager)
                .environmentObject(firebaseAuth)
                .environment(\.inboxModelContext, inboxModelContainer.mainContext)
                .task {
                    firebaseAuth.configure()
                    _ = languageManager.currentLanguage
                    await requestNotificationPermission()
                }
        }
        .modelContainer(modelContainer)
    }
    
    private func requestNotificationPermission() async {
            let granted = await notificationService.requestAuthorization()
            if granted {
                print("FocusZoneApp: Notification permission granted")
            } else {
                print("FocusZoneApp: Notification permission denied")
            }
        }
}
