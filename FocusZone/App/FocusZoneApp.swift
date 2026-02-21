//
//  FocusZoneApp.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/12/25.
//

import SwiftUI
import SwiftData
import CloudKit

// Inbox uses a local-only container (no CloudKit) to avoid schema/load issues.
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
    @StateObject private var cloudSyncManager = CloudSyncManager()
    @StateObject private var languageManager = LanguageManager.shared

    /// Task container: unchanged from original app. Task-only, CloudKit-backed.
    /// Do not add other models here; use a separate container (e.g. inbox) to avoid load/schema issues.
    let modelContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration(cloudKitDatabase: .automatic)
            return try ModelContainer(for: Task.self, configurations: configuration)
        } catch {
            fatalError("Failed to create CloudKit-backed ModelContainer: \(error)")
        }
    }()

    /// Inbox (QuickNote) container: separate from Task, local-only. Does not share store or schema with Task.
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
                .environmentObject(cloudSyncManager)
                .environmentObject(languageManager)
                .environment(\.inboxModelContext, inboxModelContainer.mainContext)
                .task {
                    _ = languageManager.currentLanguage
                    await requestNotificationPermission()
                }
                .onReceive(NotificationCenter.default.publisher(for: .CKAccountChanged)) { _ in
                    cloudSyncManager.refreshAccountStatus()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    _Concurrency.Task {
                        await cloudSyncManager.syncData(modelContext: modelContainer.mainContext)
                    }
                }
                .task {
                    cloudSyncManager.refreshAccountStatus()
                    await cloudSyncManager.syncData(modelContext: modelContainer.mainContext)
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
