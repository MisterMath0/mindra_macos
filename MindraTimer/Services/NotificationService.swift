//
//  NotificationService.swift
//  MindraTimer
//
//  Centralized notification service
//

import Foundation
import UserNotifications
import SwiftUI

protocol NotificationServiceProtocol {
    func requestPermission() async -> Bool
    func scheduleTimerNotification(title: String, body: String, delay: TimeInterval)
    func scheduleAchievementNotification(achievement: Achievement)
    func cancelAllNotifications()
    func cancelNotification(with identifier: String)
    func setupNotificationCategories()
    // Enhanced notification methods
    func handleSessionComplete(mode: TimerMode, duration: Int, completed: Bool)
    func handleAchievementUnlocked(_ achievement: Achievement)
    func checkForMilestones()
    func checkForStreakReminder()
    func sendEncouragementMessage()
}

class NotificationService: NotificationServiceProtocol, ObservableObject {
    @Published var permissionGranted = false
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Enhanced Notification Features
    @Published var showingBanner = false
    @Published var currentBanner: NotificationBanner?
    @Published var recentNotifications: [NotificationBanner] = []
    @Published var activeBanners: [NotificationBanner] = []
    
    // Enhanced settings
    @Published var enableInAppBanners = true
    @Published var enableMilestoneNotifications = true
    @Published var enableAchievementCelebrations = true
    @Published var enableStreakReminders = true
    @Published var enableEncouragementMessages = true
    
    private let center = UNUserNotificationCenter.current()
    private var userName: String?
    private var statsManager: StatsManager?
    private var timerManager: TimerManager?
    
    init() {
        checkPermissionStatus()
        loadEnhancedSettings()
        loadRecentNotifications()
    }
    
    // MARK: - Permission Management
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            await MainActor.run {
                self.permissionGranted = granted
                self.permissionStatus = granted ? .authorized : .denied
            }
            
