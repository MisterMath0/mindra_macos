//
//  TimerManager.swift
//  MindraTimer
//
//  Refactored timer manager with clean architecture and service injection
//

import SwiftUI
import Foundation

class TimerManager: ObservableObject {
    // MARK: - Published State
    @Published var timerState: TimerState
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
        self.timerState = TimerState(
            timeRemaining: Int(SessionConfiguration.default.focusDuration),
            isActive: false,
            isPaused: false,
            currentMode: .focus,
            sessionsCompleted: 0,
            totalDuration: Int(SessionConfiguration.default.focusDuration)
        )
        
        loadPersistedState()
    }
    
    // MARK: - Dependency Injection
    
    func setStatsManager(_ statsManager: StatsManager) {
        self.statsManager = statsManager
        updateConfigurationFromSettings()
    }
    
    func setAudioService(_ audioService: AudioServiceProtocol) {
        self.audioService = audioService
    }
    
    func setAnalyticsService(_ analyticsService: AnalyticsServiceProtocol) {
        self.analyticsService = analyticsService
    }
    
    // MARK: - Public Timer Actions
    
    func startTimer() {
        guard !timerState.isActive else { return }
        
        timerState = TimerState(
            timeRemaining: timerState.timeRemaining,
            isActive: true,
            isPaused: false,
            currentMode: timerState.currentMode,
            sessionsCompleted: timerState.sessionsCompleted,
            totalDuration: timerState.totalDuration
        )
        
        // Start session tracking
        startSessionTracking()
        
        // Start timer
        startInternalTimer()
        
        // Track analytics
        analyticsService?.trackSessionStart(mode: timerState.currentMode)
        
        print("⏰ Timer started: \(timerState.currentMode.displayName)")
    }
    
    func pauseTimer() {
        guard timerState.isActive && !timerState.isPaused else { return }
        
        timerState = TimerState(
            timeRemaining: timerState.timeRemaining,
            isActive: false,
            isPaused: true,
            currentMode: timerState.currentMode,
            sessionsCompleted: timerState.sessionsCompleted,
            totalDuration: timerState.totalDuration
        )
        
        stopInternalTimer()
        statsManager?.pauseSession()
        
        print("⏸️ Timer paused")
    }
    
    func resumeTimer() {
        guard timerState.isPaused else { return }
        startTimer()
    }
    
    func resetTimer() {
        stopInternalTimer()
        endCurrentSession(completed: false)
        
        let newDuration = Int(sessionConfiguration.duration(for: timerState.currentMode))
        timerState = TimerState(
            timeRemaining: newDuration,
            isActive: false,
            isPaused: false,
            currentMode: timerState.currentMode,
            sessionsCompleted: timerState.sessionsCompleted,
            totalDuration: newDuration
        )
        
        print("🔄 Timer reset")
    }
    
    func skipTimer() {
        endCurrentSession(completed: false)
        completeCurrentCycle()
    }
    
    func setMode(_ mode: TimerMode) {
        guard !timerState.isActive else { return }
        
        let newDuration = Int(sessionConfiguration.duration(for: mode))
        timerState = TimerState(
            timeRemaining: newDuration,
            isActive: false,
            isPaused: false,
            currentMode: mode,
            sessionsCompleted: timerState.sessionsCompleted,
            totalDuration: newDuration
        )
        
        analyticsService?.trackSettingsChanged(setting: "timerMode", value: mode.rawValue)
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
        if mode == timerState.currentMode && !timerState.isActive {
            let newDuration = Int(duration)
            timerState = TimerState(
                timeRemaining: newDuration,
                isActive: timerState.isActive,
                isPaused: timerState.isPaused,
                currentMode: timerState.currentMode,
                sessionsCompleted: timerState.sessionsCompleted,
                totalDuration: newDuration
            )
        }
        
        saveConfiguration()
        analyticsService?.trackSettingsChanged(setting: "duration_\(mode.rawValue)", value: minutes)
    }
    
    // MARK: - Private Timer Implementation
    
    private func startInternalTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.tick()
            }
        }
    }
    
    private func stopInternalTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        guard timerState.timeRemaining > 0 else {
            handleTimerCompletion()
            return
        }
        
        timerState = TimerState(
            timeRemaining: timerState.timeRemaining - 1,
            isActive: timerState.isActive,
            isPaused: timerState.isPaused,
            currentMode: timerState.currentMode,
            sessionsCompleted: timerState.sessionsCompleted,
            totalDuration: timerState.totalDuration
        )
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
        
        print("✅ Timer completed: \(timerState.currentMode.displayName)")
    }
    
    private func completeCurrentCycle() {
        let wasInFocus = timerState.currentMode == .focus
        
        // Update sessions completed for focus sessions
        if wasInFocus {
            sessionsCompleted += 1
            savePersistedState()
        }
        
        // Determine next mode
        let nextMode = determineNextMode()
        
        // Update timer state
        let newDuration = Int(sessionConfiguration.duration(for: nextMode))
        timerState = TimerState(
            timeRemaining: newDuration,
            isActive: false,
            isPaused: false,
            currentMode: nextMode,
            sessionsCompleted: sessionsCompleted,
            totalDuration: newDuration
        )
    }
    
    private func determineNextMode() -> TimerMode {
        switch timerState.currentMode {
        case .focus:
            // After focus, decide between short and long break
            return (sessionsCompleted % sessionConfiguration.sessionsUntilLongBreak == 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            // After any break, return to focus
            return .focus
        }
    }
    
    private func shouldAutoStartNext() -> Bool {
        switch timerState.currentMode {
        case .focus:
            return sessionConfiguration.autoStartBreaks
        case .shortBreak, .longBreak:
            return sessionConfiguration.autoStartPomodoros
        }
    }
    
    // MARK: - Session Tracking
    
    private func startSessionTracking() {
        currentSessionId = statsManager?.startSession(
            mode: timerState.currentMode, 
            duration: timerState.totalDuration
        )
        sessionStartTime = Date()
    }
    
    private func endCurrentSession(completed: Bool) {
        guard let sessionId = currentSessionId else { return }
        
        if completed {
            statsManager?.completeSession(
                sessionId: sessionId,
                mode: timerState.currentMode,
                duration: timerState.totalDuration,
                completed: true
            )
        } else {
            statsManager?.resetSession()
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
        
        // Save session configuration
        if let configData = try? encoder.encode(sessionConfiguration) {
            UserDefaults.standard.set(configData, forKey: "sessionConfiguration")
        }
        
        // Save sessions completed
        UserDefaults.standard.set(sessionsCompleted, forKey: "sessionsCompleted")
        
        print("💾 Timer state persisted")
    }
    
    private func loadPersistedState() {
        let decoder = JSONDecoder()
        
        // Load session configuration
        if let configData = UserDefaults.standard.data(forKey: "sessionConfiguration"),
           let config = try? decoder.decode(SessionConfiguration.self, from: configData) {
            sessionConfiguration = config
        }
        
        // Load sessions completed
        sessionsCompleted = UserDefaults.standard.integer(forKey: "sessionsCompleted")
        
        // Update timer state with loaded configuration
        let duration = Int(sessionConfiguration.focusDuration)
        timerState = TimerState(
            timeRemaining: duration,
            isActive: false,
            isPaused: false,
            currentMode: .focus,
            sessionsCompleted: sessionsCompleted,
            totalDuration: duration
        )
        
        print("📖 Timer state loaded")
    }
    
    private func saveConfiguration() {
        savePersistedState()
    }
    
    private func updateConfigurationFromSettings() {
        // Update configuration from settings manager if available
        // This would be implemented when SettingsManager includes timer settings
    }
    
    // MARK: - Computed Properties (for backward compatibility)
    
    var timeRemaining: Int {
        return timerState.timeRemaining
    }
    
    var isActive: Bool {
        return timerState.isActive
    }
    
    var isPaused: Bool {
        return timerState.isPaused
    }
    
    var currentMode: TimerMode {
        return timerState.currentMode
    }
    
    var formattedTime: String {
        return timerState.formattedTime
    }
    
    var progress: Double {
        return timerState.progress
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
        • Mode: \(timerState.currentMode.displayName)
        • Time: \(timerState.formattedTime)
        • Active: \(timerState.isActive)
        • Paused: \(timerState.isPaused)
        • Progress: \(String(format: "%.1f", timerState.progress * 100))%
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
