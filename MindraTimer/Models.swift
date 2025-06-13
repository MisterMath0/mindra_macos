//
//  Models.swift
//  MindraTimer
//
//  ☢️ NUCLEAR CONSOLIDATION: Clean single source of truth
//

import SwiftUI
import Foundation

// MARK: - Core Enums

enum AppMode: String, CaseIterable, Codable {
    case clock = "clock"
    case pomodoro = "pomodoro"
    
    var displayName: String {
        switch self {
        case .clock: return "Clock"
        case .pomodoro: return "Pomodoro"
        }
    }
    
    var iconName: String {
        switch self {
        case .clock: return "clock"
        case .pomodoro: return "timer"
        }
    }
}

enum TimerMode: String, CaseIterable, Codable {
    case focus = "focus"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"
    
    var displayName: String {
        switch self {
        case .focus: return "FOCUS"
        case .shortBreak: return "SHORT BREAK"
        case .longBreak: return "LONG BREAK"
        }
    }
    
    var color: Color {
        switch self {
        case .focus: return Color(red: 0.5, green: 0.3, blue: 0.9)
        case .shortBreak: return Color(red: 0.9, green: 0.5, blue: 0.7)
        case .longBreak: return Color(red: 0.3, green: 0.6, blue: 0.9)
        }
    }
    
    var defaultDuration: TimeInterval {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 10 * 60
        }
    }
}

enum SoundOption: String, CaseIterable, Codable {
    case sparkle = "sparkle"
    case chime = "chime"
    case bellSoft = "bellSoft"
    case bellLoud = "bellLoud"
    case trainArrival = "trainArrival"
    case commuterJingle = "commuterJingle"
    case gameShow = "gameShow"
    
    var displayName: String {
        switch self {
        case .sparkle: return "Sparkle"
        case .chime: return "Chime"
        case .bellSoft: return "Bell (Soft)"
        case .bellLoud: return "Bell (Loud)"
        case .trainArrival: return "Train Arrival"
        case .commuterJingle: return "Commuter Jingle"
        case .gameShow: return "Game Show"
        }
    }
    
    var fileName: String {
        switch self {
        case .sparkle: return "sparkle"
        case .chime: return "chime"
        case .bellSoft: return "bell-soft"
        case .bellLoud: return "bell-loud"
        case .trainArrival: return "train-arrival"
        case .commuterJingle: return "commuter-jingle"
        case .gameShow: return "game-show"
        }
    }
}

enum QuoteCategory: String, CaseIterable, Codable {
    case motivation = "motivation"
    case focus = "focus"
    case productivity = "productivity"
    case wellness = "wellness"
    case success = "success"
    case creativity = "creativity"
    case leadership = "leadership"
    case wisdom = "wisdom"
    
    var displayName: String {
        switch self {
        case .motivation: return "Motivation"
        case .focus: return "Focus"
        case .productivity: return "Productivity"
        case .wellness: return "Wellness"
        case .success: return "Success"
        case .creativity: return "Creativity"
        case .leadership: return "Leadership"
        case .wisdom: return "Wisdom"
        }
    }
    
    var icon: String {
        switch self {
        case .motivation: return "flame.fill"
        case .focus: return "target"
        case .productivity: return "chart.line.uptrend.xyaxis"
        case .wellness: return "leaf.fill"
        case .success: return "trophy.fill"
        case .creativity: return "paintbrush.fill"
        case .leadership: return "person.2.fill"
        case .wisdom: return "brain.head.profile"
        }
    }
    
    var color: Color {
        switch self {
        case .motivation: return AppColors.errorColor
        case .focus: return AppColors.focusColor
        case .productivity: return AppColors.successColor
        case .wellness: return AppColors.longBreakColor
        case .success: return AppColors.warningColor
        case .creativity: return AppColors.shortBreakColor
        case .leadership: return AppColors.infoColor
        case .wisdom: return AppColors.focusColor.opacity(0.8)
        }
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case dark = "dark"
    case light = "light"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .auto: return "Auto"
        }
    }
}

enum VisualizationType: String, CaseIterable, Codable {
    case bar = "bar"
    case line = "line"
    case area = "area"
    
    var displayName: String {
        switch self {
        case .bar: return "Bar Chart"
        case .line: return "Line Chart"
        case .area: return "Area Chart"
        }
    }
}

enum StatsPeriod: String, CaseIterable, Codable {
    case day = "day"
    case week = "week"
    case month = "month"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .all: return "All Time"
        }
    }
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .day:
            let startOfDay = calendar.startOfDay(for: now)
            return (start: startOfDay, end: now)
        case .week:
            let startOfWeek = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return (start: startOfWeek, end: now)
        case .month:
            let startOfMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return (start: startOfMonth, end: now)
        case .all:
            // For 'all' period, get everything from a reasonable start date to now
            let startDate = Calendar.current.date(byAdding: .year, value: -5, to: now) ?? now
            return (start: startDate, end: now)
        }
    }
}

