import Foundation

struct Settings: Codable {
    // Timer durations
    var focusDuration: TimeInterval
    var shortBreakDuration: TimeInterval
    var longBreakDuration: TimeInterval
    var sessionsUntilLongBreak: Int
    
    // Auto-start settings
    var autoStartBreaks: Bool
    var autoStartPomodoros: Bool
    
    // Notification settings
    var notificationsEnabled: Bool
    var soundEnabled: Bool
    var notificationSound: String
    var notificationMessage: String
    
    // Goals
    var dailyGoal: TimeInterval
    var weeklyGoal: TimeInterval
    
    // Display settings
    var showTimerInMenuBar: Bool
    var showNotificationsInMenuBar: Bool
    var showProgressBar: Bool
    
    // Advanced settings
    var preventScreenSleep: Bool
    var showTimeInTitle: Bool
    var minimizeToTray: Bool
    
    static let `default` = Settings(
        focusDuration: 25 * 60, // 25 minutes
        shortBreakDuration: 5 * 60, // 5 minutes
        longBreakDuration: 15 * 60, // 15 minutes
        sessionsUntilLongBreak: 4,
        autoStartBreaks: false,
        autoStartPomodoros: false,
        notificationsEnabled: true,
        soundEnabled: true,
        notificationSound: "default",
        notificationMessage: "Time's up! Take a break.",
        dailyGoal: 4 * 60 * 60, // 4 hours
        weeklyGoal: 20 * 60 * 60, // 20 hours
        showTimerInMenuBar: true,
        showNotificationsInMenuBar: true,
        showProgressBar: true,
        preventScreenSleep: true,
        showTimeInTitle: true,
        minimizeToTray: true
    )
    
    // Helper computed properties
    var focusDurationMinutes: Int {
        get { Int(focusDuration / 60) }
        set { focusDuration = TimeInterval(newValue * 60) }
    }
    
    var shortBreakDurationMinutes: Int {
        get { Int(shortBreakDuration / 60) }
        set { shortBreakDuration = TimeInterval(newValue * 60) }
    }
    
    var longBreakDurationMinutes: Int {
        get { Int(longBreakDuration / 60) }
        set { longBreakDuration = TimeInterval(newValue * 60) }
    }
    
    var dailyGoalHours: Int {
        get { Int(dailyGoal / 3600) }
        set { dailyGoal = TimeInterval(newValue * 3600) }
    }
    
    var weeklyGoalHours: Int {
        get { Int(weeklyGoal / 3600) }
        set { weeklyGoal = TimeInterval(newValue * 3600) }
    }
} 