//
//  ContentView.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 09.06.25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var appModeManager: AppModeManager
    
    @State private var showSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(red: 0.05, green: 0.05, blue: 0.05) // Modern dark gray instead of pure black
                    .ignoresSafeArea()
                
                if windowManager.isCompact {
                    // Compact PiP Mode - Only Timer
                    compactPiPView(geometry: geometry)
                } else {
                    // Full Screen Mode
                    fullScreenView(geometry: geometry)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            MindraSettingsView()
                .environmentObject(statsManager)
                .environmentObject(timerManager)
                .environmentObject(windowManager)
                .environmentObject(appModeManager)
        }
    }
    
    // MARK: - Compact PiP View
    
    private func compactPiPView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Progress bar at top
            if appModeManager.currentMode == .pomodoro {
                progressBar(geometry: geometry)
            }
            
            Spacer()
            
            // Only timer content in PiP mode
            if appModeManager.currentMode == .pomodoro {
                compactTimerDisplay(geometry: geometry)
            } else {
                compactClockDisplay(geometry: geometry)
            }
            
            Spacer()
            
            // Minimal controls
            compactControls(geometry: geometry)
        }
    }
    
    private func progressBar(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Progress bar
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 2)
                .overlay(
                    Rectangle()
                        .fill(timerManager.currentMode.color)
                        .frame(width: geometry.size.width * timerManager.progress)
                        .animation(.easeInOut(duration: 1), value: timerManager.progress),
                    alignment: .leading
                )
            
            // Mode indicator
            HStack {
                Text(timerManager.currentMode.displayName)
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.5)
                
                Spacer()
                
                // Expand button
                Button(action: { windowManager.toggleCompactMode() }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
    
    private func compactTimerDisplay(geometry: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            // Timer display
            Text(timerManager.formattedTime)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(1)
            
            // Play/Pause button
            Button(action: toggleTimer) {
                Image(systemName: timerManager.isActive && !timerManager.isPaused ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func compactClockDisplay(geometry: GeometryProxy) -> some View {
        VStack(spacing: 4) {
            Text(getCurrentTime())
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(1)
            
            Text(getCurrentDate())
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private func compactControls(geometry: GeometryProxy) -> some View {
        HStack {
            // Mode toggle
            Button(action: { appModeManager.toggleMode() }) {
                Image(systemName: appModeManager.currentMode == .clock ? "timer" : "clock")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Settings
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
    
    // MARK: - Full Screen View
    
    private func fullScreenView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Top section with quote only
            topSection(geometry: geometry)
            
            // Main content area (better spacing)
            Spacer(minLength: max(60, geometry.size.height * 0.08))
            
            mainContentArea(geometry: geometry)
            
            Spacer(minLength: max(80, geometry.size.height * 0.12))
            
            // Bottom navigation (properly aligned)
            bottomNavigation(geometry: geometry)
        }
    }
    
    // MARK: - Top Section
    
    private func topSection(geometry: GeometryProxy) -> some View {
        HStack {
            Spacer()
            
            // Quote/motivational text (right aligned)
            Text(getMotivationalQuote())
                .font(.system(size: max(12, geometry.size.width * 0.012), weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: geometry.size.width * 0.35)
                .lineLimit(2)
        }
        .padding(.horizontal, max(32, geometry.size.width * 0.04))
        .padding(.top, max(24, geometry.size.height * 0.03))
    }
    
    // MARK: - Main Content
    
    private func mainContentArea(geometry: GeometryProxy) -> some View {
        VStack(spacing: max(32, geometry.size.height * 0.04)) {
            // Greeting
            greetingSection(geometry: geometry)
            
            // Main display (clock or timer)
            if appModeManager.currentMode == .clock {
                clockDisplay(geometry: geometry)
            } else {
                pomodoroDisplay(geometry: geometry)
            }
        }
    }
    
    private func greetingSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: max(16, geometry.size.height * 0.02)) {
            if appModeManager.currentMode == .pomodoro {
                // Task focus question
                Text("What do you want to focus on?")
                    .font(.system(size: max(18, geometry.size.width * 0.022), weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                // Mode selection buttons
                HStack(spacing: max(12, geometry.size.width * 0.015)) {
                    ForEach(TimerMode.allCases, id: \.self) { mode in
                        modeButton(mode: mode, geometry: geometry)
                    }
                }
            } else {
                // Clock greeting
                Text(getGreeting())
                    .font(.system(size: max(18, geometry.size.width * 0.022), weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
    
    private func modeButton(mode: TimerMode, geometry: GeometryProxy) -> some View {
        Button(action: { timerManager.setMode(mode) }) {
            Text(mode.displayName)
                .font(.system(size: max(14, geometry.size.width * 0.016), weight: .medium, design: .rounded))
                .foregroundColor(timerManager.currentMode == mode ? .white : .white.opacity(0.6))
                .padding(.horizontal, max(16, geometry.size.width * 0.02))
                .padding(.vertical, max(8, geometry.size.height * 0.01))
                .background(
                    RoundedRectangle(cornerRadius: max(8, geometry.size.width * 0.01))
                        .fill(timerManager.currentMode == mode ? mode.color : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func clockDisplay(geometry: GeometryProxy) -> some View {
        VStack(spacing: max(16, geometry.size.height * 0.02)) {
            // Current time with BLACK weight - LARGER
            Text(getCurrentTime())
                .font(.system(size: max(120, geometry.size.width * 0.15), weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(3)
            
            // Date info
            Text(getCurrentDate())
                .font(.system(size: max(18, geometry.size.width * 0.022), weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)
            
            // Time zone or additional info (to fill space)
            Text(getTimeZoneInfo())
                .font(.system(size: max(14, geometry.size.width * 0.016), weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .tracking(0.5)
        }
    }
    
    private func pomodoroDisplay(geometry: GeometryProxy) -> some View {
        VStack(spacing: max(24, geometry.size.height * 0.03)) {
            // Current mode label
            Text(timerManager.currentMode.displayName)
                .font(.system(size: max(12, geometry.size.width * 0.014), weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .tracking(1.5)
            
            // Timer display with progress ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 3)
                    .frame(width: max(120, geometry.size.width * 0.15))
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        timerManager.currentMode.color,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: max(120, geometry.size.width * 0.15))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: timerManager.progress)
                
                // Timer text with BLACK weight
                Text(timerManager.formattedTime)
                    .font(.system(size: max(48, geometry.size.width * 0.08), weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2)
            }
            
            // Control buttons
            timerControls(geometry: geometry)
            
            // Session counter
            if timerManager.sessionsCompleted > 0 {
                VStack(spacing: 4) {
                    Text("Sessions Completed")
                        .font(.system(size: max(10, geometry.size.width * 0.012), weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(0.5)
                    
                    Text("\(timerManager.sessionsCompleted)")
                        .font(.system(size: max(16, geometry.size.width * 0.02), weight: .semibold, design: .rounded))
                        .foregroundColor(timerManager.currentMode.color)
                }
            }
        }
    }
    
    private func timerControls(geometry: GeometryProxy) -> some View {
        HStack(spacing: max(20, geometry.size.width * 0.025)) {
            // Reset button
            controlButton(
                icon: "arrow.clockwise",
                action: { timerManager.resetTimer() },
                geometry: geometry,
                isPrimary: false
            )
            
            // Play/Pause button
            controlButton(
                icon: timerManager.isActive && !timerManager.isPaused ? "pause.fill" : "play.fill",
                action: { toggleTimer() },
                geometry: geometry,
                isPrimary: true
            )
            
            // Skip button
            controlButton(
                icon: "forward.fill",
                action: { timerManager.skipTimer() },
                geometry: geometry,
                isPrimary: false
            )
        }
    }
    
    private func controlButton(icon: String, action: @escaping () -> Void, geometry: GeometryProxy, isPrimary: Bool) -> some View {
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
    }
    
    // MARK: - Bottom Navigation (Perfect Alignment)
    
    private func bottomNavigation(geometry: GeometryProxy) -> some View {
        HStack {
            // Left side controls
            HStack(spacing: max(20, geometry.size.width * 0.025)) {
                navButton(icon: "bell", action: {}, geometry: geometry)
            }
            .frame(width: max(60, geometry.size.width * 0.08), alignment: .leading)
            
            Spacer()
            
            // Center navigation (perfectly centered with main content)
            HStack(spacing: max(32, geometry.size.width * 0.04)) {
                navButton(
                    icon: "house.fill",
                    action: { appModeManager.setMode(.clock) },
                    geometry: geometry,
                    isActive: appModeManager.currentMode == .clock
                )
                navButton(
                    icon: "timer",
                    action: { appModeManager.setMode(.pomodoro) },
                    geometry: geometry,
                    isActive: appModeManager.currentMode == .pomodoro
                )
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Right side controls
            HStack(spacing: max(16, geometry.size.width * 0.02)) {
                navButton(icon: "rectangle.compress.vertical", action: { windowManager.toggleCompactMode() }, geometry: geometry)
                navButton(icon: "pin", action: { windowManager.toggleAlwaysOnTop() }, geometry: geometry, isActive: windowManager.isAlwaysOnTop)
                navButton(icon: "gearshape", action: { showSettings = true }, geometry: geometry)
            }
            .frame(width: max(120, geometry.size.width * 0.15), alignment: .trailing)
        }
        .padding(.horizontal, max(40, geometry.size.width * 0.05))
        .padding(.bottom, max(32, geometry.size.height * 0.04))
    }
    
    private func navButton(icon: String, action: @escaping () -> Void, geometry: GeometryProxy, isActive: Bool = false) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: max(18, geometry.size.width * 0.02), weight: .medium))
                .foregroundColor(isActive ? timerManager.currentMode.color : .white.opacity(0.6))
                .frame(
                    width: max(44, geometry.size.width * 0.045),
                    height: max(44, geometry.size.width * 0.045)
                )
                .background(
                    Circle()
                        .fill(isActive ? timerManager.currentMode.color.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Functions
    
    private func toggleTimer() {
        if timerManager.isActive && !timerManager.isPaused {
            timerManager.pauseTimer()
        } else {
            timerManager.startTimer()
        }
    }
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = "Math" // You can make this dynamic later
        
        switch hour {
        case 0..<12:
            return "Good morning, \(name)."
        case 12..<17:
            return "Good afternoon, \(name)."
        default:
            return "Good evening, \(name)."
        }
    }
    
    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: Date())
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private func getTimeZoneInfo() -> String {
        let timeZone = TimeZone.current.localizedName(for: .standard, locale: .current) ?? "Local Time"
        return timeZone
    }
    
    private func getMotivationalQuote() -> String {
        let quotes = [
            "Focus on progress, not perfection.",
            "Your potential is endless.",
            "Great things never come from comfort zones.",
            "Success is built one focused session at a time."
        ]
        return quotes.randomElement() ?? quotes[0]
    }
}

#Preview {
    ContentView()
        .environmentObject(WindowManager())
        .environmentObject(StatsManager())
        .environmentObject(TimerManager())
        .environmentObject(AppModeManager())
}