// MARK: - Data Models

struct TimerState: Codable {
    let timeRemaining: Int
    let isActive: Bool
    let isPaused: Bool
    let currentMode: TimerMode
    let sessionsCompleted: Int
    let totalDuration: Int
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(totalDuration - timeRemaining) / Double(totalDuration)
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SessionConfiguration: Codable {
    let focusDuration: TimeInterval
    let shortBreakDuration: TimeInterval
    let longBreakDuration: TimeInterval
    let sessionsUntilLongBreak: Int
    let autoStartBreaks: Bool
    let autoStartPomodoros: Bool
    
    static let `default` = SessionConfiguration(
        focusDuration: 25 * 60,
        shortBreakDuration: 5 * 60,
        longBreakDuration: 15 * 60,
        sessionsUntilLongBreak: 4,
        autoStartBreaks: false,
        autoStartPomodoros: false
    )
    
    func duration(for mode: TimerMode) -> TimeInterval {
        switch mode {
        case .focus: return focusDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        }
    }
}

struct FocusSession: Codable, Identifiable {
    let id: String
    let startedAt: Date
    let endedAt: Date?
    let duration: Int
    let completed: Bool
    let mode: TimerMode
    let notes: String?
    
    init(id: String = UUID().uuidString, 
         startedAt: Date, 
         endedAt: Date? = nil, 
         duration: Int, 
         completed: Bool, 
         mode: TimerMode,
         notes: String? = nil) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
        self.completed = completed
        self.mode = mode
        self.notes = notes
    }
    
    var isCompleted: Bool {
        return completed && endedAt != nil
    }
    
    var actualDuration: TimeInterval {
        if let endedAt = endedAt {
            return endedAt.timeIntervalSince(startedAt)
        }
        return TimeInterval(duration)
    }
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct Quote: Identifiable, Codable {
    let id: UUID
    let text: String
    let author: String?
    let category: QuoteCategory
    let isPersonalized: Bool
    let tags: [String]
    
    init(text: String, 
         author: String? = nil, 
         category: QuoteCategory, 
         isPersonalized: Bool = false, 
         tags: [String] = []) {
        self.id = UUID()
        self.text = text
        self.author = author
        self.category = category
        self.isPersonalized = isPersonalized
        self.tags = tags
    }
    
    func personalizedText(with name: String?) -> String {
        guard isPersonalized, let name = name, !name.isEmpty else {
            return text.replacingOccurrences(of: "{name}", with: "friend")
        }
        return text.replacingOccurrences(of: "{name}", with: name)
    }
}

struct QuoteCollection: Codable {
    let category: QuoteCategory
    let quotes: [Quote]
    let lastUpdated: Date
    
    init(category: QuoteCategory, quotes: [Quote]) {
        self.category = category
        self.quotes = quotes
        self.lastUpdated = Date()
    }
    
    func randomQuote() -> Quote? {
        return quotes.randomElement()
    }
}

struct QuoteState: Codable {
    var currentQuote: Quote?
    var currentIndex: Int
    var currentCategory: QuoteCategory
    var lastUpdateTime: Date
    var refreshInterval: TimeInterval
    
    init() {
        self.currentQuote = nil
        self.currentIndex = 0
        self.currentCategory = .motivation
        self.lastUpdateTime = Date()
        self.refreshInterval = 30 * 60
    }
    
    var shouldRefresh: Bool {
        return Date().timeIntervalSince(lastUpdateTime) > refreshInterval
    }
}

struct StatsSummary: Codable {
    let totalSessions: Int
    let totalFocusTime: Int
    let completedSessions: Int
    let completionRate: Double
    let averageSessionLength: Int
    let currentStreak: Int
    let bestStreak: Int
    let totalTasksCompleted: Int
    
    var formattedTotalFocusTime: String {
        let hours = totalFocusTime / 60
        let minutes = totalFocusTime % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    var streakDescription: String {
        if currentStreak == 0 {
            return "Start your streak!"
        } else if currentStreak == 1 {
            return "1 day streak"
        } else {
            return "\(currentStreak) day streak"
        }
    }
    
    static let empty = StatsSummary(
        totalSessions: 0,
        totalFocusTime: 0,
        completedSessions: 0,
        completionRate: 0.0,
        averageSessionLength: 0,
        currentStreak: 0,
        bestStreak: 0,
        totalTasksCompleted: 0
    )
}

struct ChartData: Codable, Identifiable {
    let id: UUID
    let day: String
    let focusMinutes: Int
    let sessions: Int
    let date: Date
    
