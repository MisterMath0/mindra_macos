//
//  NotificationService.swift
//  MindraTimer
//
//  Centralized notification service
//

import Foundation
import UserNotifications

protocol NotificationServiceProtocol {
    func requestPermission() async -> Bool
    func scheduleTimerNotification(title: String, body: String, delay: TimeInterval)
    func scheduleAchievementNotification(achievement: Achievement)
    func cancelAllNotifications()
    func cancelNotification(with identifier: String)
    func setupNotificationCategories()
}

class NotificationService: NotificationServiceProtocol, ObservableObject {
    @Published var permissionGranted = false
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    
    init() {
        checkPermissionStatus()
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
        """
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
