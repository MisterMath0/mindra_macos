//
//  ContentView.swift
//  MindraTimer
//
//  Updated with consistent colors and enhanced UI
//

import SwiftUI

// MARK: - App Colors (Consistent Color Scheme)

struct AppColors {
    // Primary colors matching main app
    static let primaryBackground = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let sidebarBackground = Color(red: 0.04, green: 0.04, blue: 0.04)
    static let cardBackground = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let selectedBackground = Color.white.opacity(0.1)
    
    // Text colors
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let tertiaryText = Color.white.opacity(0.5)
    
    // Accent colors matching timer modes
    static let focusColor = Color(red: 0.6, green: 0.4, blue: 0.9) // Purple like main app
    static let shortBreakColor = Color(red: 0.9, green: 0.5, blue: 0.7) // Pink
    static let longBreakColor = Color(red: 0.3, green: 0.6, blue: 0.9) // Blue
    
    // UI colors
    static let dividerColor = Color.white.opacity(0.1)
    static let errorColor = Color.red
    static let successColor = Color.green
    static let warningColor = Color.orange
}

struct ContentView: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var appModeManager: AppModeManager
    @EnvironmentObject var quotesManager: QuotesManager
    @EnvironmentObject var greetingManager: GreetingManager
    
    @State private var showSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                AppColors.primaryBackground
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
                .environmentObject(quotesManager)
                .environmentObject(greetingManager)
        }
    }
    
    // MARK: - Compact PiP View
    
    private func compactPiPView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Main content centered - Flocus style
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
    

    private func compactTimerDisplay(geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            // Timer display - Flocus style with larger font
            Text(timerManager.formattedTime)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(AppColors.primaryText)
                .tracking(2)
            
            // Start/Pause button - Flocus style
            Button(action: toggleTimer) {
                HStack(spacing: 8) {
                    Image(systemName: timerManager.isActive && !timerManager.isPaused ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(timerManager.isActive && !timerManager.isPaused ? "Pause" : "Start")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppColors.focusColor)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func compactClockDisplay(geometry: GeometryProxy) -> some View {
        VStack(spacing: 4) {
            Text(getCurrentTime())
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(AppColors.primaryText)
                .tracking(1)
            
            Text(getCurrentDate())
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.secondaryText)
        }
    }
    
    private func compactControls(geometry: GeometryProxy) -> some View {
        HStack {
            // Mode toggle
            Button(action: { appModeManager.toggleMode() }) {
                Image(systemName: appModeManager.currentMode == .clock ? "timer" : "clock")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppColors.tertiaryText)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Settings
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppColors.tertiaryText)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
    
    // MARK: - Full Screen View
    
    private func fullScreenView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Top section with quotes (only in focus mode)
            if appModeManager.currentMode == .pomodoro && statsManager.settings.showQuotes {
                topSection(geometry: geometry)
            }
            
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
            
            // Quote in top-right corner (replaces previous content)
            if !quotesManager.currentQuote.isEmpty {
                Text(quotesManager.currentQuote)
                    .font(.system(size: max(12, geometry.size.width * 0.012), weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: geometry.size.width * 0.35)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, max(32, geometry.size.width * 0.04))
        .padding(.top, max(24, geometry.size.height * 0.03))
    }
    
    // MARK: - Main Content
    
    private func mainContentArea(geometry: GeometryProxy) -> some View {
        VStack(spacing: max(32, geometry.size.height * 0.04)) {
            // Clock mode: Show personalized greetings
            // Focus mode: Show focus prompts
            if statsManager.settings.showGreetings {
                greetingSection(geometry: geometry)
            }
            
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
                // Focus mode: Task focus question
                Text(greetingManager.getFocusPrompt())
                    .font(.system(size: max(18, geometry.size.width * 0.022), weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                // Mode selection buttons
                HStack(spacing: max(12, geometry.size.width * 0.015)) {
                    ForEach(TimerMode.allCases, id: \.self) { mode in
                        modeButton(mode: mode, geometry: geometry)
                    }
                }
            } else {
                // Clock mode: Personalized time-dependent greetings
                let greeting = greetingManager.getGreeting()
                if !greeting.isEmpty {
                    Text(greeting)
                        .font(.system(size: max(24, geometry.size.width * 0.028), weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                }
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

}

#Preview {
    ContentView()
        .environmentObject(WindowManager())
        .environmentObject(StatsManager())
        .environmentObject(TimerManager())
        .environmentObject(AppModeManager())
        .environmentObject(QuotesManager())
        .environmentObject(GreetingManager())
}