    init(day: String, focusMinutes: Int, sessions: Int, date: Date = Date()) {
        self.id = UUID()
        self.day = day
        self.focusMinutes = focusMinutes
        self.sessions = sessions
        self.date = date
    }
}

struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let type: AchievementType
    var progress: Double
    let target: Double
    var unlocked: Bool
    var unlockedDate: Date?
    
    enum AchievementType: String, Codable, CaseIterable {
        case totalFocusTime
        case streak
        case sessionsCompleted
        case perfectWeek
        case perfectMonth
        case earlyBird
        case nightOwl
        case weekendWarrior
        case consistency
        case marathon
        
        var displayName: String {
            switch self {
            case .totalFocusTime: return "Total Focus Time"
            case .streak: return "Streak"
            case .sessionsCompleted: return "Sessions Completed"
            case .perfectWeek: return "Perfect Week"
            case .perfectMonth: return "Perfect Month"
            case .earlyBird: return "Early Bird"
            case .nightOwl: return "Night Owl"
            case .weekendWarrior: return "Weekend Warrior"
            case .consistency: return "Consistency"
            case .marathon: return "Marathon"
            }
        }
    }
    
    init(id: UUID = UUID(),
         title: String,
         description: String,
         icon: String,
         type: AchievementType,
         progress: Double = 0,
         target: Double,
         unlocked: Bool = false,
         unlockedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.type = type
        self.progress = progress
        self.target = target
        self.unlocked = unlocked
        self.unlockedDate = unlockedDate
    }
    
    var progressPercentage: Double {
        return min(100, (progress / target) * 100)
    }
    
    var isCompleted: Bool {
        return progress >= target
    }
}

struct AppSettings: Codable {
    var sessionConfiguration: SessionConfiguration
    var autoStartTimer: Bool
    var soundEnabled: Bool
    var soundVolume: Int
    var selectedSound: SoundOption
    var notificationsEnabled: Bool
    var showNotifications: Bool
    var theme: AppTheme
    var disableAnimations: Bool
    var clearMode: Bool
    var showShareButton: Bool
    var use24HourFormat: Bool
    var showGreetings: Bool
    var showDynamicGreetings: Bool
    var showQuotes: Bool
    var enablePersonalizedQuotes: Bool
    var selectedQuoteCategories: [QuoteCategory]
    var quoteRefreshInterval: Int
    var displayPeriod: StatsPeriod
    var showStreak: Bool
    var showAchievements: Bool
    var showTotalTime: Bool
    var showCompletionRate: Bool
    var showAverageSessionLength: Bool
    var enableNotificationsForAchievements: Bool
    var visualizationType: VisualizationType
    var showTimerInMenuBar: Bool
    var showNotificationsInMenuBar: Bool
    var preventScreenSleep: Bool
    var showTimeInTitle: Bool
    var minimizeToTray: Bool
    
    static let `default` = AppSettings(
        sessionConfiguration: SessionConfiguration.default,
        autoStartTimer: true,
        soundEnabled: true,
        soundVolume: 70,
        selectedSound: SoundOption.sparkle,
        notificationsEnabled: true,
        showNotifications: true,
        theme: AppTheme.dark,
        disableAnimations: false,
        clearMode: false,
        showShareButton: true,
        use24HourFormat: false,
        showGreetings: true,
        showDynamicGreetings: true,
        showQuotes: true,
        enablePersonalizedQuotes: false,
        selectedQuoteCategories: [QuoteCategory.motivation, QuoteCategory.focus, QuoteCategory.productivity],
        quoteRefreshInterval: 5,
        displayPeriod: StatsPeriod.week,
        showStreak: true,
        showAchievements: true,
        showTotalTime: false,
        showCompletionRate: false,
        showAverageSessionLength: false,
        enableNotificationsForAchievements: false,
        visualizationType: VisualizationType.bar,
        showTimerInMenuBar: true,
        showNotificationsInMenuBar: true,
        preventScreenSleep: true,
        showTimeInTitle: true,
        minimizeToTray: true
    )
}

struct UserProfile: Codable {
    let id: UUID
    var name: String?
    var createdAt: Date
    var lastActiveAt: Date
    var preferences: UserPreferences
    
    init(name: String? = nil) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.preferences = UserPreferences()
    }
}

struct UserPreferences: Codable {
    var enablePersonalization: Bool
    var preferredGreetingStyle: GreetingStyle
    var customQuotes: [String]
    
    enum GreetingStyle: String, CaseIterable, Codable {
        case casual = "casual"
        case formal = "formal"
        case motivational = "motivational"
        
        var displayName: String {
            switch self {
            case .casual: return "Casual"
            case .formal: return "Formal"
            case .motivational: return "Motivational"
            }
        }
    }
    
    init() {
        self.enablePersonalization = true
        self.preferredGreetingStyle = .casual
        self.customQuotes = []
    }
}
