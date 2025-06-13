//
//  FullModeComponents.swift
//  MindraTimer
//
//  🖥️ CLEAN FULL-MODE COMPONENTS - FIXED REDECLARATIONS
//  Single source of truth for all FullMode components
//

import SwiftUI

// MARK: - ⏱️ Premium Timer Display

struct PremiumTimerDisplay: View {
    let geometry: GeometryProxy
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        VStack(spacing: max(28, geometry.size.height * 0.035)) {
            Text(timerManager.currentMode.displayName)
                .font(.system(size: max(14, geometry.size.width * 0.016), weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .tracking(max(1.8, geometry.size.width * 0.002))
                .animation(.easeInOut(duration: 0.3), value: timerManager.currentMode)
            
            // TIMER RING
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: max(3, geometry.size.width * 0.004))
                    .frame(width: max(160, geometry.size.width * 0.18))
                
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        timerManager.currentMode.color,
                        style: StrokeStyle(lineWidth: max(3, geometry.size.width * 0.004), lineCap: .round)
                    )
                    .frame(width: max(160, geometry.size.width * 0.18))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: timerManager.progress)
                
                Text(timerManager.formattedTime)
                    .font(.system(size: max(56, min(geometry.size.width * 0.09, 120)), weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(max(2.5, geometry.size.width * 0.003))
                    .animation(.easeInOut(duration: 0.2), value: timerManager.formattedTime)
            }
            
            // TIMER CONTROLS
            FullModeTimerControls(geometry: geometry)
                .environmentObject(timerManager)
            
            // SESSION COUNTER
            if timerManager.sessionsCompleted > 0 {
                FullModeSessionCounter(geometry: geometry)
                    .environmentObject(timerManager)
            }
        }
    }
}

// MARK: - Timer Controls (Renamed to avoid conflicts)

struct FullModeTimerControls: View {
    let geometry: GeometryProxy
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        HStack(spacing: max(20, geometry.size.width * 0.025)) {
            // RESET
            FullModeControlButton(
                icon: "arrow.clockwise",
                action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        timerManager.resetTimer()
                    }
                },
                geometry: geometry,
                isPrimary: false
            )
            
            // PLAY/PAUSE
            FullModeControlButton(
                icon: timerManager.isActive && !timerManager.isPaused ? "pause.fill" : "play.fill",
                action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        timerManager.toggleTimer()
                    }
                },
                geometry: geometry,
                isPrimary: true
            )
            
            // SKIP
            FullModeControlButton(
                icon: "forward.fill",
                action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        timerManager.skipTimer()
                    }
                },
                geometry: geometry,
                isPrimary: false
            )
        }
    }
}

// MARK: - Timer Control Button (Renamed to avoid conflicts)

struct FullModeControlButton: View {
    let icon: String
    let action: () -> Void
    let geometry: GeometryProxy
    let isPrimary: Bool
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: max(18, geometry.size.width * 0.02), weight: .medium))
                .foregroundColor(isPrimary ? .black : .white)
                .frame(
                    width: max(56, geometry.size.width * 0.06),
                    height: max(56, geometry.size.width * 0.06)
                )
                .background(
                    Circle()
                        .fill(isPrimary ? .white : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPrimary)
    }
}

// MARK: - Session Counter (Renamed to avoid conflicts)

struct FullModeSessionCounter: View {
    let geometry: GeometryProxy
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        HStack(spacing: max(20, geometry.size.width * 0.025)) {
            VStack(spacing: max(6, geometry.size.height * 0.008)) {
                Text("Focus Sessions")
                    .font(.system(size: max(12, geometry.size.width * 0.014), weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(max(0.6, geometry.size.width * 0.0008))
                Text("\(timerManager.sessionsCompleted)")
                    .font(.system(size: max(18, geometry.size.width * 0.022), weight: .semibold, design: .rounded))
                    .foregroundColor(timerManager.currentMode.color)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: timerManager.sessionsCompleted)
            }
            VStack(spacing: max(6, geometry.size.height * 0.008)) {
                Text("Pomodoro Cycles")
                    .font(.system(size: max(12, geometry.size.width * 0.014), weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(max(0.6, geometry.size.width * 0.0008))
                Text("\(timerManager.sessionsCompleted / 4)")
                    .font(.system(size: max(18, geometry.size.width * 0.022), weight: .semibold, design: .rounded))
                    .foregroundColor(timerManager.currentMode.color)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: timerManager.sessionsCompleted)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}
