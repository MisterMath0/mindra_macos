//
//  AnalyticsService.swift
//  MindraTimer
//
//  Analytics and data processing service
//

import Foundation

protocol AnalyticsServiceProtocol {
    func trackSessionStart(mode: TimerMode)
    func trackSessionComplete(session: FocusSession)
    func trackAchievementUnlocked(achievement: Achievement)
    func trackSettingsChanged(setting: String, value: Any)
    func generateAnalyticsReport(for period: StatsPeriod) -> AnalyticsReport
}

struct AnalyticsEvent: Codable {
    let id: UUID
    let timestamp: Date
    let type: EventType
    let data: [String: String]
    
    enum EventType: String, CaseIterable, Codable {
        case sessionStart = "session_start"
        case sessionComplete = "session_complete"
        case sessionSkipped = "session_skipped"
        case achievementUnlocked = "achievement_unlocked"
        case settingsChanged = "settings_changed"
        case appLaunched = "app_launched"
        case appClosed = "app_closed"
        case modeChanged = "mode_changed"
    }
    
    init(type: EventType, data: [String: String] = [:]) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.data = data
    }
}

struct AnalyticsReport: Codable {
    let period: StatsPeriod
    let generatedAt: Date
    let totalEvents: Int
    let sessionMetrics: SessionMetrics
    let usagePatterns: UsagePatterns
    let achievementMetrics: AchievementMetrics
    
    struct SessionMetrics: Codable {
        let totalSessions: Int
        let completedSessions: Int
        let skippedSessions: Int
        let averageSessionLength: TimeInterval
        let totalFocusTime: TimeInterval
        let mostProductiveDay: String?
        let averageCompletionRate: Double
    }
    
    struct UsagePatterns: Codable {
        let mostActiveHour: Int?
        let mostActiveDayOfWeek: String?
        let averageSessionsPerDay: Double
        let peakUsageTimes: [Int] // Hours of day
        let sessionsByMode: [String: Int]
    }
    
    struct AchievementMetrics: Codable {
        let totalUnlocked: Int
        let recentUnlocks: [String]
        let progressTowardsNext: [String: Double]
    }
}

class AnalyticsService: AnalyticsServiceProtocol, ObservableObject {
    @Published private(set) var events: [AnalyticsEvent] = []
    
    private let userDefaults = UserDefaults.standard
    private let eventsKey = "analytics_events"
    private let maxStoredEvents = 10000 // Limit stored events to prevent memory issues
    
    init() {
        loadEvents()
        trackAppLaunched()
    }
    
    // MARK: - Event Tracking
    
    func trackSessionStart(mode: TimerMode) {
        let event = AnalyticsEvent(
            type: .sessionStart,
            data: [
                "mode": mode.rawValue,
                "hour": String(Calendar.current.component(.hour, from: Date())),
                "day_of_week": String(Calendar.current.component(.weekday, from: Date()))
            ]
        )
        addEvent(event)
    }
    
    func trackSessionComplete(session: FocusSession) {
        let event = AnalyticsEvent(
            type: .sessionComplete,
            data: [
                "mode": session.mode.rawValue,
                "duration": String(session.duration),
                "completed": String(session.completed),
                "hour": String(Calendar.current.component(.hour, from: session.startedAt)),
                "day_of_week": String(Calendar.current.component(.weekday, from: session.startedAt))
            ]
        )
        addEvent(event)
    }
    
    func trackAchievementUnlocked(achievement: Achievement) {
        let event = AnalyticsEvent(
            type: .achievementUnlocked,
            data: [
                "achievement_id": achievement.id.uuidString,
                "achievement_title": achievement.title,
                "achievement_type": achievement.type.rawValue,
                "progress": String(achievement.progress),
                "target": String(achievement.target)
            ]
        )
        addEvent(event)
    }
    
    func trackSettingsChanged(setting: String, value: Any) {
        let event = AnalyticsEvent(
            type: .settingsChanged,
            data: [
                "setting": setting,
                "value": String(describing: value)
            ]
        )
        addEvent(event)
    }
    
    func trackModeChanged(from oldMode: AppMode, to newMode: AppMode) {
        let event = AnalyticsEvent(
            type: .modeChanged,
            data: [
                "from_mode": oldMode.rawValue,
                "to_mode": newMode.rawValue
            ]
        )
        addEvent(event)
    }
    
