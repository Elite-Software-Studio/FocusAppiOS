//
//  FocusModeManager.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import Foundation
import SwiftUI
import UserNotifications

// Only import Intents if available
#if canImport(Intents)
import Intents
#endif

// Check for iOS 15.0+ availability
@available(iOS 15.0, *)
extension Notification.Name {
    static let INFocusStatusDidChange = Notification.Name("INFocusStatusDidChange")
}

@MainActor
class FocusModeManager: NSObject, ObservableObject {
    @Published var isActiveFocus = false
    @Published var currentFocusMode: FocusMode?
    @Published var blockedNotifications: Int = 0
    @Published var lastFocusActivationError: String?
    
    // Use optional for iOS version compatibility
    private var focusStatusCenter: Any?
    private var focusStatusObserver: NSObjectProtocol?
    private var focusSession: FocusSession?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupFocusStatusCenter()
        setupFocusStatusObserver()
        restoreActiveSession()
    }
    
    deinit {
        if let observer = focusStatusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - iOS Version Compatibility
    
    private func setupFocusStatusCenter() {
        if #available(iOS 15.0, *) {
            #if canImport(Intents)
            focusStatusCenter = INFocusStatusCenter()
            #endif
        }
    }
    
    private var isSystemFocusAvailable: Bool {
        if #available(iOS 15.0, *) {
            #if canImport(Intents)
            return true
            #else
            return false
            #endif
        }
        return false
    }
    
    // MARK: - Focus Activation
    
    func activateFocus(mode: FocusMode, duration: TimeInterval) async -> Bool {
        print("🎯 Attempting to activate focus mode: \(mode.displayName)")
        
        do {
            // Clear any previous errors
            lastFocusActivationError = nil
            
            // Create focus session
            let session = FocusSession(
                id: UUID(),
                mode: mode,
                startTime: Date(),
                plannedDuration: duration
            )
            
            // Try system focus mode first
            let systemActivationSuccess = await activateSystemFocus(mode: mode)
            
            if systemActivationSuccess {
                print("✅ System focus mode activated successfully")
            } else {
                print("⚠️ System focus failed, using custom focus mode")
                // Continue with custom implementation even if system focus fails
            }
            
            // Set up custom notification filtering regardless
            await setupCustomNotificationFiltering(for: mode)
            
            // Update state
            self.focusSession = session
            self.currentFocusMode = mode
            self.isActiveFocus = true
            self.blockedNotifications = 0
            
            // Schedule auto-deactivation
            scheduleAutoDeactivation(after: duration)
            
            // Donate to Shortcuts for learning
            donateStartFocusIntent(taskTitle: "Focus Session")
            
            // Send success notification
            await sendFocusActivatedNotification(mode: mode)
            
            print("🎯 Focus mode '\(mode.displayName)' activated successfully")
            return true
            
        } catch {
            print("❌ Failed to activate focus mode: \(error.localizedDescription)")
            lastFocusActivationError = error.localizedDescription
            return false
        }
    }
    
    func deactivateFocus() async -> Bool {
        print("🎯 Deactivating focus mode")
        
        guard isActiveFocus else {
            print("⚠️ No active focus session to deactivate")
            return true
        }
        
        do {
            // Complete the session
            if var session = focusSession {
                session.endTime = Date()
                session.notificationsBlocked = blockedNotifications
                
                // Save session analytics
                saveFocusSessionAnalytics(session)
            }
            
            // Deactivate system focus if it was activated
            if let mode = currentFocusMode, mode.systemFocusIdentifier != nil {
                await deactivateSystemFocus()
            }
            
            // Clear custom notification filtering
            await clearCustomNotificationFiltering()
            
            // Cancel auto-deactivation timer
            cancelAutoDeactivation()
            
            // Update state
            self.isActiveFocus = false
            self.currentFocusMode = nil
            self.focusSession = nil
            
            // Donate stop intent
            donateStopFocusIntent()
            
            // Send completion notification
            await sendFocusDeactivatedNotification()
            
            print("✅ Focus mode deactivated successfully")
            return true
            
        } catch {
            print("❌ Failed to deactivate focus mode: \(error.localizedDescription)")
            lastFocusActivationError = error.localizedDescription
            return false
        }
    }
    
    func getCurrentFocusStatus() -> Any? {
        // Check system focus status with availability check
        if #available(iOS 15.0, *), isSystemFocusAvailable {
            #if canImport(Intents)
            if let center = focusStatusCenter as? INFocusStatusCenter {
                return center.focusStatus
            }
            #endif
        }
        
        // Fallback: return our custom focus status
        if isActiveFocus {
            return CustomFocusStatus(isFocused: true)
        }
        
        return nil
    }
    
    // MARK: - System Focus Integration
    private func activateSystemFocus(mode: FocusMode) async -> Bool {
        guard mode.systemFocusIdentifier != nil else {
            print("📱 No system focus mode for \(mode.displayName), using custom implementation")
            return false
        }
        
        guard isSystemFocusAvailable else {
            print("📱 System focus not available on this iOS version, using custom implementation")
            return false
        }
    
        return false
    }
    
    private func deactivateSystemFocus() async {
        guard isSystemFocusAvailable else { return }
        
    }
    
    // MARK: - Notification Management
    
    func setupCustomNotificationFiltering(for mode: FocusMode) async {
        print("🔕 Setting up custom notification filtering for \(mode.displayName)")
        
        // Request notification permissions if needed
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        // Configure filtering based on focus mode
        let filteringEnabled = await requestNotificationManagementPermission()
        
        if filteringEnabled {
            print("✅ Notification filtering enabled")
        } else {
            print("⚠️ Notification filtering not available - limited permissions")
        }
    }
    
    func clearCustomNotificationFiltering() async {
        print("🔕 Clearing custom notification filtering")
        // Reset notification center delegate if needed
        // In a real implementation, you might want to restore previous delegate
    }
    
    private func requestNotificationManagementPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let settings = await center.notificationSettings()
            return settings.authorizationStatus == .authorized
        } catch {
            print("❌ Failed to check notification permissions: \(error)")
            return false
        }
    }
    
    func shouldAllowNotification(_ notification: UNNotification) -> Bool {
        guard isActiveFocus, let mode = currentFocusMode else {
            return true // No active focus, allow all notifications
        }
        
        let request = notification.request
        let content = request.content
        
        // Always allow critical notifications
        if content.interruptionLevel == .critical {
            return true
        }
        
        // Always allow notifications from FocusZone itself
        if request.identifier.hasPrefix("focus_zone_") {
            return true
        }
        
        // Filter based on focus mode intensity
        switch mode {
        case .doNotDisturb:
            // Block everything except critical
            return false
            
        case .deepWork:
            // Block most notifications, allow only work-related
            return isWorkRelatedNotification(content)
            
        case .workMode:
            // Use system work focus if available, otherwise custom filtering
            return isWorkRelatedNotification(content) || isUrgentNotification(content)
            
        case .lightFocus:
            // Block entertainment and social media, allow important notifications
            return !isDistractingNotification(content)
        }
    }
    
    func trackBlockedNotification() {
        blockedNotifications += 1
        print("🚫 Blocked notification #\(blockedNotifications)")
        
        // Update UI with haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Notification Classification
    
    private func isWorkRelatedNotification(_ content: UNNotificationContent) -> Bool {
        let workKeywords = ["meeting", "calendar", "email", "slack", "teams", "zoom", "work", "project", "deadline"]
        let text = (content.title + " " + content.body).lowercased()
        
        return workKeywords.contains { text.contains($0) }
    }
    
    private func isUrgentNotification(_ content: UNNotificationContent) -> Bool {
        let urgentKeywords = ["urgent", "emergency", "asap", "important", "call", "phone"]
        let text = (content.title + " " + content.body).lowercased()
        
        return urgentKeywords.contains { text.contains($0) }
    }
    
    private func isDistractingNotification(_ content: UNNotificationContent) -> Bool {
        let distractingApps = ["instagram", "facebook", "twitter", "tiktok", "youtube", "netflix", "game"]
        let bundleId = content.targetContentIdentifier?.lowercased() ?? ""
        let text = (content.title + " " + content.body).lowercased()
        
        return distractingApps.contains { bundleId.contains($0) || text.contains($0) }
    }
    
    // MARK: - Focus Status Observer
    
    private func setupFocusStatusObserver() {
        guard isSystemFocusAvailable else {
            print("📱 Focus status observer not available on this iOS version")
            return
        }
    }
    
    private func handleSystemFocusStatusChange() {
        let systemStatus = getCurrentFocusStatus()
        
        // Handle both INFocusStatus and our custom status
        var isFocused = false
        
        print("📱 System focus status changed: \(isFocused ? "Active" : "Inactive")")
        
        // Sync our state with system focus if we didn't initiate the change
        if isFocused && !isActiveFocus {
            // System focus was activated externally
            print("🔄 Syncing with external system focus activation")
            // You might want to activate light focus mode as fallback
        } else if !isFocused && isActiveFocus {
            // System focus was deactivated externally
            print("🔄 System focus deactivated externally, maintaining custom focus")
            // Decision: Keep custom focus or deactivate? Depends on UX preference
        }
    }
    
    // MARK: - Auto-deactivation
    
    private var autoDeactivationTimer: Timer?
    
    private func scheduleAutoDeactivation(after duration: TimeInterval) {
        cancelAutoDeactivation()
        
        autoDeactivationTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                print("⏰ Auto-deactivating focus mode after planned duration")
                await self?.deactivateFocus()
            }
        }
    }
    
    private func cancelAutoDeactivation() {
        autoDeactivationTimer?.invalidate()
        autoDeactivationTimer = nil
    }
    
    // MARK: - Shortcuts Integration
    
    func donateStartFocusIntent(taskTitle: String) {
        guard let mode = currentFocusMode else { return }
        guard isSystemFocusAvailable else {
            print("📱 Shortcuts integration not available on this iOS version")
            return
        }
    }
    
    func donateStopFocusIntent() {
        guard isSystemFocusAvailable else {
            print("📱 Shortcuts integration not available on this iOS version")
            return
        }
    }
    
    // MARK: - Session Management
    
    private func restoreActiveSession() {
        // Try to restore any active focus session from UserDefaults
        if let sessionData = UserDefaults.standard.data(forKey: "active_focus_session"),
           let session = try? JSONDecoder().decode(FocusSession.self, from: sessionData) {
            
            // Check if session is still valid (not expired)
            let now = Date()
            let sessionDuration = now.timeIntervalSince(session.startTime)
            
            if sessionDuration < session.plannedDuration {
                // Restore session
                self.focusSession = session
                self.currentFocusMode = session.mode
                self.isActiveFocus = true
                
                // Schedule remaining auto-deactivation
                let remainingDuration = session.plannedDuration - sessionDuration
                scheduleAutoDeactivation(after: remainingDuration)
                
                print("🔄 Restored active focus session: \(session.mode.displayName)")
            } else {
                // Session expired, clean up
                UserDefaults.standard.removeObject(forKey: "active_focus_session")
            }
        }
    }
    
    private func saveFocusSessionAnalytics(_ session: FocusSession) {
        // Save session data for analytics
        if let data = try? JSONEncoder().encode(session) {
            var sessions = getFocusSessionHistory()
            sessions.append(session)
            
            // Keep only last 50 sessions
            if sessions.count > 50 {
                sessions = Array(sessions.suffix(50))
            }
            
            if let historyData = try? JSONEncoder().encode(sessions) {
                UserDefaults.standard.set(historyData, forKey: "focus_session_history")
            }
        }
        
        // Clear active session
        UserDefaults.standard.removeObject(forKey: "active_focus_session")
        
        print("📊 Saved focus session analytics: \(session.duration) seconds, \(session.notificationsBlocked) blocked")
    }
    
    private func getFocusSessionHistory() -> [FocusSession] {
        guard let data = UserDefaults.standard.data(forKey: "focus_session_history"),
              let sessions = try? JSONDecoder().decode([FocusSession].self, from: data) else {
            return []
        }
        return sessions
    }
    
    // MARK: - Notifications
    
    private func sendFocusActivatedNotification(mode: FocusMode) async {
        let content = UNMutableNotificationContent()
        content.title = "🎯 Focus Mode Active"
        content.body = "\(mode.displayName) is now helping you stay focused"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "FOCUS_STATUS"
        
        let request = UNNotificationRequest(
            identifier: "focus_zone_activated",
            content: content,
            trigger: nil // Immediate
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("❌ Failed to send focus activation notification: \(error)")
        }
    }
    
    private func sendFocusDeactivatedNotification() async {
        guard let session = focusSession else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "✅ Focus Session Complete"
        
        let minutes = Int(session.duration / 60)
        content.body = "Great job! You focused for \(minutes) minutes and blocked \(blockedNotifications) distractions"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "FOCUS_COMPLETE"
        
        let request = UNNotificationRequest(
            identifier: "focus_zone_completed",
            content: content,
            trigger: nil // Immediate
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("❌ Failed to send focus completion notification: \(error)")
        }
    }
    
    // MARK: - Public Analytics Methods
    
    func getFocusEffectiveness() -> Double {
        let sessions = getFocusSessionHistory()
        guard !sessions.isEmpty else { return 0.0 }
        
        let totalSessions = Double(sessions.count)
        let completedSessions = sessions.filter { $0.endTime != nil }.count
        
        return Double(completedSessions) / totalSessions
    }
    
    func getAverageSessionDuration() -> TimeInterval {
        let sessions = getFocusSessionHistory().filter { $0.endTime != nil }
        guard !sessions.isEmpty else { return 0 }
        
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        return totalDuration / Double(sessions.count)
    }
    
    func getTotalNotificationsBlocked() -> Int {
        return getFocusSessionHistory().reduce(0) { $0 + $1.notificationsBlocked }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension FocusModeManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Check if notification should be allowed during focus
        if shouldAllowNotification(notification) {
            completionHandler([.banner, .sound, .badge])
        } else {
            // Block the notification
            trackBlockedNotification()
            completionHandler([]) // No presentation
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification interactions
        let identifier = response.notification.request.identifier
        
        if identifier.hasPrefix("focus_zone_") {
            // Handle FocusZone-specific notifications
            print("👆 User interacted with FocusZone notification: \(identifier)")
        }
        
        completionHandler()
    }
}

// MARK: - Supporting Models

// Custom focus status for iOS versions without INFocusStatus
struct CustomFocusStatus {
    let isFocused: Bool
}
