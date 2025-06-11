//
//  Models.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 09.06.25.
//

import SwiftUI
import Foundation

// This file is currently empty as TimerMode has been moved to TimerManager.swift

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
    
    enum AchievementType: String, Codable {
        case totalFocusTime
        case streak
        case sessionsCompleted
        case perfectWeek
        case perfectMonth
        case earlyBird
        case nightOwl
        case weekendWarrior
    }
    
    var progressPercentage: Double {
        return (progress / target) * 100
    }
    
    var isCompleted: Bool {
        return progress >= target
    }
}

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

struct PomodoroSession: Codable, Identifiable {
    let id: UUID
    let userId: String?
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval
    let type: SessionType
    let completed: Bool
    let notes: String?
    
    enum SessionType: String, Codable {
        case focus
        case shortBreak
        case longBreak
    }
    
    init(id: UUID = UUID(),
         userId: String? = nil,
         startTime: Date = Date(),
         endTime: Date? = nil,
         duration: TimeInterval,
         type: SessionType,
         completed: Bool = false,
         notes: String? = nil) {
        self.id = id
        self.userId = userId
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.type = type
        self.completed = completed
        self.notes = notes
    }
    
    var isCompleted: Bool {
        return completed && endTime != nil
    }
    
    var actualDuration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        }
        return duration
    }
}