    private func trackAppLaunched() {
        let event = AnalyticsEvent(
            type: .appLaunched,
            data: [
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            ]
        )
        addEvent(event)
    }
    
    // MARK: - Analytics Generation
    
    func generateAnalyticsReport(for period: StatsPeriod) -> AnalyticsReport {
        let dateRange = period.dateRange
        let periodEvents = events.filter { 
            $0.timestamp >= dateRange.start && $0.timestamp <= dateRange.end 
        }
        
        return AnalyticsReport(
            period: period,
            generatedAt: Date(),
            totalEvents: periodEvents.count,
            sessionMetrics: generateSessionMetrics(from: periodEvents),
            usagePatterns: generateUsagePatterns(from: periodEvents),
            achievementMetrics: generateAchievementMetrics(from: periodEvents)
        )
    }
    
    private func generateSessionMetrics(from events: [AnalyticsEvent]) -> AnalyticsReport.SessionMetrics {
        let sessionEvents = events.filter { 
            $0.type == .sessionComplete || $0.type == .sessionStart 
        }
        
        let completedSessions = events.filter { 
            $0.type == .sessionComplete && $0.data["completed"] == "true" 
        }
        
        let skippedSessions = events.filter { 
            $0.type == .sessionComplete && $0.data["completed"] == "false" 
        }
        
        let totalFocusTime = completedSessions
            .compactMap { Double($0.data["duration"] ?? "0") }
            .reduce(0, +)
        
        let averageSessionLength = completedSessions.isEmpty ? 0 : 
            totalFocusTime / Double(completedSessions.count)
        
        let completionRate = sessionEvents.isEmpty ? 0 : 
            Double(completedSessions.count) / Double(sessionEvents.count) * 100
        
        // Find most productive day
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        
        let dayGroups = Dictionary(grouping: completedSessions) { event in
            dateFormatter.string(from: event.timestamp)
        }
        
        let mostProductiveDay = dayGroups.max { $0.value.count < $1.value.count }?.key
        
        return AnalyticsReport.SessionMetrics(
            totalSessions: sessionEvents.count,
            completedSessions: completedSessions.count,
            skippedSessions: skippedSessions.count,
            averageSessionLength: averageSessionLength,
            totalFocusTime: totalFocusTime,
            mostProductiveDay: mostProductiveDay,
            averageCompletionRate: completionRate
        )
    }
    
    private func generateUsagePatterns(from events: [AnalyticsEvent]) -> AnalyticsReport.UsagePatterns {
        let sessionEvents = events.filter { $0.type == .sessionStart }
        
        // Most active hour
        let hourGroups = Dictionary(grouping: sessionEvents) { event in
            Int(event.data["hour"] ?? "0") ?? 0
        }
        let mostActiveHour = hourGroups.max { $0.value.count < $1.value.count }?.key
        
        // Most active day of week
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        
        let dayGroups = Dictionary(grouping: sessionEvents) { event in
            dayFormatter.string(from: event.timestamp)
        }
        let mostActiveDayOfWeek = dayGroups.max { $0.value.count < $1.value.count }?.key
        
        // Average sessions per day
        let calendar = Calendar.current
        let dayGroups2 = Dictionary(grouping: sessionEvents) { event in
            calendar.startOfDay(for: event.timestamp)
        }
        let averageSessionsPerDay = dayGroups2.isEmpty ? 0 : 
            Double(sessionEvents.count) / Double(dayGroups2.count)
        
        // Peak usage times (hours with above-average activity)
        let averageHourlyActivity = Double(sessionEvents.count) / 24.0
        let peakUsageTimes = hourGroups.compactMap { hour, events in
            Double(events.count) > averageHourlyActivity ? hour : nil
        }.sorted()
        
        // Sessions by mode
        let modeGroups = Dictionary(grouping: sessionEvents) { event in
            event.data["mode"] ?? "unknown"
        }
        let sessionsByMode = modeGroups.mapValues { $0.count }
        
        return AnalyticsReport.UsagePatterns(
            mostActiveHour: mostActiveHour,
            mostActiveDayOfWeek: mostActiveDayOfWeek,
            averageSessionsPerDay: averageSessionsPerDay,
            peakUsageTimes: peakUsageTimes,
            sessionsByMode: sessionsByMode
        )
    }
    