            print("📢 Notification permission: \(granted ? "Granted" : "Denied")")
            return granted
        } catch {
            print("📢 Error requesting notification permission: \(error)")
            return false
        }
    }
    
    private func checkPermissionStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionStatus = settings.authorizationStatus
                self.permissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Timer Notifications
    
    func scheduleTimerNotification(title: String, body: String, delay: TimeInterval) {
        guard permissionGranted else {
            print("📢 Cannot schedule notification: Permission not granted")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "TIMER_COMPLETE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let identifier = "timer_\(UUID().uuidString)"
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("📢 Error scheduling timer notification: \(error)")
            } else {
                print("📢 Timer notification scheduled: \(title)")
            }
        }
    }
    
    // MARK: - Achievement Notifications
    
    func scheduleAchievementNotification(achievement: Achievement) {
        guard permissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 Achievement Unlocked!"
        content.body = "\(achievement.icon) \(achievement.title): \(achievement.description)"
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT_UNLOCKED"
        
        // Schedule immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let identifier = "achievement_\(achievement.id.uuidString)"
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("📢 Error scheduling achievement notification: \(error)")
            } else {
                print("📢 Achievement notification scheduled: \(achievement.title)")
            }
        }
    }
    
    // MARK: - Notification Management
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        print("📢 All notifications cancelled")
    }
    
    func cancelNotification(with identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        print("📢 Cancelled notification: \(identifier)")
    }
    
    func cancelTimerNotifications() {
        center.getPendingNotificationRequests { requests in
            let timerNotifications = requests.filter { $0.identifier.hasPrefix("timer_") }
            let identifiers = timerNotifications.map { $0.identifier }
            
            self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
            print("📢 Cancelled \(identifiers.count) timer notifications")
        }
    }
    
    // MARK: - Notification Categories
    
    func setupNotificationCategories() {
        let timerCompleteCategory = UNNotificationCategory(
            identifier: "TIMER_COMPLETE",
            actions: [
                UNNotificationAction(
                    identifier: "START_BREAK",
                    title: "Start Break",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "Dismiss",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let achievementCategory = UNNotificationCategory(
            identifier: "ACHIEVEMENT_UNLOCKED",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_ACHIEVEMENTS",
                    title: "View All",
                    options: .foreground
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([timerCompleteCategory, achievementCategory])
    }
    
    // MARK: - Debug and Info
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
    
    func getDeliveredNotifications() async -> [UNNotification] {
        return await center.deliveredNotifications()
    }
    
    func getNotificationInfo() async -> String {
        let pending = await getPendingNotifications()
        let delivered = await getDeliveredNotifications()
        
        return """
        📢 Notification Service Info:
        • Permission: \(permissionGranted ? "Granted" : "Not Granted")
        • Status: \(permissionStatus.rawValue)
        • Pending: \(pending.count)
        • Delivered: \(delivered.count)
        • In-App Banners: \(enableInAppBanners ? "Enabled" : "Disabled")
        • Recent Notifications: \(recentNotifications.count)
        """
    }
    
    // MARK: - Enhanced Notification Features
    
    func setUserName(_ userName: String?) {
        self.userName = userName
    }
    
    func setStatsManager(_ statsManager: StatsManager) {
        self.statsManager = statsManager
    }
    
    func setTimerManager(_ timerManager: TimerManager) {
        self.timerManager = timerManager
    }
    
    // MARK: - Session Complete Notifications with Personalization
    
    func handleSessionComplete(mode: TimerMode, duration: Int, completed: Bool) {
        guard completed else { return }
        
        let personalizedTitle = getPersonalizedTitle(for: mode)
        let message = getSessionCompleteMessage(for: mode, duration: duration)
        
        // Create in-app banner
        if enableInAppBanners {
            let banner = NotificationBanner(
                type: .sessionComplete,
                title: personalizedTitle,
                message: message,
                actionText: mode == .focus ? "Start Break" : "Start Focus",
                actionIdentifier: "start_next_session"
            )
            showBanner(banner)
        }
        
        // Create system notification
        let systemTitle = mode == .focus ? "Focus Session Complete! 🎯" : "Break Complete! ⚡"
        scheduleTimerNotification(title: systemTitle, body: message, delay: 0.1)
        
        // Check for milestones after focus sessions
        if mode == .focus {
            checkForMilestones()
        }
    }
    
    // MARK: - Achievement Notifications with Celebration
    
    func handleAchievementUnlocked(_ achievement: Achievement) {
        let personalizedTitle = getPersonalizedAchievementTitle()
        let message = "\(achievement.icon) \(achievement.title): \(achievement.description)"
        
        // Create celebration banner
        if enableAchievementCelebrations {
            let banner = NotificationBanner(
                type: .achievementUnlocked,
                title: personalizedTitle,
                message: message,
                actionText: "View Achievements",
                actionIdentifier: "view_achievements"
            )
            showBanner(banner)
        }
        
        // Create system notification
        scheduleAchievementNotification(achievement: achievement)
        
        // Trigger celebration
        triggerAchievementCelebration(achievement: achievement)
    }
    
    // MARK: - Milestone Notifications
    
    func checkForMilestones() {
        guard let statsManager = statsManager, enableMilestoneNotifications else { return }
        
        let achievements = statsManager.achievements
        
        for achievement in achievements {
            if !achievement.unlocked {
                let milestoneThresholds = getMilestoneThresholds(for: achievement.target)
                
                for threshold in milestoneThresholds {
                    let milestoneProgress = achievement.target * threshold
                    
                    if achievement.progress >= milestoneProgress && achievement.progress < milestoneProgress + 1 {
                        showMilestoneNotification(for: achievement, threshold: threshold)
                        break
                    }
                }
            }
        }
    }
    
    private func showMilestoneNotification(for achievement: Achievement, threshold: Double) {
        let remaining = Int(achievement.target - achievement.progress)
        let progressPercent = Int(threshold * 100)
        
        let title = "Milestone Reached! 🎯"
        let message = "\(progressPercent)% progress on \(achievement.title). Just \(remaining) more to unlock!"
        
        let banner = NotificationBanner(
            type: .milestone,
            title: title,
            message: message,
            actionText: "View Progress",
            actionIdentifier: "view_achievements"
        )
        
        showBanner(banner)
    }
    
    private func getMilestoneThresholds(for target: Double) -> [Double] {
        if target <= 10 {
            return [0.5, 0.8] // 50%, 80%
        } else if target <= 50 {
            return [0.25, 0.5, 0.75, 0.9] // 25%, 50%, 75%, 90%
        } else {
            return [0.1, 0.25, 0.5, 0.75, 0.9] // 10%, 25%, 50%, 75%, 90%
        }
    }
    
    // MARK: - Streak Reminders
    
    func checkForStreakReminder() {
        guard let statsManager = statsManager, enableStreakReminders else { return }
        
        let currentStreak = statsManager.summary.currentStreak
        let todaysSessions = statsManager.getSessionsToday()
        
        // Remind if user has a streak but hasn't focused today
        if currentStreak > 0 && todaysSessions == 0 {
            let calendar = Calendar.current
            let now = Date()
            let hour = calendar.component(.hour, from: now)
            
            // Send reminder in the evening (6 PM - 9 PM)
            if hour >= 18 && hour <= 21 {
                showStreakReminder(currentStreak: currentStreak)
            }
        }
    }
    
    private func showStreakReminder(currentStreak: Int) {
        let personalizedTitle = getPersonalizedStreakTitle()
        let message = "Your \(currentStreak)-day streak is waiting! Don't break the chain. 🔥"
        
        let banner = NotificationBanner(
            type: .streakReminder,
            title: personalizedTitle,
            message: message,
            actionText: "Start Focus",
            actionIdentifier: "start_focus_session"
        )
        
        showBanner(banner)
    }
    
    // MARK: - Encouragement Messages
    
    func sendEncouragementMessage() {
        guard enableEncouragementMessages else { return }
        
        let messages = getEncouragementMessages()
        guard let message = messages.randomElement() else { return }
        
        let title = getPersonalizedEncouragementTitle()
        
        let banner = NotificationBanner(
            type: .encouragement,
            title: title,
            message: message,
            actionText: "Let's Focus",
            actionIdentifier: "start_focus_session"
        )
        
        showBanner(banner)
    }
    
    // MARK: - Banner Management
    
    private func showBanner(_ banner: NotificationBanner) {
        DispatchQueue.main.async {
            // Add to recent notifications
            self.recentNotifications.insert(banner, at: 0)
            
            // Limit recent notifications to 20
            if self.recentNotifications.count > 20 {
                self.recentNotifications.removeLast()
            }
            
            // Show banner if not already showing one
            if !self.showingBanner {
                self.currentBanner = banner
                self.showingBanner = true
                
                // Auto-dismiss after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.dismissCurrentBanner()
                }
            } else {
                // Queue banner for later
                self.activeBanners.append(banner)
            }
            
            self.saveRecentNotifications()
        }
    }
    
    func dismissCurrentBanner() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingBanner = false
            currentBanner = nil
        }
        
        // Show next banner if queued
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.activeBanners.isEmpty {
                let nextBanner = self.activeBanners.removeFirst()
                self.currentBanner = nextBanner
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showingBanner = true
                }
                
                // Auto-dismiss after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.dismissCurrentBanner()
                }
            }
        }
    }
    
    func markNotificationAsRead(_ notification: NotificationBanner) {
        if let index = recentNotifications.firstIndex(where: { $0.id == notification.id }) {
            recentNotifications[index].isRead = true
            saveRecentNotifications()
        }
    }
    
    func clearAllNotifications() {
        recentNotifications.removeAll()
        activeBanners.removeAll()
        currentBanner = nil
        showingBanner = false
        saveRecentNotifications()
        
        // Also clear system notifications
        cancelAllNotifications()
    }
    
    // MARK: - Action Handling
    
    func handleNotificationAction(_ actionIdentifier: String) {
        switch actionIdentifier {
        case "start_next_session":
            // Will be handled by the app coordinator
            break
        case "start_focus_session":
            // Will be handled by the app coordinator
            break
        case "view_achievements":
            // Will be handled by the app coordinator
            break
        default:
            break
        }
    }
    
    // MARK: - Personalization Helpers
    
    private func getPersonalizedTitle(for mode: TimerMode) -> String {
        guard let name = userName, !name.isEmpty else {
            return mode == .focus ? "Focus Complete! 🎯" : "Break Complete! ⚡"
        }
        
        switch mode {
        case .focus:
            return "\(name), great focus session! 🎯"
        case .shortBreak:
            return "\(name), refreshed and ready! ⚡"
        case .longBreak:
            return "\(name), well-deserved break! 🌟"
        }
    }
    
    private func getPersonalizedAchievementTitle() -> String {
        guard let name = userName, !name.isEmpty else {
            return "Achievement Unlocked! 🏆"
        }
        return "\(name), you've unlocked an achievement! 🏆"
    }
    
    private func getPersonalizedStreakTitle() -> String {
        guard let name = userName, !name.isEmpty else {
            return "Keep Your Streak Alive! 🔥"
        }
        return "\(name), don't break your streak! 🔥"
    }
    
    private func getPersonalizedEncouragementTitle() -> String {
        guard let name = userName, !name.isEmpty else {
            return "You've Got This! 💪"
        }
        return "\(name), you've got this! 💪"
    }
    
    private func getSessionCompleteMessage(for mode: TimerMode, duration: Int) -> String {
        let minutes = duration / 60
        
        switch mode {
        case .focus:
            return "You focused for \(minutes) minutes. Time for a well-deserved break!"
        case .shortBreak:
            return "Short break complete. Ready to dive back into focused work?"
        case .longBreak:
            return "Long break complete. You're refreshed and ready for more productivity!"
        }
    }
    
    private func getEncouragementMessages() -> [String] {
        return [
            "Every expert was once a beginner. Keep building your focus muscle! 💪",
            "Small consistent actions lead to big results. You're on the right track! 🎯",
            "Your future self will thank you for the focus you build today! 🌟",
            "Progress, not perfection. Every session counts! 📈",
            "The best time to focus was yesterday. The second best time is now! ⏰",
            "You're not just managing time, you're investing in your potential! 💎",
            "Champions are made in the moments when no one is watching. Focus time! 🏆"
        ]
    }
    
    // MARK: - Achievement Celebration
    
    private func triggerAchievementCelebration(achievement: Achievement) {
        // Store the achievement for celebration in UI
        UserDefaults.standard.set(achievement.id.uuidString, forKey: "recent_achievement_unlock")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "recent_achievement_time")
    }
    
    // MARK: - Enhanced Settings Persistence
    
    private func loadEnhancedSettings() {
        enableInAppBanners = UserDefaults.standard.object(forKey: "notification_banners") as? Bool ?? true
        enableMilestoneNotifications = UserDefaults.standard.object(forKey: "notification_milestones") as? Bool ?? true
        enableAchievementCelebrations = UserDefaults.standard.object(forKey: "notification_achievements") as? Bool ?? true
        enableStreakReminders = UserDefaults.standard.object(forKey: "notification_streaks") as? Bool ?? true
        enableEncouragementMessages = UserDefaults.standard.object(forKey: "notification_encouragement") as? Bool ?? true
    }
    
    private func saveEnhancedSettings() {
        UserDefaults.standard.set(enableInAppBanners, forKey: "notification_banners")
        UserDefaults.standard.set(enableMilestoneNotifications, forKey: "notification_milestones")
        UserDefaults.standard.set(enableAchievementCelebrations, forKey: "notification_achievements")
        UserDefaults.standard.set(enableStreakReminders, forKey: "notification_streaks")
        UserDefaults.standard.set(enableEncouragementMessages, forKey: "notification_encouragement")
    }
    
    private func loadRecentNotifications() {
        guard let data = UserDefaults.standard.data(forKey: "recent_notifications"),
              let notifications = try? JSONDecoder().decode([NotificationBanner].self, from: data) else {
            return
        }
        
        // Only keep notifications from the last 7 days
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        recentNotifications = notifications.filter { $0.timestamp > oneWeekAgo }
    }
    
    private func saveRecentNotifications() {
        guard let data = try? JSONEncoder().encode(recentNotifications) else { return }
        UserDefaults.standard.set(data, forKey: "recent_notifications")
    }
    
    // MARK: - Settings Update Methods
    
    func updateBannerSettings(_ enabled: Bool) {
        enableInAppBanners = enabled
        saveEnhancedSettings()
    }
    
    func updateMilestoneSettings(_ enabled: Bool) {
        enableMilestoneNotifications = enabled
        saveEnhancedSettings()
    }
    
    func updateAchievementSettings(_ enabled: Bool) {
        enableAchievementCelebrations = enabled
        saveEnhancedSettings()
    }
    
    func updateStreakSettings(_ enabled: Bool) {
        enableStreakReminders = enabled
        saveEnhancedSettings()
    }
    
    func updateEncouragementSettings(_ enabled: Bool) {
        enableEncouragementMessages = enabled
        saveEnhancedSettings()
    }
}

