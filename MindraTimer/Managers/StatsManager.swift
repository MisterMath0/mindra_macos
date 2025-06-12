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
    @Published private(set) var achievements: [Achievement] = []
    
    let database: DatabaseManager  // Made public for debugging
    private var currentSessionId: String?
    private var sessionStartTime: Date?
    
    init() {
        self.database = DatabaseManager.shared  // Use singleton instead
        self.settingsManager = SettingsManager()
        
        // Load existing data
        fetchStats(for: settingsManager.displayPeriod)
        loadAchievements()
        
        print("📊 Stats Manager initialized")
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
    
    // MARK: - Achievement Management
    
    private func loadAchievements() {
        achievements = database.getAchievements()
        print("🏆 Loaded \(achievements.count) achievements from database")
    }
    
    // MARK: - One-time setup methods (call manually when needed)
    
    func initializeDefaultAchievements() {
        print("🔄 Initializing default achievements...")
        let defaultAchievements = createDefaultAchievements()
        
        for achievement in defaultAchievements {
            if database.addAchievement(achievement) {
                print("✅ Created achievement: \(achievement.title)")
            } else {
                print("❌ Failed to create achievement: \(achievement.title)")
            }
        }
        
        // Reload achievements from database
        loadAchievements()
        print("✅ Default achievements initialization complete")
    }
    
    private func createDefaultAchievements() -> [Achievement] {
        return [
            Achievement(
                id: UUID(),
                title: "First Focus",
                description: "Complete your first focus session",
                icon: "🎯",
                type: .sessionsCompleted,
                progress: 0,
                target: 1,
                unlocked: false,
                unlockedDate: nil
            ),
            Achievement(
                id: UUID(),
                title: "Focus Master",
                description: "Complete 10 focus sessions",
                icon: "🏆",
                type: .sessionsCompleted,
                progress: 0,
                target: 10,
                unlocked: false,
                unlockedDate: nil
            ),
            Achievement(
                id: UUID(),
                title: "Time Keeper",
                description: "Focus for 2 hours total",
                icon: "⏰",
                type: .totalFocusTime,
                progress: 0,
                target: 120, // 2 hours in minutes
                unlocked: false,
                unlockedDate: nil
            ),
            Achievement(
                id: UUID(),
                title: "Streak Starter",
                description: "Maintain a 3-day focus streak",
                icon: "🔥",
                type: .streak,
                progress: 0,
                target: 3,
                unlocked: false,
                unlockedDate: nil
            ),
            Achievement(
                id: UUID(),
                title: "Perfect Week",
                description: "Focus every day for a week",
                icon: "🌟",
                type: .perfectWeek,
                progress: 0,
                target: 7,
                unlocked: false,
                unlockedDate: nil
            ),
            Achievement(
                id: UUID(),
                title: "Marathon Focus",
                description: "Focus for 10 hours total",
                icon: "🏃‍♂️",
                type: .totalFocusTime,
                progress: 0,
                target: 600, // 10 hours in minutes
                unlocked: false,
                unlockedDate: nil
            ),
            Achievement(
                id: UUID(),
                title: "Consistency Champion",
                description: "Maintain a 30-day focus streak",
                icon: "👑",
                type: .streak,
                progress: 0,
                target: 30,
                unlocked: false,
                unlockedDate: nil
            ),
            Achievement(
                id: UUID(),
                title: "Century Club",
                description: "Complete 100 focus sessions",
                icon: "💯",
                type: .sessionsCompleted,
                progress: 0,
                target: 100,
                unlocked: false,
                unlockedDate: nil
            )
        ]
    }
    
    func updateAchievementProgress(type: Achievement.AchievementType, progress: Double) {
        for index in achievements.indices {
            if achievements[index].type == type {
                var achievement = achievements[index]
                
                // Handle different progress update strategies
                switch type {
                case .sessionsCompleted, .totalFocusTime, .marathon:
                    // Accumulate progress for these types
                    achievement.progress += progress
                case .streak, .consistency:
                    // Set progress to current value (not accumulative)
                    achievement.progress = progress
                case .perfectWeek, .perfectMonth, .earlyBird, .nightOwl, .weekendWarrior:
                    // These will need special handling based on specific logic
                    achievement.progress = max(achievement.progress, progress)
                }
                
                // Check if achievement should be unlocked
                if achievement.isCompleted && !achievement.unlocked {
                    achievement.unlocked = true
                    achievement.unlockedDate = Date()
                    print("🎉 Achievement unlocked: \(achievement.title)")
                    // TODO: Show achievement unlocked notification
                }
                
                if database.updateAchievement(achievement) {
                    achievements[index] = achievement
                    print("✅ Updated achievement: \(achievement.title) - Progress: \(achievement.progress)/\(achievement.target)")
                } else {
                    print("❌ Failed to update achievement: \(achievement.title)")
                }
            }
        }
    }
    
    func unlockAchievement(id: UUID) {
        if let index = achievements.firstIndex(where: { $0.id == id }) {
            var achievement = achievements[index]
            achievement.unlocked = true
            achievement.unlockedDate = Date()
            
            if database.updateAchievement(achievement) {
                achievements[index] = achievement
                // TODO: Show achievement unlocked notification
            }
        }
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
            
            // Update session completion
            if database.updateSessionCompletion(sessionId: sessionId, completed: completed) {
                // Update achievements based on session completion
                if completed && mode == .focus {
                    // Increment sessions completed count in database
                    incrementSessionsCompleted()
                    
                    // Update focus time achievement (accumulate total time)
                    updateAchievementProgress(type: .totalFocusTime, progress: Double(duration) / 60.0)
                    
                    // Update sessions completed achievement (increment by 1)
                    updateAchievementProgress(type: .sessionsCompleted, progress: 1.0)
                    
                    // Update streak achievement (set to current streak)
                    if let streak = calculateCurrentStreak() {
                        updateAchievementProgress(type: .streak, progress: Double(streak))
                    }
                    
                    print("📊 Achievement progress updated for completed focus session")
                }
            }
        }
    }
    
    func pauseSession() {
        print("⏸️ Session paused")
    }
    
    func resetSession() {
        if currentSessionId != nil, sessionStartTime != nil {
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
        // Clear database
        database.clearAllData()
        
        // Clear in-memory data
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
        achievements.removeAll()
        
        // Reinitialize achievements
        initializeDefaultAchievements()
        
        print("🗑️ All stats data cleared and reset")
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
        
        // Update achievements based on test data
        updateAchievementProgress(type: .sessionsCompleted, progress: 7.0) // 7 sessions
        updateAchievementProgress(type: .totalFocusTime, progress: 175.0) // 7 * 25 minutes
        updateAchievementProgress(type: .streak, progress: 7.0) // 7 day streak
        
        print("🧪 Test data added and achievements updated")
    }
    
    // Calculate current streak for achievement tracking
    private func calculateCurrentStreak() -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get all completed sessions
        let completedSessions = sessions.filter { $0.completed && $0.mode == .focus }
        
        // Sort sessions by date
        let sortedSessions = completedSessions.sorted { $0.startedAt > $1.startedAt }
        
        // If no sessions, return 0
        guard !sortedSessions.isEmpty else { return 0 }
        
        // Check if the most recent session was today
        let mostRecentSession = sortedSessions[0]
        if !calendar.isDate(mostRecentSession.startedAt, inSameDayAs: today) {
            return 0
        }
        
        // Calculate streak
        var streak = 1
        var currentDate = today
        
        for session in sortedSessions.dropFirst() {
            let sessionDate = calendar.startOfDay(for: session.startedAt)
            let daysBetween = calendar.dateComponents([.day], from: sessionDate, to: currentDate).day ?? 0
            
            if daysBetween == 1 {
                streak += 1
                currentDate = sessionDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Debug Methods
    
    func debugAchievements() {
        print("🏆 Achievements Debug Info:")
        print("   Total achievements: \(achievements.count)")
        for achievement in achievements {
            let status = achievement.unlocked ? "✅ UNLOCKED" : "🔒 Locked"
            print("   \(achievement.icon) \(achievement.title): \(achievement.progress)/\(achievement.target) \(status)")
        }
    }
    
    func debugStats() {
        print("📊 Stats Debug Info:")
        print("   Total Sessions: \(summary.totalSessions)")
        print("   Completed Sessions: \(summary.completedSessions)")
        print("   Total Focus Time: \(summary.totalFocusTime) minutes")
        print("   Current Streak: \(summary.currentStreak) days")
        print("   Completion Rate: \(String(format: "%.1f", summary.completionRate))%")
        
        // Check database integrity
        print("   Database Path: \(database.dbPath)")
        let testSession = FocusSession(startedAt: Date(), duration: 60, completed: true, mode: .focus)
        let canWrite = database.addSession(testSession)
        print("   Database Write Test: \(canWrite ? "✅ OK" : "❌ FAILED")")
    }
    
    func forceRefreshAchievements() {
        print("🔄 Force refreshing achievements...")
        loadAchievements()
        print("✅ Achievements refresh complete: \(achievements.count) achievements loaded")
    }
    
    // MARK: - Simplified session tracking (no UserDefaults migration)
    
    var sessionsCompletedCount: Int {
        return summary.completedSessions
    }
    
    private func incrementSessionsCompleted() {
        // This is now handled automatically through the summary calculation
        print("📊 Session completion tracked in summary")
    }
}
