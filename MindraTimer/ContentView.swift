//
//  ContentView.swift
//  MindraTimer
//
//  Updated with modern animations and enhanced UI
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
    @State private var showSoundPicker = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with title bar color matching
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                if windowManager.isCompact {
                    // Compact PiP Mode - Enhanced
                    compactPiPView(geometry: geometry)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 1.1).combined(with: .opacity)
                        ))
                } else {
                    // Full Screen Mode
                    fullScreenView(geometry: geometry)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 1.1).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: windowManager.isCompact)
        .sheet(isPresented: $showSettings) {
            MindraSettingsView()
                .environmentObject(statsManager)
                .environmentObject(timerManager)
                .environmentObject(windowManager)
                .environmentObject(appModeManager)
                .environmentObject(quotesManager)
                .environmentObject(greetingManager)
        }
        .sheet(isPresented: $showSoundPicker) {
            SoundPickerView()
                .environmentObject(statsManager)
        }
    }
    
    // MARK: - Enhanced Compact PiP View
    
    private func compactPiPView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Progress indicator at top ONLY when timer is active and has progress
            if appModeManager.currentMode == .pomodoro && timerManager.isActive && timerManager.progress > 0 {
                Rectangle()
                    .fill(timerManager.currentMode.color)
                    .frame(height: 3)
                    .scaleEffect(x: timerManager.progress, y: 1, anchor: .leading)
                    .animation(.easeInOut(duration: 1), value: timerManager.progress)
            }
            Spacer()
            // Main content centered - Clean minimal style
            if appModeManager.currentMode == .pomodoro {
                compactTimerDisplay(geometry: geometry)
            } else {
                compactClockDisplay(geometry: geometry)
            }
            Spacer()
            // Progress dots for pomodoro cycle
            if appModeManager.currentMode == .pomodoro {
                pomodoroProgressDots()
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    windowManager.toggleCompactMode()
                }
            }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(AppColors.cardBackground)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 20)
            .padding(.leading, 20),
            alignment: .topLeading
        )
    }
    
    private func compactTimerDisplay(geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            // Timer display - Responsive and clean
            Text(timerManager.formattedTime)
                .font(.system(size: min(geometry.size.width * 0.25, 60), weight: .black, design: .rounded))
                .foregroundColor(AppColors.primaryText)
                .tracking(1)
                .animation(.easeInOut(duration: 0.3), value: timerManager.formattedTime)
            
            // Start/Pause button - Modern style
            Button(action: toggleTimer) {
                HStack(spacing: 6) {
                    Image(systemName: timerManager.isActive && !timerManager.isPaused ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(timerManager.isActive && !timerManager.isPaused ? "Pause" : "Start")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(timerManager.currentMode.color)
                )
                .scaleEffect(1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: timerManager.isActive)
        }
    }
    
    private func compactClockDisplay(geometry: GeometryProxy) -> some View {
        VStack(spacing: 4) {
            Text(getCurrentTime())
                .font(.system(size: min(geometry.size.width * 0.20, 48), weight: .black, design: .rounded))
                .foregroundColor(AppColors.primaryText)
                .tracking(1)
            
            Text(getCurrentDate())
                .font(.system(size: min(geometry.size.width * 0.08, 12), weight: .medium, design: .rounded))
                .foregroundColor(AppColors.secondaryText)
        }
    }
    
    private func pomodoroProgressDots() -> some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < timerManager.sessionsCompleted ? timerManager.currentMode.color : AppColors.tertiaryText.opacity(0.3))
                    .frame(width: 4, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: timerManager.sessionsCompleted)
            }
        }
    }
    
    // MARK: - Full Screen View
    
    private func fullScreenView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Top section with quotes (only in focus mode)
            if appModeManager.currentMode == .pomodoro && statsManager.settings.showQuotes {
                topSection(geometry: geometry)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Main content area (better spacing)
            Spacer(minLength: max(60, geometry.size.height * 0.08))
            
            mainContentArea(geometry: geometry)
            
            Spacer(minLength: max(80, geometry.size.height * 0.12))
            
            // Bottom navigation (properly aligned)
            bottomNavigation(geometry: geometry)
        }
        .animation(.easeInOut(duration: 0.4), value: appModeManager.currentMode)
    }
    
    // MARK: - Top Section
    
    private func topSection(geometry: GeometryProxy) -> some View {
        HStack {
            Spacer()
            
            // Quote in top-right corner
            if !quotesManager.currentQuote.isEmpty {
                Text(quotesManager.currentQuote)
                    .font(.system(size: max(12, geometry.size.width * 0.012), weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: geometry.size.width * 0.35)
                    .lineLimit(2)
                    .opacity(1.0)
                    .animation(.easeInOut(duration: 0.5), value: quotesManager.currentQuote)
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
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Main display (clock or timer)
            if appModeManager.currentMode == .clock {
                clockDisplay(geometry: geometry)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.2).combined(with: .opacity)
                    ))
            } else {
                pomodoroDisplay(geometry: geometry)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.2).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
            }
        }
    }
    
    private func greetingSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: max(16, geometry.size.height * 0.02)) {
            if appModeManager.currentMode == .pomodoro {
                // Mode selection buttons with animations
                HStack(spacing: max(12, geometry.size.width * 0.015)) {
                    ForEach(TimerMode.allCases, id: \.self) { mode in
                        modeButton(mode: mode, geometry: geometry)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: timerManager.currentMode)
            } else {
                // Clock mode: Personalized time-dependent greetings
                let greeting = greetingManager.getGreeting()
                if !greeting.isEmpty {
                    Text(greeting)
                        .font(.system(size: max(24, geometry.size.width * 0.028), weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.5), value: greeting)
                }
            }
        }
    }
    
    private func modeButton(mode: TimerMode, geometry: GeometryProxy) -> some View {
        Button(action: { 
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                timerManager.setMode(mode)
            }
        }) {
            Text(mode.displayName)
                .font(.system(size: max(14, geometry.size.width * 0.016), weight: .medium, design: .rounded))
                .foregroundColor(timerManager.currentMode == mode ? .white : .white.opacity(0.6))
                .padding(.horizontal, max(16, geometry.size.width * 0.02))
                .padding(.vertical, max(8, geometry.size.height * 0.01))
                .background(
                    RoundedRectangle(cornerRadius: max(8, geometry.size.width * 0.01))
                        .fill(timerManager.currentMode == mode ? mode.color : Color.white.opacity(0.08))
                )
                .scaleEffect(timerManager.currentMode == mode ? 1.0 : 0.95)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: timerManager.currentMode)
    }
    
    private func clockDisplay(geometry: GeometryProxy) -> some View {
        VStack(spacing: max(16, geometry.size.height * 0.02)) {
            // Current time with BLACK weight - LARGER
            Text(getCurrentTime())
                .font(.system(size: max(120, geometry.size.width * 0.15), weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(3)
                .animation(.easeInOut(duration: 0.3), value: getCurrentTime())
            
            // Date info
            Text(getCurrentDate())
                .font(.system(size: max(18, geometry.size.width * 0.022), weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)
                .animation(.easeInOut(duration: 0.3), value: getCurrentDate())
            
            // Time zone or additional info
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
                .animation(.easeInOut(duration: 0.3), value: timerManager.currentMode)
            
            // Timer display with enhanced progress ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 3)
                    .frame(width: max(120, geometry.size.width * 0.15))
                
                // Progress circle with smooth animation
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
                    .animation(.easeInOut(duration: 0.2), value: timerManager.formattedTime)
            }
            
            // Enhanced control buttons
            timerControls(geometry: geometry)
            
            // Session counter with animation
            if timerManager.sessionsCompleted > 0 {
                VStack(spacing: 4) {
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("Focus Sessions")
                                .font(.system(size: max(10, geometry.size.width * 0.012), weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(0.5)
                            Text("\(timerManager.sessionsCompleted)")
                                .font(.system(size: max(16, geometry.size.width * 0.02), weight: .semibold, design: .rounded))
                                .foregroundColor(timerManager.currentMode.color)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: timerManager.sessionsCompleted)
                        }
                        VStack(spacing: 4) {
                            Text("Pomodoro Cycles")
                                .font(.system(size: max(10, geometry.size.width * 0.012), weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(0.5)
                            Text("\(timerManager.sessionsCompleted / 4)")
                                .font(.system(size: max(16, geometry.size.width * 0.02), weight: .semibold, design: .rounded))
                                .foregroundColor(timerManager.currentMode.color)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: timerManager.sessionsCompleted)
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func timerControls(geometry: GeometryProxy) -> some View {
        HStack(spacing: max(20, geometry.size.width * 0.025)) {
            // Reset button
            controlButton(
                icon: "arrow.clockwise",
                action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        timerManager.resetTimer()
                    }
                },
                geometry: geometry,
                isPrimary: false
            )
            
            // Play/Pause button
            controlButton(
                icon: timerManager.isActive && !timerManager.isPaused ? "pause.fill" : "play.fill",
                action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        toggleTimer()
                    }
                },
                geometry: geometry,
                isPrimary: true
            )
            
            // Skip button
            controlButton(
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
                .scaleEffect(1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPrimary)
    }
    
    // MARK: - Bottom Navigation
    
    private func bottomNavigation(geometry: GeometryProxy) -> some View {
        HStack {
            // Left side controls
            HStack(spacing: max(20, geometry.size.width * 0.025)) {
                navButton(icon: "bell", action: { showSoundPicker = true }, geometry: geometry)
            }
            .frame(width: max(60, geometry.size.width * 0.08), alignment: .leading)
            
            Spacer()
            
            // Center navigation (perfectly centered with main content)
            HStack(spacing: max(32, geometry.size.width * 0.04)) {
                navButton(
                    icon: "house.fill",
                    action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            appModeManager.setMode(.clock)
                        }
                    },
                    geometry: geometry,
                    isActive: appModeManager.currentMode == .clock
                )
                navButton(
                    icon: "timer",
                    action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            appModeManager.setMode(.pomodoro)
                        }
                    },
                    geometry: geometry,
                    isActive: appModeManager.currentMode == .pomodoro
                )
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Right side controls
            HStack(spacing: max(16, geometry.size.width * 0.02)) {
                navButton(
                    icon: "rectangle.compress.vertical", 
                    action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            windowManager.toggleCompactMode()
                        }
                    }, 
                    geometry: geometry
                )
                navButton(
                    icon: "pin", 
                    action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            windowManager.toggleAlwaysOnTop()
                        }
                    }, 
                    geometry: geometry, 
                    isActive: windowManager.isAlwaysOnTop
                )
                navButton(
                    icon: "gearshape", 
                    action: { showSettings = true }, 
                    geometry: geometry
                )
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
                .scaleEffect(isActive ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
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