// MARK: - Mock Service for Testing

class MockNotificationService: NotificationServiceProtocol {
    private(set) var scheduledNotifications: [String] = []
    private(set) var cancelledNotifications: [String] = []
    private(set) var achievementNotifications: [Achievement] = []
    
    var mockPermissionGranted = true
    
    func requestPermission() async -> Bool {
        return mockPermissionGranted
    }
    
    func scheduleTimerNotification(title: String, body: String, delay: TimeInterval) {
        let notification = "Timer: \(title) - \(body) (delay: \(delay)s)"
        scheduledNotifications.append(notification)
        print("📢 Mock: Scheduled timer notification - \(notification)")
    }
    
    func scheduleAchievementNotification(achievement: Achievement) {
        achievementNotifications.append(achievement)
        print("📢 Mock: Scheduled achievement notification - \(achievement.title)")
    }
    
    func cancelAllNotifications() {
        cancelledNotifications.append("ALL")
        scheduledNotifications.removeAll()
        achievementNotifications.removeAll()
        print("📢 Mock: Cancelled all notifications")
    }
    
    func cancelNotification(with identifier: String) {
        cancelledNotifications.append(identifier)
        print("📢 Mock: Cancelled notification - \(identifier)")
    }
    
    func setupNotificationCategories() {
        print("📢 Mock: Setup notification categories")
    }
    
    // Enhanced notification methods
    func handleSessionComplete(mode: TimerMode, duration: Int, completed: Bool) {
        print("📢 Mock: Session complete - \(mode.displayName), duration: \(duration), completed: \(completed)")
    }
    
    func handleAchievementUnlocked(_ achievement: Achievement) {
        achievementNotifications.append(achievement)
        print("📢 Mock: Achievement unlocked - \(achievement.title)")
    }
    
    func checkForMilestones() {
        print("📢 Mock: Checking for milestones")
    }
    
    func checkForStreakReminder() {
        print("📢 Mock: Checking for streak reminders")
    }
    
    func sendEncouragementMessage() {
        print("📢 Mock: Sending encouragement message")
    }
    
    func reset() {
        scheduledNotifications.removeAll()
        cancelledNotifications.removeAll()
        achievementNotifications.removeAll()
    }
}

// MARK: - Extensions

extension UNAuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}
