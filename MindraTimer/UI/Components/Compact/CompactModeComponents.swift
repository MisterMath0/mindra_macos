//
//  CompactModeComponents.swift
//  MindraTimer
//
//  🚀 CLEAN COMPACT MODE COMPONENTS
//  Fixed sizing, removed unwanted behaviors
//

import SwiftUI

// MARK: - Progress Bar

struct ProgressBarView: View {
    let geometry: GeometryProxy
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        timerManager.currentMode.color,
                        timerManager.currentMode.color.opacity(0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 2)
            .scaleEffect(x: timerManager.progress, y: 1, anchor: .leading)
            .animation(.easeInOut(duration: 1), value: timerManager.progress)
    }
}

// MARK: - Compact Timer View

struct CompactTimerView: View {
    let geometry: GeometryProxy
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        VStack(spacing: 16) {
            // MODE INDICATOR
            Text(timerManager.currentMode.displayName.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(timerManager.currentMode.color)
                .tracking(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(timerManager.currentMode.color.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(timerManager.currentMode.color.opacity(0.3), lineWidth: 1)
                        )
                )
                .animation(.easeInOut(duration: 0.3), value: timerManager.currentMode)
            
            // TIMER DISPLAY - Fixed responsive sizing
            Text(timerManager.formattedTime)
                .font(.system(size: min(geometry.size.width * 0.25, 60), weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(1)
                .shadow(color: timerManager.currentMode.color.opacity(0.3), radius: 4, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.2), value: timerManager.formattedTime)
            
            // CONTROL BUTTON
            CompactControlButton(geometry: geometry)
                .environmentObject(timerManager)
        }
    }
}

// MARK: - Compact Clock View

struct CompactClockView: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 8) {
            // GREETING
            Text(getSmartGreeting())
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .textCase(.uppercase)
                .tracking(0.5)
                .animation(.easeInOut(duration: 0.5), value: getSmartGreeting())
            
            // TIME - Fixed responsive sizing
            Text(getCurrentTime())
                .font(.system(size: min(geometry.size.width * 0.20, 48), weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(1)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .animation(.easeInOut(duration: 0.3), value: getCurrentTime())
            
            // DATE
            Text(getCompactDate())
                .font(.system(size: min(geometry.size.width * 0.08, 12), weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.3)
                .animation(.easeInOut(duration: 0.3), value: getCompactDate())
        }
    }
    
    private func getSmartGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: Date())
    }
    
    private func getCompactDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Compact Control Button

struct CompactControlButton: View {
    let geometry: GeometryProxy
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        Button(action: {
            timerManager.toggleTimer()
        }) {
            HStack(spacing: 6) {
                Image(systemName: timerManager.isActive && !timerManager.isPaused ? "pause.fill" : "play.fill")
                    .font(.system(size: 12, weight: .bold))
                
                Text(timerManager.isActive && !timerManager.isPaused ? "Pause" : "Start")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                timerManager.currentMode.color,
                                timerManager.currentMode.color.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: timerManager.currentMode.color.opacity(0.4), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: timerManager.isActive)
    }
}

// MARK: - Status Row

struct CompactStatusRowView: View {
    let geometry: GeometryProxy
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var appModeManager: AppModeManager
    
    var body: some View {
        HStack(spacing: 8) {
            // STREAK
            if statsManager.getCurrentStreak() > 0 {
                CompactStatusIndicator(
                    icon: "flame.fill",
                    value: "\(statsManager.getCurrentStreak())",
                    color: AppColors.warningColor
                )
            }
            
            Spacer()
            
            // POMODORO PROGRESS
            if appModeManager.currentMode == .pomodoro {
                CompactPomodoroProgress()
                    .environmentObject(timerManager)
            }
            
            Spacer()
            
            // TODAY'S SESSIONS
            if statsManager.getSessionsToday() > 0 {
                CompactStatusIndicator(
                    icon: "checkmark.circle.fill",
                    value: "\(statsManager.getSessionsToday())",
                    color: AppColors.successColor
                )
            }
        }
        .padding(.horizontal, 12)
    }
}

struct CompactStatusIndicator: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.15))
        )
    }
}

struct CompactPomodoroProgress: View {
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < timerManager.sessionsCompleted ? timerManager.currentMode.color : Color.white.opacity(0.2))
                    .frame(width: 4, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: timerManager.sessionsCompleted)
            }
        }
    }
}

// MARK: - Controls Overlay

struct CompactControlsOverlay: View {
    let geometry: GeometryProxy
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var navigationManager: AppNavigationManager
    @EnvironmentObject var appModeManager: AppModeManager
    
    var body: some View {
        VStack {
            HStack {
                // MODE TOGGLE
                CompactFloatingButton(
                    icon: appModeManager.currentMode == .clock ? "timer" : "house.fill",
                    action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            if appModeManager.currentMode == .clock {
                                appModeManager.setMode(.pomodoro)
                            } else {
                                appModeManager.setMode(.clock)
                            }
                        }
                    }
                )
                
                Spacer()
                
                // EXPAND BUTTON
                CompactFloatingButton(
                    icon: "arrow.up.left.and.arrow.down.right",
                    action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            windowManager.toggleCompactMode()
                        }
                    }
                )
            }
            .padding(.top, 8)
            .padding(.horizontal, 12)
            
            Spacer()
            
            // SETTINGS ACCESS
            HStack {
                Spacer()
                
                CompactFloatingButton(
                    icon: "gearshape",
                    action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            windowManager.toggleCompactMode()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navigationManager.navigateTo(.settings)
                            }
                        }
                    }
                )
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 12)
        }
    }
}

struct CompactFloatingButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
