//
//  MindraSettingsView.swift
//  MindraTimer
//
//  Updated with Quotes & Greeting Settings and Consistent Colors
//

import SwiftUI

// MARK: - Custom Styles

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.cardBackground)
                    .stroke(AppColors.dividerColor, lineWidth: 1)
            )
            .foregroundColor(AppColors.primaryText)
            .font(.system(size: 14, weight: .medium, design: .rounded))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.focusColor)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
                    .shadow(color: AppColors.focusColor.opacity(0.3), radius: configuration.isPressed ? 2 : 4, x: 0, y: configuration.isPressed ? 1 : 2)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(AppColors.secondaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.cardBackground)
                    .stroke(AppColors.dividerColor, lineWidth: 1)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct MindraSettingsView: View {
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var appModeManager: AppModeManager
    @EnvironmentObject var quotesManager: QuotesManager
    @EnvironmentObject var greetingManager: GreetingManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: SettingsSection = .timer
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var tempUserName: String = ""
    @State private var soundVolume: Double
    @State private var quoteInterval: Double
    
    init() {
        // Initialize state variables with current values
        _soundVolume = State(initialValue: Double(UserDefaults.standard.integer(forKey: "soundVolume")))
        _quoteInterval = State(initialValue: Double(UserDefaults.standard.integer(forKey: "quoteRefreshInterval")))
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                sidebar(geometry: geometry)
                mainContent(geometry: geometry)
            }
            .background(AppColors.primaryBackground)
        }
        .frame(width: 900, height: 650)
        .onAppear {
            tempUserName = userName
        }
    }
    
    private func sidebar(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("Settings")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
            
            VStack(alignment: .leading, spacing: 24) {
                sectionGroup(title: "CORE", items: [
                    (.timer, "timer", "Timer"),
                    (.clock, "clock", "Clock"),
                    (.sounds, "speaker.wave.2", "Sounds"),
                    (.stats, "chart.bar", "Stats")
                ], geometry: geometry)
                
                sectionGroup(title: "PERSONALIZATION", items: [
                    (.profile, "person.circle", "Profile"),
                    (.quotes, "quote.bubble", "Quotes"),
                    (.appearance, "paintbrush", "Appearance")
                ], geometry: geometry)
                
                sectionGroup(title: "OTHER", items: [
                    (.general, "gearshape", "General"),
                    (.about, "info.circle", "About")
                ], geometry: geometry)
            }
            .padding(.leading, 24)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("MindraTimer")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                Text("Version 1.0.0")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.tertiaryText)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: geometry.size.width * 0.3)
        .background(AppColors.sidebarBackground)
    }
    
    private func sectionGroup(title: String, items: [(SettingsSection, String, String)], geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.tertiaryText)
                .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.0) { item in
                    sidebarItem(section: item.0, icon: item.1, title: item.2, geometry: geometry)
                }
            }
        }
    }
    
    private func sidebarItem(section: SettingsSection, icon: String, title: String, geometry: GeometryProxy) -> some View {
        Button(action: { selectedSection = section }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedSection == section ? AppColors.primaryText : AppColors.secondaryText)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(selectedSection == section ? AppColors.primaryText : AppColors.secondaryText)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedSection == section ? AppColors.selectedBackground : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func mainContent(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            switch selectedSection {
            case .timer: timerSettingsView(geometry: geometry)
            case .clock: clockSettingsView(geometry: geometry)
            case .sounds: soundSettingsView(geometry: geometry)
            case .stats: statsSettingsView(geometry: geometry)
            case .profile: profileSettingsView(geometry: geometry)
            case .quotes: quotesSettingsView(geometry: geometry)
            case .appearance: appearanceSettingsView(geometry: geometry)
            case .general: generalSettingsView(geometry: geometry)
            case .about: aboutView(geometry: geometry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.primaryBackground)
    }
    
    // MARK: - Settings Views
    
    private func profileSettingsView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Profile Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Customize your personal information")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Name")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        TextField("Enter your name", text: $tempUserName)
                            .textFieldStyle(ModernTextFieldStyle())
                            .onSubmit { saveUserName() }
                            .frame(maxWidth: 400)
                        
                        Text("Used for personalized greetings and quotes")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    HStack(spacing: 12) {
                        Button("Save") { saveUserName() }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(tempUserName.trimmingCharacters(in: .whitespacesAndNewlines) == userName)
                        
                        if !userName.isEmpty {
                            Button("Clear") {
                                tempUserName = ""
                                saveUserName()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                }
                
                Spacer(minLength: 200)
            }
            .padding(.all, 40)
        }
    }
    
    private func clockSettingsView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Clock Settings")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                VStack(alignment: .leading, spacing: 20) {
                    Toggle("Show greetings", isOn: Binding(
                        get: { statsManager.settings.showGreetings },
                        set: { _ in statsManager.toggleGreetings() }
                    ))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                    .accentColor(AppColors.focusColor)
                }
                Spacer()
            }
            .padding(.all, 32)
        }
    }
    
    private func quotesSettingsView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Quotes Settings")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                VStack(alignment: .leading, spacing: 20) {
                    Toggle("Show quotes", isOn: Binding(
                        get: { statsManager.settings.showQuotes },
                        set: { newValue in statsManager.settings.showQuotes = newValue }
                    ))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                    .accentColor(AppColors.focusColor)
                    
                    if statsManager.settings.showQuotes {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("Enable personalized quotes", isOn: Binding(
                                get: { statsManager.settings.enablePersonalizedQuotes },
                                set: { newValue in 
                                    statsManager.settings.enablePersonalizedQuotes = newValue
                                    quotesManager.setPersonalization(newValue)
                                }
                            ))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                            .accentColor(AppColors.focusColor)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Quote refresh interval")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(AppColors.primaryText)
                                    Spacer()
                                    Text("\(statsManager.settings.quoteRefreshInterval) min")
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                
                                Slider(value: $quoteInterval, in: 1...60, step: 1)
                                    .accentColor(AppColors.focusColor)
                                    .onChange(of: quoteInterval) { newValue in
                                        let intValue = Int(newValue)
                                        statsManager.settingsManager.quoteRefreshInterval = intValue
                                        quotesManager.setQuoteInterval(minutes: intValue)
                                    }
                                
                                Text("How often quotes change (applies to focus mode)")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Quote")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text("\"\(quotesManager.currentQuote)\"")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(AppColors.secondaryText)
                                    .italic()
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppColors.cardBackground)
                                    )
                                
                                Button("Get New Quote") {
                                    quotesManager.updateQuoteIfNeeded(force: true)
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(.all, 32)
        }
    }
    
    private func statsSettingsView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stats & Achievements")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Track your progress and unlock achievements")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: 32) {
                    // Stats Overview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Stats Overview")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        VStack(spacing: 16) {
                            HStack(spacing: 24) {
                                StatCard(
                                    title: "Total Focus Time",
                                    value: formatTime(statsManager.summary.totalFocusTime),
                                    icon: "clock.fill"
                                )
                                
                                StatCard(
                                    title: "Total Sessions",
                                    value: "\(statsManager.summary.totalSessions)",
                                    icon: "number.circle.fill"
                                )
                                
                                StatCard(
                                    title: "Completion Rate",
                                    value: String(format: "%.1f%%", statsManager.summary.completionRate),
                                    icon: "chart.pie.fill"
                                )
                            }
                            
                            HStack(spacing: 24) {
                                StatCard(
                                    title: "Current Streak",
                                    value: "\(statsManager.summary.currentStreak) days",
                                    icon: "flame.fill"
                                )
                                
                                StatCard(
                                    title: "Longest Streak",
                                    value: "\(statsManager.summary.bestStreak) days",
                                    icon: "trophy.fill"
                                )
                                
                                StatCard(
                                    title: "Avg. Session",
                                    value: formatTime(statsManager.summary.averageSessionLength),
                                    icon: "timer"
                                )
                            }
                        }
                    }
                    
                    // Achievements
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Achievements")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        VStack(spacing: 12) {
                            ForEach(statsManager.achievements) { achievement in
                                AchievementRow(achievement: achievement)
                            }
                        }
                    }
                    
                    // Stats Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Stats Settings")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        VStack(spacing: 16) {
                            Picker("Display Period", selection: Binding(
                                get: { statsManager.settingsManager.displayPeriod },
                                set: { statsManager.setDisplayPeriod($0) }
                            )) {
                                Text("Day").tag(StatsPeriod.day)
                                Text("Week").tag(StatsPeriod.week)
                                Text("Month").tag(StatsPeriod.month)
                                Text("All Time").tag(StatsPeriod.all)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            VStack(spacing: 12) {
                                Toggle("Show Streak", isOn: Binding(
                                    get: { statsManager.settingsManager.showStreakCounter },
                                    set: { newValue in statsManager.settingsManager.showStreakCounter = newValue }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: AppColors.focusColor))
                                
                                Toggle("Show Notifications", isOn: Binding(
                                    get: { statsManager.settingsManager.showNotifications },
                                    set: { newValue in statsManager.settingsManager.showNotifications = newValue }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: AppColors.focusColor))
                            }
                        }
                    }
                }
                
                Spacer(minLength: 200)
            }
            .padding(.all, 40)
        }
    }
    
    private func StatCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.focusColor)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
        )
    }
    
    private func AchievementRow(achievement: Achievement) -> some View {
        HStack(spacing: 16) {
            // Achievement Icon
            Text(achievement.icon)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(achievement.unlocked ? AppColors.focusColor : AppColors.cardBackground)
                        .opacity(achievement.unlocked ? 0.2 : 0.1)
                )
            
            // Achievement Info
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                Text(achievement.description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
                
                // Progress Bar
                ProgressView(value: achievement.progress, total: achievement.target)
                    .progressViewStyle(LinearProgressViewStyle(tint: achievement.unlocked ? AppColors.focusColor : AppColors.secondaryText))
                    .frame(height: 4)
            }
            
            Spacer()
            
            // Completion Status
            if achievement.unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.focusColor)
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .opacity(achievement.unlocked ? 0.3 : 0.1)
        )
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
    
    private func timerSettingsView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timer Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Customize your timer durations and behavior")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: 32) {
                    // Timer Durations
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Timer Durations")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        VStack(spacing: 24) {
                            DurationSettingRow(
                                title: "Focus Duration",
                                value: timerManager.focusDuration / 60,
                                onValueChanged: { timerManager.updateDuration(for: .focus, minutes: $0) }
                            )
                            
                            DurationSettingRow(
                                title: "Short Break Duration",
                                value: timerManager.shortBreakDuration / 60,
                                onValueChanged: { timerManager.updateDuration(for: .shortBreak, minutes: $0) }
                            )
                            
                            DurationSettingRow(
                                title: "Long Break Duration",
                                value: timerManager.longBreakDuration / 60,
                                onValueChanged: { timerManager.updateDuration(for: .longBreak, minutes: $0) }
                            )
                        }
                    }
                    
                    // Timer Behavior
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Timer Behavior")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        VStack(spacing: 12) {
                            Toggle("Auto-start next timer", isOn: Binding(
                                get: { statsManager.settingsManager.autoStartTimer },
                                set: { newValue in statsManager.settingsManager.autoStartTimer = newValue }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: AppColors.focusColor))
                            
                            Toggle("Play sound on completion", isOn: Binding(
                                get: { statsManager.settingsManager.soundEnabled },
                                set: { newValue in statsManager.settingsManager.soundEnabled = newValue }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: AppColors.focusColor))
                            
                            if statsManager.settingsManager.soundEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sound Volume")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    HStack {
                                        Slider(value: $soundVolume, in: 0...100, step: 1)
                                            .onChange(of: soundVolume) { newValue in
                                                let volume = Int(newValue)
                                                statsManager.settingsManager.soundVolume = volume
                                            }
                                        Text("\(statsManager.settingsManager.soundVolume)%")
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer(minLength: 200)
            }
            .padding(.all, 40)
        }
    }
    
    private func DurationSettingRow(title: String, value: Int, onValueChanged: @escaping (Int) -> Void) -> some View {
        HStack {
            Text(title)
                .foregroundColor(AppColors.secondaryText)
            Spacer()
            Button(action: {
                let newValue = max(1, value - 1)
                onValueChanged(newValue)
            }) {
                Image(systemName: "minus.circle")
                    .foregroundColor(AppColors.focusColor)
            }
            Text("\(value) min")
                .frame(width: 50)
                .foregroundColor(AppColors.primaryText)
            Button(action: {
                let newValue = value + 1
                onValueChanged(newValue)
            }) {
                Image(systemName: "plus.circle")
                    .foregroundColor(AppColors.focusColor)
            }
        }
    }
    
    private func soundSettingsView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sound & Notifications")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Customize your sound and notification preferences")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: 32) {
                    // Notification Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notification Settings")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        VStack(spacing: 16) {
                            Toggle("Enable Notifications", isOn: Binding(
                                get: { statsManager.settingsManager.showNotifications },
                                set: { newValue in statsManager.toggleNotifications() }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: AppColors.focusColor))
                            
                            Toggle("Enable Sound", isOn: Binding(
                                get: { statsManager.settingsManager.soundEnabled },
                                set: { newValue in statsManager.toggleSound() }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: AppColors.focusColor))
                            
                            if statsManager.settingsManager.soundEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sound Volume")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    HStack {
                                        Slider(value: $soundVolume, in: 0...100, step: 1)
                                            .onChange(of: soundVolume) { newValue in
                                                let volume = Int(newValue)
                                                statsManager.settingsManager.soundVolume = volume
                                            }
                                        Text("\(statsManager.settingsManager.soundVolume)%")
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Menu Bar Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Menu Bar Settings")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        menuBarSettingsView
                    }
                }
                
                Spacer(minLength: 200)
            }
            .padding(.all, 40)
        }
    }
    
    private var menuBarSettingsView: some View {
        VStack(spacing: 20) {
            Toggle("Show Timer in Menu Bar", isOn: Binding(
                get: { statsManager.settingsManager.showTimerInMenuBar },
                set: { newValue in statsManager.settingsManager.showTimerInMenuBar = newValue }
            ))
            
            Toggle("Show Notifications in Menu Bar", isOn: Binding(
                get: { statsManager.settingsManager.showNotificationsInMenuBar },
                set: { newValue in statsManager.settingsManager.showNotificationsInMenuBar = newValue }
            ))
        }
    }
    
    private func appearanceSettingsView(geometry: GeometryProxy) -> some View {
        placeholderView(title: "Appearance")
    }
    
    private func generalSettingsView(geometry: GeometryProxy) -> some View {
        placeholderView(title: "General Settings")
    }
    
    private func aboutView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("About MindraTimer")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("A focused productivity timer for macOS")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(AppColors.secondaryText)
                    Text("Version 1.0.0")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.secondaryText)
                }
                Spacer()
            }
            .padding(.all, 32)
        }
    }
    
    private func placeholderView(title: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                Text("Coming soon...")
                    .foregroundColor(AppColors.secondaryText)
                Spacer()
            }
            .padding(.all, 32)
        }
    }
    
    private func saveUserName() {
        userName = tempUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(userName.isEmpty ? nil : userName, forKey: "userName")
        quotesManager.setUserName(userName.isEmpty ? nil : userName)
        greetingManager.setUserName(userName.isEmpty ? nil : userName)
    }
}

enum SettingsSection: CaseIterable {
    case timer, clock, sounds, stats, profile, quotes, appearance, general, about
    
    var title: String {
        switch self {
        case .timer: return "Timer"
        case .clock: return "Clock"
        case .sounds: return "Sounds"
        case .stats: return "Statistics"
        case .profile: return "Profile"
        case .quotes: return "Quotes"
        case .appearance: return "Appearance"
        case .general: return "General"
        case .about: return "About"
        }
    }
}

#Preview {
    MindraSettingsView()
        .environmentObject(WindowManager())
        .environmentObject(StatsManager())
        .environmentObject(TimerManager())
        .environmentObject(AppModeManager())
        .environmentObject(QuotesManager())
        .environmentObject(GreetingManager())
}