    private func generateAchievementMetrics(from events: [AnalyticsEvent]) -> AnalyticsReport.AchievementMetrics {
        let achievementEvents = events.filter { $0.type == .achievementUnlocked }
        
        let recentUnlocks = achievementEvents
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(5)
            .compactMap { $0.data["achievement_title"] }
            .map { String($0) }
        
        // Progress towards next would require access to current achievements
        // This is a placeholder implementation
        let progressTowardsNext: [String: Double] = [:]
        
        return AnalyticsReport.AchievementMetrics(
            totalUnlocked: achievementEvents.count,
            recentUnlocks: recentUnlocks,
            progressTowardsNext: progressTowardsNext
        )
    }
    
    // MARK: - Data Management
    
    private func addEvent(_ event: AnalyticsEvent) {
        DispatchQueue.main.async {
            self.events.append(event)
            
            // Trim events if we exceed the limit
            if self.events.count > self.maxStoredEvents {
                self.events.removeFirst(self.events.count - self.maxStoredEvents)
            }
            
            self.saveEvents()
        }
    }
    
    private func saveEvents() {
        do {
            let data = try JSONEncoder().encode(events)
            userDefaults.set(data, forKey: eventsKey)
        } catch {
            print("📊 Error saving analytics events: \(error)")
        }
    }
    
    private func loadEvents() {
        guard let data = userDefaults.data(forKey: eventsKey) else { return }
        
        do {
            events = try JSONDecoder().decode([AnalyticsEvent].self, from: data)
            print("📊 Loaded \(events.count) analytics events")
        } catch {
            print("📊 Error loading analytics events: \(error)")
            events = []
        }
    }
    
    // MARK: - Utility Methods
    
    func clearAllEvents() {
        events.removeAll()
        userDefaults.removeObject(forKey: eventsKey)
        print("📊 All analytics events cleared")
    }
    
    func exportEvents() -> Data? {
        do {
            return try JSONEncoder().encode(events)
        } catch {
            print("📊 Error exporting events: \(error)")
            return nil
        }
    }
    
    func getAnalyticsInfo() -> String {
        let eventsByType = Dictionary(grouping: events) { $0.type }
        let typeInfo = eventsByType.map { type, events in
            "\(type.rawValue): \(events.count)"
        }.joined(separator: ", ")
        
        return """
        📊 Analytics Service Info:
        • Total Events: \(events.count)
        • Event Types: \(typeInfo)
        • Storage: \(events.count)/\(maxStoredEvents) events
        """
    }
}

// MARK: - Mock Service for Testing

class MockAnalyticsService: AnalyticsServiceProtocol {
    private(set) var trackedEvents: [AnalyticsEvent] = []
    
    func trackSessionStart(mode: TimerMode) {
        let event = AnalyticsEvent(type: .sessionStart, data: ["mode": mode.rawValue])
        trackedEvents.append(event)
    }
    
    func trackSessionComplete(session: FocusSession) {
        let event = AnalyticsEvent(type: .sessionComplete, data: ["mode": session.mode.rawValue])
        trackedEvents.append(event)
    }
    
    func trackAchievementUnlocked(achievement: Achievement) {
        let event = AnalyticsEvent(type: .achievementUnlocked, data: ["title": achievement.title])
        trackedEvents.append(event)
    }
    
    func trackSettingsChanged(setting: String, value: Any) {
        let event = AnalyticsEvent(type: .settingsChanged, data: ["setting": setting])
        trackedEvents.append(event)
    }
    
    func generateAnalyticsReport(for period: StatsPeriod) -> AnalyticsReport {
        return AnalyticsReport(
            period: period,
            generatedAt: Date(),
            totalEvents: trackedEvents.count,
            sessionMetrics: AnalyticsReport.SessionMetrics(
                totalSessions: 0,
                completedSessions: 0,
                skippedSessions: 0,
                averageSessionLength: 0,
                totalFocusTime: 0,
                mostProductiveDay: nil,
                averageCompletionRate: 0
            ),
            usagePatterns: AnalyticsReport.UsagePatterns(
                mostActiveHour: nil,
                mostActiveDayOfWeek: nil,
                averageSessionsPerDay: 0,
                peakUsageTimes: [],
                sessionsByMode: [:]
            ),
            achievementMetrics: AnalyticsReport.AchievementMetrics(
                totalUnlocked: 0,
                recentUnlocks: [],
                progressTowardsNext: [:]
            )
        )
    }
    
    func reset() {
        trackedEvents.removeAll()
    }
}
