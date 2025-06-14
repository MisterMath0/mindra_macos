//
//  ContentView.swift
//  MindraTimer
//
//  RESTORED ORIGINAL BEAUTIFUL DESIGN - PROPER SCALING
//  Back to the working proportions and layout
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var navigationManager: AppNavigationManager
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var appModeManager: AppModeManager
    @EnvironmentObject var quotesManager: QuotesManager
    @EnvironmentObject var greetingManager: GreetingManager
    @EnvironmentObject var audioService: AudioService
    @EnvironmentObject var notificationService: NotificationService
    
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
                    // Full Screen Mode - Back to original beauty
                    if navigationManager.currentPage == .settings {
                        // Settings as full page
                        MindraSettingsView()
                            .environmentObject(statsManager)
                            .environmentObject(timerManager)
                            .environmentObject(windowManager)
                            .environmentObject(appModeManager)
                            .environmentObject(quotesManager)
                            .environmentObject(greetingManager)
                            .environmentObject(navigationManager)
                            .environmentObject(notificationService)
                    } else {
                        fullScreenView(geometry: geometry)
                        .transition(.asymmetric(
                        insertion: .scale(scale: 1.1).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                        .overlay(
                            // Notification banner overlay
                            NotificationBannerOverlay(
                                notificationService: notificationService,
                                onAction: handleNotificationAction
                            )
                        )
                    }
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: windowManager.isCompact)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: navigationManager.currentPage)
        .sheet(isPresented: $showSoundPicker) {
            PremiumSoundPickerView()
                .environmentObject(statsManager)
                .environmentObject(audioService)
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
    
    // MARK: - Full Screen View - RESTORED ORIGINAL PROPORTIONS
    
    private func fullScreenView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Top section with quotes (only in focus mode)
            if appModeManager.currentMode == .pomodoro && statsManager.settings.showQuotes {
                topSection(geometry: geometry)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Main content area - ORIGINAL SPACING RESTORED
            Spacer(minLength: max(60, geometry.size.height * 0.08))
            
            mainContentArea(geometry: geometry)
            
            Spacer(minLength: max(80, geometry.size.height * 0.12))
            
            // Bottom navigation - ORIGINAL LAYOUT
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
                Text("\"\(quotesManager.currentQuote)\"")
                    .font(.system(size: max(14, geometry.size.width * 0.014), weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .italic()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: geometry.size.width * 0.35)
                    .lineLimit(2)
                    .tracking(0.3)
                    .animation(.easeInOut(duration: 0.5), value: quotesManager.currentQuote)
            }
        }
        .padding(.horizontal, max(32, geometry.size.width * 0.04))
        .padding(.top, max(24, geometry.size.height * 0.03))
    }
    
    // MARK: - Main Content - ORIGINAL BEAUTIFUL LAYOUT
    
    private func mainContentArea(geometry: GeometryProxy) -> some View {
        VStack(spacing: max(32, geometry.size.height * 0.04)) {
            // Timer mode header (Focus, Short Break, Long Break) - Only in pomodoro mode
            if appModeManager.currentMode == .pomodoro {
                timerModeHeader(geometry: geometry)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Greeting section - Only for clock mode or when enabled
            if statsManager.settings.showGreetings {
                greetingSection(geometry: geometry)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Main display (clock or timer) - ORIGINAL SIZES
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
            if appModeManager.currentMode == .clock {
                // Clock mode: Personalized time-dependent greetings only
                let greeting = greetingManager.getGreeting()
                if !greeting.isEmpty {
                    Text(greeting)
                        .font(.system(size: max(20, geometry.size.width * 0.024), weight: .medium, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white.opacity(0.9), .white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .tracking(max(0.5, geometry.size.width * 0.0006))
                        .animation(.easeInOut(duration: 0.5), value: greeting)
                }
            }
        }
    }
    
    // MARK: - Timer Mode Header - ORIGINAL BEAUTIFUL TABS
    
    private func timerModeHeader(geometry: GeometryProxy) -> some View {
        HStack(spacing: max(12, geometry.size.width * 0.015)) {
            ForEach(TimerMode.allCases, id: \.self) { mode in
                timerModeButton(mode: mode, geometry: geometry)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: timerManager.currentMode)
    }
    
    private func timerModeButton(mode: TimerMode, geometry: GeometryProxy) -> some View {
        Button(action: { 
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                timerManager.setMode(mode)
            }
        }) {
            Text(mode.displayName)
                .font(.system(size: max(14, geometry.size.width * 0.016), weight: .medium, design: .rounded))
                .foregroundColor(timerManager.currentMode == mode ? .white : .white.opacity(0.6))
                .padding(.horizontal, max(20, geometry.size.width * 0.025))
                .padding(.vertical, max(10, geometry.size.height * 0.012))
                .background(
                    RoundedRectangle(cornerRadius: max(8, geometry.size.width * 0.01))
                        .fill(timerManager.currentMode == mode ? mode.color : Color.white.opacity(0.08))
                )
                .scaleEffect(timerManager.currentMode == mode ? 1.0 : 0.95)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: timerManager.currentMode)
    }
    
    // MARK: - Clock Display - ORIGINAL BOLD BEAUTY
    
    private func clockDisplay(geometry: GeometryProxy) -> some View {
        VStack(spacing: max(28, geometry.size.height * 0.035)) {
            // Current time - ORIGINAL BOLD SIZE
            Text(getCurrentTime())
                .font(.system(size: max(60, min(geometry.size.width * 0.2, 200)), weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(max(6, geometry.size.width * 0.007))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.3), value: getCurrentTime())
            
            // Date info
            Text(getCurrentDate())
                .font(.system(size: max(22, geometry.size.width * 0.026), weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .tracking(max(1, geometry.size.width * 0.0012))
                .animation(.easeInOut(duration: 0.3), value: getCurrentDate())
            
            // Stats (only if meaningful data)
            if statsManager.settings.showGreetings && shouldShowStats() {
                ClockStatsView(geometry: geometry)
                    .environmentObject(statsManager)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private func shouldShowStats() -> Bool {
        return statsManager.getSessionsToday() > 0 || 
               statsManager.getCurrentStreak() > 0 || 
               statsManager.getTotalHours() > 0
    }
    
    // MARK: - Pomodoro Display - ORIGINAL IMPACT
    
    private func pomodoroDisplay(geometry: GeometryProxy) -> some View {
        VStack(spacing: max(32, geometry.size.height * 0.04)) {
            // Timer display with enhanced progress ring - OPTIMIZED SIZE
            ZStack {
                // Background circle - SLIGHTLY SMALLER
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: max(6, geometry.size.width * 0.006))
                    .frame(width: max(240, geometry.size.width * 0.28))
                
                // Progress circle - SLIGHTLY SMALLER
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        timerManager.currentMode.color,
                        style: StrokeStyle(lineWidth: max(6, geometry.size.width * 0.006), lineCap: .round)
                    )
                    .frame(width: max(240, geometry.size.width * 0.28))
                    .rotationEffect(.degrees(-90))
                    .shadow(
                        color: timerManager.currentMode.color.opacity(0.4), 
                        radius: 6, 
                        x: 0, 
                        y: 3
                    )
                    .animation(.easeInOut(duration: 1), value: timerManager.progress)
                
                // Timer text - REDUCED SIZE FOR BETTER PROPORTIONS
                Text(timerManager.formattedTime)
                    .font(.system(size: max(72, min(geometry.size.width * 0.11, 120)), weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(max(3, geometry.size.width * 0.004))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .animation(.easeInOut(duration: 0.2), value: timerManager.formattedTime)
            }
            
            // Enhanced control buttons
            timerControls(geometry: geometry)
            
            // Minimal stats display (pulls from database)
            minimalPomodoroStats(geometry: geometry)
                .transition(.scale.combined(with: .opacity))
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
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPrimary)
    }
    
    private func minimalPomodoroStats(geometry: GeometryProxy) -> some View {
        HStack(spacing: max(20, geometry.size.width * 0.025)) {
            // Today's sessions with icon
            HStack(spacing: max(8, geometry.size.width * 0.01)) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: max(14, geometry.size.width * 0.016), weight: .medium))
                    .foregroundColor(AppColors.successColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(statsManager.getSessionsToday())")
                        .font(.system(size: max(16, geometry.size.width * 0.02), weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("today")
                        .font(.system(size: max(10, geometry.size.width * 0.012), weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Divider
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1, height: max(24, geometry.size.height * 0.03))
            
            // Current streak with icon
            HStack(spacing: max(8, geometry.size.width * 0.01)) {
                Image(systemName: "flame.fill")
                    .font(.system(size: max(14, geometry.size.width * 0.016), weight: .medium))
                    .foregroundColor(AppColors.warningColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(statsManager.getCurrentStreak())")
                        .font(.system(size: max(16, geometry.size.width * 0.02), weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("streak")
                        .font(.system(size: max(10, geometry.size.width * 0.012), weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Divider
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1, height: max(24, geometry.size.height * 0.03))
            
            // Cycles completed with icon
            HStack(spacing: max(8, geometry.size.width * 0.01)) {
                Image(systemName: "arrow.2.circlepath")
                    .font(.system(size: max(14, geometry.size.width * 0.016), weight: .medium))
                    .foregroundColor(AppColors.focusColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(statsManager.getSessionsToday() / 4)")
                        .font(.system(size: max(16, geometry.size.width * 0.02), weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("cycles")
                        .font(.system(size: max(10, geometry.size.width * 0.012), weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, max(16, geometry.size.width * 0.02))
        .padding(.vertical, max(8, geometry.size.height * 0.01))
        .background(
            RoundedRectangle(cornerRadius: max(8, geometry.size.width * 0.01))
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: max(8, geometry.size.width * 0.01))
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: statsManager.getSessionsToday())
    }
    
    private func sessionCounter(geometry: GeometryProxy) -> some View {
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
    }
    
    // MARK: - Bottom Navigation - ORIGINAL LAYOUT
    
    private func bottomNavigation(geometry: GeometryProxy) -> some View {
        HStack {
            // Left side controls
            HStack(spacing: max(20, geometry.size.width * 0.025)) {
                navButton(icon: "bell", action: { 
                    showSoundPicker = true 
                }, geometry: geometry)
            }
            .frame(width: max(60, geometry.size.width * 0.08), alignment: .leading)
            
            Spacer()
            
            // Center navigation
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
                    icon: windowManager.isAlwaysOnTop ? "pin.fill" : "pin", 
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
                    action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            navigationManager.navigateTo(.settings)
                        }
                    }, 
                    geometry: geometry,
                    isActive: navigationManager.currentPage == .settings
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
        // Use TimerManager's toggle method instead of custom logic
        timerManager.toggleTimer()
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
    
    // MARK: - Notification Action Handling
    
    private func handleNotificationAction(_ actionIdentifier: String) {
        switch actionIdentifier {
        case "start_next_session":
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                if timerManager.currentMode == .focus {
                    // After focus, start break
                    let nextMode: TimerMode = timerManager.sessionsCompleted % 4 == 0 ? .longBreak : .shortBreak
                    timerManager.setMode(nextMode)
                } else {
                    // After break, start focus
                    timerManager.setMode(.focus)
                }
                timerManager.startTimer()
            }
        case "start_focus_session":
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appModeManager.setMode(.pomodoro)
                timerManager.setMode(.focus)
                timerManager.startTimer()
            }
        case "view_achievements":
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                navigationManager.navigateTo(.settings)
                // Navigate to stats section in settings
            }
        default:
            break
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WindowManager())
        .environmentObject(AppNavigationManager())
        .environmentObject(StatsManager())
        .environmentObject(TimerManager())
        .environmentObject(AppModeManager())
        .environmentObject(QuotesManager())
        .environmentObject(GreetingManager())
        .environmentObject(AudioService())
}
