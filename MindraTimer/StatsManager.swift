//
//  StatsManager.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 09.06.25.
//

import Foundation
import Combine

// MARK: - Stats Manager (integrating with existing SettingsManager)

class StatsManager: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var sessions: [FocusSession] = []
    @Published var summary: StatsSummary = StatsSummary(
        totalSessions: 0,
        totalFocusTime: 0,
        completedSessions: 0,
        completionRate: 0.0,
        averageSessionLength: 0,
        currentStreak: 0,
        bestStreak: 0,
        totalTasksCompleted: 0
    )
    @Published var chartData: [ChartData] = []
    
    // Use the existing SettingsManager instead of our own AppSettings
    @Published var settingsManager: SettingsManager
    
    private let database: DatabaseManager
    private var currentSessionId: String?
    private var sessionStartTime: Date?
    
    init() {
        self.database = DatabaseManager()
        self.settingsManager = SettingsManager()
        fetchStats(for: settingsManager.displayPeriod)
    }
    
    // MARK: - Computed Properties for easy access
    
    var settings: SettingsManager {
        return settingsManager
    }
    
    var hasActiveSessions: Bool {
        return !sessions.isEmpty
    }
    
    var todaysSessions: [FocusSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return sessions.filter { session in
            calendar.isDate(session.startedAt, inSameDayAs: today)
        }
    }
    
    var todaysFocusTime: Int {
        return todaysSessions
            .filter { $0.mode == .focus && $0.completed }
            .reduce(0) { $0 + ($1.duration / 60) }
    }
    
    var streakText: String {
        if summary.currentStreak == 0 {
            return "Start your streak!"
        } else if summary.currentStreak == 1 {
            return "1 day streak"
        } else {
            return "\(summary.currentStreak) day streak"
        }
    }
    
    // MARK: - Settings Bridge Methods (delegate to SettingsManager)
    
    func toggleAutoStartTimer() {
        settingsManager.autoStartTimer.toggle()
    }
    
    func toggleStreakCounter() {
        settingsManager.showStreakCounter.toggle()
    }
    
    func toggleSound() {
        settingsManager.soundEnabled.toggle()
    }
    
    func setSoundVolume(_ volume: Double) {
        settingsManager.soundVolume = max(0, min(100, Int(volume)))
    }
    
    func setSelectedSound(_ sound: String) {
        if let soundOption = SoundOption(rawValue: sound) {
            settingsManager.selectedSound = soundOption
        }
    }
    
    func toggleNotifications() {
        settingsManager.showNotifications.toggle()
    }
    
    func toggle24HourFormat() {
        settingsManager.use24HourFormat.toggle()
    }
    
    func toggleGreetings() {
        settingsManager.showGreetings.toggle()
    }
    
    func setDisplayPeriod(_ period: StatsPeriod) {
        settingsManager.displayPeriod = period
        fetchStats(for: period)
    }
    
    // MARK: - Session Management
    
    func startSession(mode: TimerMode, duration: Int) -> String {
        let sessionId = UUID().uuidString
        currentSessionId = sessionId
        sessionStartTime = Date()
        
        print("📱 Started \(mode.displayName) session: \(sessionId)")
        return sessionId
    }
    
    func completeSession(sessionId: String, mode: TimerMode, duration: Int, completed: Bool) {
        guard let startTime = sessionStartTime else {
            print("❌ No start time found for session completion")
            return
        }
        
        let endTime = Date()
        
        let session = FocusSession(
            id: sessionId,
            startedAt: startTime,
            endedAt: endTime,
            duration: duration,
            completed: completed,
            mode: mode
        )
        
        let success = database.addSession(session)
        print("💾 Session saved: \(success ? "✅" : "❌") - \(mode.displayName), completed: \(completed)")
        
        if success {
            // Clear session tracking
            currentSessionId = nil
            sessionStartTime = nil
            
            // Refresh stats
            fetchStats(for: settingsManager.displayPeriod)
        }
    }
    
    func pauseSession() {
        print("⏸️ Session paused")
    }
    
    func resetSession() {
        if let sessionId = currentSessionId, sessionStartTime != nil {
            print("🔄 Session reset - saving as incomplete")
        }
        
        currentSessionId = nil
        sessionStartTime = nil
    }
    
    func skipSession(sessionId: String, mode: TimerMode, duration: Int) {
        completeSession(sessionId: sessionId, mode: mode, duration: duration, completed: false)
        print("⏭️ Session skipped and saved as incomplete")
    }
    
    // MARK: - Data Fetching
    
    func fetchStats(for period: StatsPeriod) {
        isLoading = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let fetchedSessions = self.database.getSessions(for: period)
            let newSummary = self.database.calculateSummary(for: fetchedSessions)
            let newChartData = self.database.generateChartData(for: fetchedSessions, period: period)
            
            DispatchQueue.main.async {
                self.sessions = fetchedSessions
                self.summary = newSummary
                self.chartData = newChartData
                self.isLoading = false
                
                print("📊 Stats updated: \(fetchedSessions.count) sessions, \(newSummary.currentStreak) day streak")
            }
        }
    }
    
    // MARK: - Debug Methods
    
    func clearAllData() {
        sessions.removeAll()
        summary = StatsSummary(
            totalSessions: 0,
            totalFocusTime: 0,
            completedSessions: 0,
            completionRate: 0.0,
            averageSessionLength: 0,
            currentStreak: 0,
            bestStreak: 0,
            totalTasksCompleted: 0
        )
        chartData.removeAll()
        
        print("🗑️ All stats data cleared")
    }
    
    func addTestData() {
        let calendar = Calendar.current
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let session = FocusSession(
                    startedAt: date,
                    endedAt: calendar.date(byAdding: .minute, value: 25, to: date),
                    duration: 25 * 60,
                    completed: true,
                    mode: .focus
                )
                
                _ = database.addSession(session)
            }
        }
        
        fetchStats(for: settingsManager.displayPeriod)
        print("🧪 Test data added")
    }
}
