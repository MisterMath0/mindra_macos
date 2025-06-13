//
//  TimerManager.swift
//  MindraTimer
//
//  Refactored timer manager with clean architecture and service injection
//

import SwiftUI
import Foundation

class TimerManager: ObservableObject {
    // MARK: - Published State - FIXED: Direct properties instead of TimerState wrapper
    @Published var timeRemaining: Int = 0
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentMode: TimerMode = .focus
    @Published var totalDuration: Int = 0
    @Published var sessionConfiguration: SessionConfiguration
    @Published var sessionsCompleted: Int = 0
    
    // MARK: - Dependencies
    private var statsManager: StatsManager?
    private var audioService: AudioServiceProtocol?
    private var analyticsService: AnalyticsServiceProtocol?
    
    // MARK: - Private State
    private var timer: Timer?
    private var currentSessionId: String?
    private var sessionStartTime: Date?
    
    // MARK: - Initialization
    
    init() {
        self.sessionConfiguration = SessionConfiguration.default
        self.timeRemaining = Int(SessionConfiguration.default.focusDuration)
        self.totalDuration = Int(SessionConfiguration.default.focusDuration)
        self.isActive = false
        self.isPaused = false
        self.currentMode = .focus
        
        loadPersistedState()
    }
    
    // MARK: - Dependency Injection
    
    func setStatsManager(_ statsManager: StatsManager) {
        self.statsManager = statsManager
        updateConfigurationFromSettings()
        syncSessionsFromDatabase()
    }
    
    func setAudioService(_ audioService: AudioServiceProtocol) {
        self.audioService = audioService
    }
    
    func setAnalyticsService(_ analyticsService: AnalyticsServiceProtocol) {
        self.analyticsService = analyticsService
    }
    
    // MARK: - Public Timer Actions
    
    func startTimer() {
        print("🟢 StartTimer called - isActive: \(isActive), isPaused: \(isPaused)")
        
        // Check if we're resuming from pause
        if isPaused {
            resumeTimer()
            return
        }
        
        guard !isActive else { 
            print("⚠️ Timer already active, ignoring start request")
            return 
        }
        
        isActive = true
        isPaused = false
        
        // Start session tracking
        startSessionTracking()
        
        // Start timer
        startInternalTimer()
        
        // Track analytics
        analyticsService?.trackSessionStart(mode: currentMode)
        
        print("✅ Timer started: \(currentMode.displayName)")
    }
    
    func pauseTimer() {
        print("🟡 PauseTimer called - isActive: \(isActive), isPaused: \(isPaused)")
        guard isActive && !isPaused else { 
            print("⚠️ Timer not in pausable state")
            return 
        }
        
        isActive = false
        isPaused = true
        
        stopInternalTimer()
        statsManager?.pauseSession()
        
        print("✅ Timer paused")
    }
    
    func resumeTimer() {
        print("🔵 ResumeTimer called - isActive: \(isActive), isPaused: \(isPaused)")
        guard isPaused else { 
            print("⚠️ Timer not paused, cannot resume")
            return 
        }
        
        // FIXED: Don't call startTimer(), directly resume
        isActive = true
        isPaused = false
        
        // Resume session tracking if needed
        if currentSessionId == nil {
            startSessionTracking()
        }
        
        // Start timer without creating new session
        startInternalTimer()
        
        print("✅ Timer resumed")
    }
    
    // FIXED: NEW METHOD - Central toggle logic
    func toggleTimer() {
        print("🔄 ToggleTimer called - isActive: \(isActive), isPaused: \(isPaused)")
        
        if isActive && !isPaused {
            pauseTimer()
        } else if isPaused {
            resumeTimer()
        } else {
            startTimer()
        }
    }
    
    func resetTimer() {
        stopInternalTimer()
        endCurrentSession(completed: false)
        
        let newDuration = Int(sessionConfiguration.duration(for: currentMode))
        timeRemaining = newDuration
        isActive = false
        isPaused = false
        totalDuration = newDuration
        
        print("🔄 Timer reset")
    }
    
