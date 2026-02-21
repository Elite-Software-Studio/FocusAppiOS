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
    @StateObject private var firebaseSync = FirebaseSyncService.shared

    init() {
        FirebaseApp.configure()
    }

    /// Task container: local-only, explicit store in app container (not App Group) to avoid schema/table errors.
    let modelContainer: ModelContainer = {
        do {
            let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let focusZoneDir = supportURL.appendingPathComponent("FocusZone")
            let taskStoreURL = focusZoneDir.appendingPathComponent("task.store")
            try FileManager.default.createDirectory(at: focusZoneDir, withIntermediateDirectories: true)
            let configuration = ModelConfiguration(url: taskStoreURL, cloudKitDatabase: .none)
            return try ModelContainer(for: Task.self, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    /// Inbox (QuickNote) container: separate store in app container.
    let inboxModelContainer: ModelContainer = {
        do {
            let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let focusZoneDir = supportURL.appendingPathComponent("FocusZone")
            let inboxStoreURL = focusZoneDir.appendingPathComponent("inbox.store")
            try FileManager.default.createDirectory(at: focusZoneDir, withIntermediateDirectories: true)
            let configuration = ModelConfiguration(url: inboxStoreURL, cloudKitDatabase: .none)
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
                .environmentObject(firebaseSync)
                .environment(\.inboxModelContext, inboxModelContainer.mainContext)
                .task {
                    firebaseAuth.configure()
                    _ = languageManager.currentLanguage
                    await requestNotificationPermission()
                    await firebaseSync.sync(taskContext: modelContainer.mainContext, inboxContext: inboxModelContainer.mainContext)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    _Concurrency.Task {
                        await firebaseSync.sync(taskContext: modelContainer.mainContext, inboxContext: inboxModelContainer.mainContext)
                    }
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
