//
//  TimerManager.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 09.06.25.
//

import SwiftUI
import Foundation
import AVFoundation

enum TimerMode: String, CaseIterable {
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
        case .focus: return Color(red: 0.5, green: 0.3, blue: 0.9) // Purple
        case .shortBreak: return Color(red: 0.9, green: 0.5, blue: 0.7) // Pink
        case .longBreak: return Color(red: 0.3, green: 0.6, blue: 0.9) // Blue
        }
    }
}

class TimerManager: ObservableObject {
    // Timer state
    @Published var timeRemaining: Int = 25 * 60 // 25 minutes in seconds
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentMode: TimerMode = .focus
    @Published var sessionsCompleted: Int = 0
    
    // Timer durations (in seconds) - loaded from settings
    @Published var focusDuration: Int = 25 * 60 // 25 minutes
    @Published var shortBreakDuration: Int = 5 * 60 // 5 minutes
    @Published var longBreakDuration: Int = 10 * 60 // 10 minutes
    
    private var timer: Timer?
    private var statsManager: StatsManager?
    private var currentSessionId: String?
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        loadPersistedData()
        resetTimer()
    }
    
    // Inject stats manager after initialization
    func setStatsManager(_ statsManager: StatsManager) {
        self.statsManager = statsManager
        
        // Load durations from settings
        let settings = statsManager.settings
        updateDurationsFromSettings(settings)
    }
    
    // MARK: - Computed Properties
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        let totalDuration = currentModeDuration
        return totalDuration > 0 ? Double(totalDuration - timeRemaining) / Double(totalDuration) : 0
    }
    
    private var currentModeDuration: Int {
        switch currentMode {
        case .focus: return focusDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        }
    }
    
    // MARK: - Timer Actions (with stats integration)
    
    func startTimer() {
        isActive = true
        isPaused = false
        
        // Start session tracking
        if currentSessionId == nil {
            currentSessionId = statsManager?.startSession(mode: currentMode, duration: currentModeDuration)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.tick()
        }
    }
    
    func pauseTimer() {
        isPaused = true
        isActive = false
        timer?.invalidate()
        timer = nil
        
        statsManager?.pauseSession()
    }
    
    func resetTimer() {
        stopTimer()
        
        // Save as incomplete if there was an active session
        if currentSessionId != nil {
            statsManager?.resetSession()
            currentSessionId = nil
        }
        
        timeRemaining = currentModeDuration
    }
    
    func skipTimer() {
        // Save current session as incomplete
        if currentSessionId != nil {
            statsManager?.skipSession(sessionId: currentSessionId!, mode: currentMode, duration: currentModeDuration)
            currentSessionId = nil
        }
        
        stopTimer()
        cycleToNextMode()
    }
    
    private func stopTimer() {
        isActive = false
        isPaused = false
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            // Timer completed
            handleTimerCompletion()
        }
    }
    
    private func handleTimerCompletion() {
        stopTimer()
        
        // Complete the session
        if currentSessionId != nil {
            statsManager?.completeSession(
                sessionId: currentSessionId!,
                mode: currentMode,
                duration: currentModeDuration,
                completed: true
            )
            currentSessionId = nil
        }
        
        // Play completion sound
        playCompletionSound()
        
        // Update sessions completed for focus mode
        if currentMode == .focus {
            sessionsCompleted += 1
            savePersistedData()
        }
        
        // Cycle to next mode
        cycleToNextMode()
        
        // Auto-start next timer if enabled
        if statsManager?.settings.autoStartTimer == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startTimer()
            }
        }
    }
    
    private func cycleToNextMode() {
        switch currentMode {
        case .focus:
            // After focus, go to break (long break every 4 sessions)
            currentMode = (sessionsCompleted % 4 == 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            // After any break, go back to focus
            currentMode = .focus
        }
        
        // Reset timer for new mode
        timeRemaining = currentModeDuration
    }
    
    // MARK: - Settings Management
    
    func updateDuration(for mode: TimerMode, minutes: Int) {
        let seconds = minutes * 60
        switch mode {
        case .focus:
            focusDuration = seconds
        case .shortBreak:
            shortBreakDuration = seconds
        case .longBreak:
            longBreakDuration = seconds
        }
        
        // If we're updating the current mode, update remaining time
        if mode == currentMode && !isActive {
            timeRemaining = seconds
        }
        
        // Save to settings via stats manager
        saveDurationsToSettings()
    }
    
    func setMode(_ mode: TimerMode) {
        if !isActive {
            currentMode = mode
            timeRemaining = currentModeDuration
        }
    }
    
    private func updateDurationsFromSettings(_ settings: SettingsManager) {
        // Future: extend SettingsManager to include timer durations
        // For now, using defaults but this structure is ready for expansion
    }
    
    private func saveDurationsToSettings() {
        // Future: extend SettingsManager to save timer durations
        // For now, we save to UserDefaults directly
        savePersistedData()
    }
    
    // MARK: - Persistence (local session state)
    
    private func savePersistedData() {
        UserDefaults.standard.set(focusDuration, forKey: "focusDuration")
        UserDefaults.standard.set(shortBreakDuration, forKey: "shortBreakDuration")
        UserDefaults.standard.set(longBreakDuration, forKey: "longBreakDuration")
        UserDefaults.standard.set(sessionsCompleted, forKey: "sessionsCompleted")
    }
    
    private func loadPersistedData() {
        focusDuration = UserDefaults.standard.object(forKey: "focusDuration") as? Int ?? 25 * 60
        shortBreakDuration = UserDefaults.standard.object(forKey: "shortBreakDuration") as? Int ?? 5 * 60
        longBreakDuration = UserDefaults.standard.object(forKey: "longBreakDuration") as? Int ?? 10 * 60
        sessionsCompleted = UserDefaults.standard.integer(forKey: "sessionsCompleted")
    }
    
    // MARK: - Sound System (matching your implementation)
    
    private func playCompletionSound() {
        guard let statsManager = statsManager,
              statsManager.settings.soundEnabled else {
            return
        }
        
        let soundName = statsManager.settings.selectedSound.rawValue
        playSound(named: soundName)
    }
    
    private func playSound(named soundName: String) {
        // Try to find the sound file in the bundle
        var soundFileName = soundName
        
        // Map sound names to actual file names
        switch soundName {
        case "sparkle":
            soundFileName = "sparkle"
        case "chime":
            soundFileName = "chime"
        case "bellSoft":
            soundFileName = "bell-soft"
        case "bellLoud":
            soundFileName = "bell-loud"
        case "trainArrival":
            soundFileName = "train-arrival"
        case "commuterJingle":
            soundFileName = "commuter-jingle"
        default:
            // Fallback to system sound
            NSSound.beep()
            return
        }
        
        // Try to load and play the sound file from the bundle
        if let url = Bundle.main.url(forResource: soundFileName, withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.volume = Float(statsManager?.settings.soundVolume ?? 70) / 100.0
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error)")
                // Fallback to system sound if file not found
                NSSound.beep()
            }
        } else {
            print("Sound file not found: \(soundFileName).mp3")
            print("Bundle path: \(Bundle.main.bundlePath)")
            // Fallback to system sound
            NSSound.beep()
        }
    }
    
    // MARK: - Debug Methods
    
    func getDebugInfo() -> String {
        return """
        Timer Debug Info:
        - Current Mode: \(currentMode.displayName)
        - Time Remaining: \(formattedTime)
        - Is Active: \(isActive)
        - Is Paused: \(isPaused)
        - Sessions Completed: \(sessionsCompleted)
        - Current Session ID: \(currentSessionId ?? "none")
        - Progress: \(String(format: "%.1f", progress * 100))%
        """
    }
}