    func skipTimer() {
        print("⏭️ SkipTimer called - Current state: active=\(isActive), paused=\(isPaused), mode=\(currentMode.displayName)")
        
        // Store the current timer state before skipping
        let wasActive = isActive
        let wasPaused = isPaused
        
        // End current session
        endCurrentSession(completed: false)
        
        // Determine next mode
        let wasInFocus = currentMode == .focus
        
        // Update sessions completed for focus sessions
        if wasInFocus {
            // DON'T increment locally - wait for database sync
            // Let StatsManager handle the session tracking
            
            // Refresh session count from database after skip
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.syncSessionsFromDatabase()
            }
        }
        
        // Get next mode
        let nextMode = determineNextMode()
        
        // Update to next mode with new duration
        let newDuration = Int(sessionConfiguration.duration(for: nextMode))
        timeRemaining = newDuration
        currentMode = nextMode
        totalDuration = newDuration
        
        // CRITICAL FIX: Preserve timer state (running/paused) after skip
        if wasActive && !wasPaused {
            // Timer was running - keep it running with new mode
            isActive = true
            isPaused = false
            // Restart the internal timer with new duration
            startInternalTimer()
            // Start tracking for new mode
            startSessionTracking()
            print("✅ Timer skipped to \(nextMode.displayName) - CONTINUING to run")
        } else if wasPaused {
            // Timer was paused - keep it paused with new mode  
            isActive = false
            isPaused = true
            print("✅ Timer skipped to \(nextMode.displayName) - REMAINING paused")
        } else {
            // Timer was stopped - keep it stopped with new mode
            isActive = false
            isPaused = false
            print("✅ Timer skipped to \(nextMode.displayName) - REMAINING stopped")
        }
    }
    
    func setMode(_ mode: TimerMode) {
        print("🔄 SetMode called: \(mode.displayName) - Current state: active=\(isActive), paused=\(isPaused)")
        
        // FIXED: Allow mode changes but stop timer if running
        if isActive {
            print("⚠️ Timer is active, stopping before mode change")
            stopInternalTimer()
            endCurrentSession(completed: false)
        }
        
        let newDuration = Int(sessionConfiguration.duration(for: mode))
        timeRemaining = newDuration
        isActive = false
        isPaused = false
        currentMode = mode
        totalDuration = newDuration
        
        analyticsService?.trackSettingsChanged(setting: "timerMode", value: mode.rawValue)
        print("✅ Mode changed to: \(mode.displayName)")
    }
    
    // MARK: - Configuration Management
    
    func updateDuration(for mode: TimerMode, minutes: Int) {
        let duration = TimeInterval(minutes * 60)
        
        var newConfig = sessionConfiguration
        switch mode {
        case .focus:
            newConfig = SessionConfiguration(
                focusDuration: duration,
                shortBreakDuration: sessionConfiguration.shortBreakDuration,
                longBreakDuration: sessionConfiguration.longBreakDuration,
                sessionsUntilLongBreak: sessionConfiguration.sessionsUntilLongBreak,
                autoStartBreaks: sessionConfiguration.autoStartBreaks,
                autoStartPomodoros: sessionConfiguration.autoStartPomodoros
            )
        case .shortBreak:
            newConfig = SessionConfiguration(
                focusDuration: sessionConfiguration.focusDuration,
                shortBreakDuration: duration,
                longBreakDuration: sessionConfiguration.longBreakDuration,
                sessionsUntilLongBreak: sessionConfiguration.sessionsUntilLongBreak,
                autoStartBreaks: sessionConfiguration.autoStartBreaks,
                autoStartPomodoros: sessionConfiguration.autoStartPomodoros
            )
        case .longBreak:
            newConfig = SessionConfiguration(
                focusDuration: sessionConfiguration.focusDuration,
                shortBreakDuration: sessionConfiguration.shortBreakDuration,
                longBreakDuration: duration,
                sessionsUntilLongBreak: sessionConfiguration.sessionsUntilLongBreak,
                autoStartBreaks: sessionConfiguration.autoStartBreaks,
                autoStartPomodoros: sessionConfiguration.autoStartPomodoros
            )
        }
        
        sessionConfiguration = newConfig
        
        // Update current timer if we're changing the active mode
        if mode == currentMode && !isActive {
            let newDuration = Int(duration)
            timeRemaining = newDuration
            totalDuration = newDuration
        }
        
        saveConfiguration()
        analyticsService?.trackSettingsChanged(setting: "duration_\(mode.rawValue)", value: minutes)
    }
    
    // MARK: - Private Timer Implementation
    
    private func startInternalTimer() {
        // CRITICAL FIX: Always stop existing timer before creating new one
        stopInternalTimer()
        
        print("🕑 Creating new timer instance")
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.tick()
            }
        }
    }
    
    private func stopInternalTimer() {
        if timer != nil {
            print("🛑 Stopping timer instance")
            timer?.invalidate()
            timer = nil
        } else {
            print("🔍 No timer to stop")
        }
    }
    
    @MainActor
    private func tick() {
        guard timeRemaining > 0 else {
            handleTimerCompletion()
            return
        }
        
        timeRemaining -= 1
        
        // Debug: Log every 10 seconds
        if timeRemaining % 10 == 0 {
            print("⏱️ Timer tick: \(formattedTime) remaining")
        }
    }
    
    private func handleTimerCompletion() {
        stopInternalTimer()
        
        // Complete session tracking
        endCurrentSession(completed: true)
        
        // Play completion sound
        playCompletionSound()
        
        // Update session count and cycle to next mode
        completeCurrentCycle()
        
        // Auto-start next timer if enabled
        if shouldAutoStartNext() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.startTimer()
            }
        }
        
        print("✅ Timer completed: \(currentMode.displayName)")
    }
    
    private func completeCurrentCycle() {
        let wasInFocus = currentMode == .focus
        
        // Update sessions completed for focus sessions
        if wasInFocus {
            // DON'T increment locally - wait for database sync
            // sessionsCompleted will be updated after database write
            
            // Refresh session count from database after completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.syncSessionsFromDatabase()
            }
        }
        
        // Determine next mode
        let nextMode = determineNextMode()
        
        // Update timer state
        let newDuration = Int(sessionConfiguration.duration(for: nextMode))
        timeRemaining = newDuration
        isActive = false
        isPaused = false
        currentMode = nextMode
        totalDuration = newDuration
    }
    
    private func determineNextMode() -> TimerMode {
        switch currentMode {
        case .focus:
            // After focus, decide between short and long break
            // We need to get the actual completed sessions count from the database
            let actualSessionsCompleted = statsManager?.getSessionsToday() ?? sessionsCompleted
            let sessionsBeforeLongBreak = sessionConfiguration.sessionsUntilLongBreak
            
            // Check if it's time for a long break
            if actualSessionsCompleted > 0 && actualSessionsCompleted % sessionsBeforeLongBreak == 0 {
                return .longBreak
            } else {
                return .shortBreak
            }
        case .shortBreak, .longBreak:
            // After any break, return to focus
            return .focus
        }
    }
    
    private func shouldAutoStartNext() -> Bool {
        switch currentMode {
        case .focus:
            return sessionConfiguration.autoStartBreaks
        case .shortBreak, .longBreak:
            return sessionConfiguration.autoStartPomodoros
        }
    }
    
    // MARK: - Session Tracking
    
    private func startSessionTracking() {
        currentSessionId = statsManager?.startSession(
            mode: currentMode, 
            duration: totalDuration
        )
        sessionStartTime = Date()
    }
    
    private func endCurrentSession(completed: Bool) {
        guard let sessionId = currentSessionId,
              let startTime = sessionStartTime else { return }
        
        // Calculate actual duration based on time elapsed
        let actualDuration = Int(Date().timeIntervalSince(startTime))
        
        // Only save to database if this was a focus session
        if currentMode == .focus {
            statsManager?.completeSession(
                sessionId: sessionId,
                mode: currentMode,
                duration: actualDuration,
                completed: completed
            )
        } else {
            // For breaks, just log but don't save to database
            print("🏖️ Break session ended: \(currentMode.displayName)")
        }
        
        currentSessionId = nil
        sessionStartTime = nil
    }
    
    // MARK: - Audio
    
    private func playCompletionSound() {
        guard let statsManager = statsManager,
              statsManager.settings.soundEnabled,
              let audioService = audioService else {
            return
        }
        
        let volume = Float(statsManager.settings.soundVolume) / 100.0
        audioService.playSound(statsManager.settings.selectedSound, volume: volume)
    }
    
    // MARK: - Persistence
    
    private func savePersistedState() {
        let encoder = JSONEncoder()
        
        // Save session configuration ONLY (not session counts)
        if let configData = try? encoder.encode(sessionConfiguration) {
            UserDefaults.standard.set(configData, forKey: "sessionConfiguration")
        }
        
        // DO NOT save sessionsCompleted to UserDefaults - use database!
        // The session count should come from StatsManager/Database
        
        print("💾 Timer configuration persisted (sessions tracked in database)")
    }
    
    private func loadPersistedState() {
        let decoder = JSONDecoder()
        
        // Load session configuration
        if let configData = UserDefaults.standard.data(forKey: "sessionConfiguration"),
           let config = try? decoder.decode(SessionConfiguration.self, from: configData) {
            sessionConfiguration = config
        }
        
        // DO NOT load sessionsCompleted from UserDefaults
        // Instead, get it from StatsManager when available
        sessionsCompleted = 0  // Will be updated from database
        
        // Update timer state with loaded configuration
        let duration = Int(sessionConfiguration.focusDuration)
        timeRemaining = duration
        isActive = false
        isPaused = false
        currentMode = .focus
        totalDuration = duration
        
        print("📖 Timer configuration loaded (sessions will sync from database)")
    }
    
    private func saveConfiguration() {
        savePersistedState()
    }
    
    private func updateConfigurationFromSettings() {
        // Update configuration from settings manager if available
        // This would be implemented when SettingsManager includes timer settings
    }
    
    private func syncSessionsFromDatabase() {
        guard let statsManager = statsManager else { return }
        
        // Get today's completed focus sessions from database
        let todaysSessions = statsManager.getSessionsToday()
        
        // Update sessions completed to match database
        sessionsCompleted = todaysSessions
        
        print("🔄 Synced sessions from database: \(sessionsCompleted) sessions today")
    }
    
    // MARK: - Computed Properties
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(totalDuration - timeRemaining) / Double(totalDuration)
    }
    
    var focusDuration: Int {
        return Int(sessionConfiguration.focusDuration)
    }
    
    var shortBreakDuration: Int {
        return Int(sessionConfiguration.shortBreakDuration)
    }
    
    var longBreakDuration: Int {
        return Int(sessionConfiguration.longBreakDuration)
    }
    
    // MARK: - Debug
    
    func getDebugInfo() -> String {
        return """
        ⏰ Timer Manager Debug Info:
        
        State:
        • Mode: \(currentMode.displayName)
        • Time: \(formattedTime)
        • Active: \(isActive)
        • Paused: \(isPaused)
        • Progress: \(String(format: "%.1f", progress * 100))%
        • Sessions: \(sessionsCompleted)
        
        Configuration:
        • Focus: \(Int(sessionConfiguration.focusDuration / 60))min
        • Short Break: \(Int(sessionConfiguration.shortBreakDuration / 60))min
        • Long Break: \(Int(sessionConfiguration.longBreakDuration / 60))min
        • Auto-start: \(sessionConfiguration.autoStartBreaks)
        
        Session:
        • ID: \(currentSessionId ?? "none")
        • Start: \(sessionStartTime?.description ?? "none")
        
        Services:
        • Stats: \(statsManager != nil ? "✅" : "❌")
        • Audio: \(audioService != nil ? "✅" : "❌")
        • Analytics: \(analyticsService != nil ? "✅" : "❌")
        """
    }
}
