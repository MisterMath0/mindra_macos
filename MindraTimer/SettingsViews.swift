//
//  SettingsViews.swift
//  MindraTimer
//
//  Individual settings view implementations for the refactored settings
//

import SwiftUI

// MARK: - Individual Settings Views

struct TimerSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var statsManager: StatsManager
    
    var body: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: "Timer Settings",
                subtitle: "Customize your timer durations and behavior"
            ) {
                SettingsCard(title: "Timer Durations") {
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
                
                SettingsCard(title: "Timer Behavior") {
                    VStack(spacing: 12) {
                        SettingsToggle(
                            title: "Auto-start next timer",
                            isOn: Binding(
                                get: { coordinator.autoStartTimer },
                                set: { coordinator.updateAutoStartTimer($0, statsManager: statsManager) }
                            )
                        )
                        
                        SettingsToggle(
                            title: "Play sound on completion",
                            isOn: Binding(
                                get: { coordinator.soundEnabled },
                                set: { coordinator.updateSoundEnabled($0, statsManager: statsManager) }
                            )
                        )
                        
                        if coordinator.soundEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sound Volume")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.primaryText)
                                
                                HStack {
                                    Slider(value: $coordinator.soundVolume, in: 0...100, step: 1)
                                        .onChange(of: coordinator.soundVolume) { newValue in
                                            coordinator.updateSoundVolume(newValue)
                                            statsManager.setSoundVolume(newValue)
                                        }
                                    
                                    Text("\(Int(coordinator.soundVolume))%")
                                        .foregroundColor(AppColors.secondaryText)
                                        .frame(width: 40)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ProfileSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @EnvironmentObject var quotesManager: QuotesManager
    @EnvironmentObject var greetingManager: GreetingManager
    
    var body: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: "Profile Settings",
                subtitle: "Customize your personal information"
            ) {
                SettingsCard(title: "Your Name") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Enter your name", text: $coordinator.tempUserName)
                            .textFieldStyle(ModernTextFieldStyle())
                            .onSubmit { saveUserName() }
                            .frame(maxWidth: 400)
                        
                        Text("Used for personalized greetings and quotes")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.secondaryText)
                        
                        HStack(spacing: 12) {
                            Button("Save") { saveUserName() }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(coordinator.tempUserName.trimmingCharacters(in: .whitespacesAndNewlines) == coordinator.userName)
                            
                            if !coordinator.userName.isEmpty {
                                Button("Clear") {
                                    coordinator.tempUserName = ""
                                    saveUserName()
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveUserName() {
        coordinator.saveUserName()
        quotesManager.setUserName(coordinator.userName.isEmpty ? nil : coordinator.userName)
        greetingManager.setUserName(coordinator.userName.isEmpty ? nil : coordinator.userName)
    }
}

struct QuotesSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var quotesManager: QuotesManager
    
    var body: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: "Quotes Settings",
                subtitle: "Customize your inspirational quotes"
            ) {
                SettingsCard(title: "Quote Preferences") {
                    VStack(spacing: 16) {
                        SettingsToggle(
                            title: "Show quotes",
                            isOn: Binding(
                                get: { coordinator.showQuotes },
                                set: { coordinator.updateShowQuotes($0, statsManager: statsManager) }
                            )
                        )
                        
                        if coordinator.showQuotes {
                            SettingsToggle(
                                title: "Enable personalized quotes",
                                isOn: Binding(
                                    get: { coordinator.enablePersonalizedQuotes },
                                    set: { coordinator.updateEnablePersonalizedQuotes($0, statsManager: statsManager, quotesManager: quotesManager) }
                                )
                            )
                        }
                    }
                }
                
                if coordinator.showQuotes {
                    SettingsCard(title: "Quote Categories") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select the types of quotes you'd like to see")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(AppColors.secondaryText)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(QuoteCategory.allCases, id: \.self) { category in
                                    SettingsToggle(
                                        title: category.displayName,
                                        isOn: Binding(
                                            get: { statsManager.settings.selectedQuoteCategories.contains(category) },
                                            set: { isOn in
                                                if isOn {
                                                    statsManager.settings.selectedQuoteCategories.append(category)
                                                } else {
                                                    statsManager.settings.selectedQuoteCategories.removeAll { $0 == category }
                                                }
                                            }
                                        )
                                    )
                                }
                            }
                        }
                    }
                    
                    SettingsCard(title: "Quote Refresh Interval") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Change quotes every")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.primaryText)
                                
                                Spacer()
                                
                                Text("\(Int(coordinator.quoteInterval)) min")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Slider(value: $coordinator.quoteInterval, in: 1...60, step: 1)
                                .accentColor(AppColors.focusColor)
                                .onChange(of: coordinator.quoteInterval) { newValue in
                                    let intValue = Int(newValue)
                                    coordinator.updateQuoteInterval(newValue)
                                    statsManager.settingsManager.quoteRefreshInterval = intValue
                                    quotesManager.setQuoteInterval(minutes: intValue)
                                }
                            
                            Text("How often quotes change (applies to focus mode)")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    
                    SettingsCard(title: "Current Quote") {
                        VStack(alignment: .leading, spacing: 12) {
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
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                }
            }
        }
    }
}

struct SoundSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @EnvironmentObject var statsManager: StatsManager
    
    var body: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: "Sound & Notifications",
                subtitle: "Customize your sound and notification preferences"
            ) {
                SettingsCard(title: "Notification Settings") {
                    VStack(spacing: 16) {
                        SettingsToggle(
                            title: "Enable Notifications",
                            isOn: Binding(
                                get: { coordinator.showNotifications },
                                set: { coordinator.updateShowNotifications($0, statsManager: statsManager) }
                            )
                        )
                        
                        SettingsToggle(
                            title: "Enable Sound",
                            isOn: Binding(
                                get: { coordinator.soundEnabled },
                                set: { coordinator.updateSoundEnabled($0, statsManager: statsManager) }
                            )
                        )
                        
                        if coordinator.soundEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sound Volume")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.primaryText)
                                
                                HStack {
                                    Slider(value: $coordinator.soundVolume, in: 0...100, step: 1)
                                        .onChange(of: coordinator.soundVolume) { newValue in
                                            coordinator.updateSoundVolume(newValue)
                                            statsManager.setSoundVolume(newValue)
                                        }
                                    
                                    Text("\(Int(coordinator.soundVolume))%")
                                        .foregroundColor(AppColors.secondaryText)
                                        .frame(width: 40)
                                }
                            }
                        }
                    }
                }
                
                SettingsCard(title: "Menu Bar Settings") {
                    VStack(spacing: 12) {
                        SettingsToggle(
                            title: "Show Timer in Menu Bar",
                            isOn: Binding(
                                get: { coordinator.showTimerInMenuBar },
                                set: { coordinator.updateShowTimerInMenuBar($0, statsManager: statsManager) }
                            )
                        )
                        
                        SettingsToggle(
                            title: "Show Notifications in Menu Bar",
                            isOn: Binding(
                                get: { coordinator.showNotificationsInMenuBar },
                                set: { coordinator.updateShowNotificationsInMenuBar($0, statsManager: statsManager) }
                            )
                        )
                    }
                }
            }
        }
    }
}

struct ClockSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @EnvironmentObject var statsManager: StatsManager
    
    var body: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: "Clock Settings",
                subtitle: "Customize your clock display"
            ) {
                SettingsCard(title: "Clock Preferences") {
                    SettingsToggle(
                        title: "Show greetings",
                        isOn: Binding(
                            get: { coordinator.showGreetings },
                            set: { coordinator.updateShowGreetings($0, statsManager: statsManager) }
                        )
                    )
                }
            }
        }
    }
}

struct StatsSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @EnvironmentObject var statsManager: StatsManager
    
    var body: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: "Stats & Achievements",
                subtitle: "Track your progress and unlock achievements"
            ) {
                SettingsCard(title: "Stats Overview") {
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
                
                SettingsCard(title: "Stats Settings") {
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
                            SettingsToggle(
                                title: "Show Streak",
                                isOn: Binding(
                                    get: { coordinator.showStreakCounter },
                                    set: { coordinator.updateShowStreakCounter($0, statsManager: statsManager) }
                                )
                            )
                            
                            SettingsToggle(
                                title: "Show Notifications",
                                isOn: Binding(
                                    get: { coordinator.showStatsNotifications },
                                    set: { coordinator.updateShowStatsNotifications($0, statsManager: statsManager) }
                                )
                            )
                        }
                    }
                }
                
                SettingsCard(title: "Achievements") {
                    VStack(spacing: 12) {
                        if statsManager.achievements.isEmpty {
                            Text("No achievements available yet")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(AppColors.secondaryText)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(statsManager.achievements) { achievement in
                                AchievementRow(achievement: achievement)
                            }
                        }
                    }
                }
                
                // Debug section (only shown in DEBUG builds)
                #if DEBUG
                SettingsCard(title: "Debug Tools") {
                    VStack(spacing: 12) {
                        Button("Debug Achievements") {
                            statsManager.debugAchievements()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Debug Stats") {
                            statsManager.debugStats()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Add Test Data") {
                            statsManager.addTestData()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                #endif
            }
        }
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return String(format: "%d:%02d h", hours, remainingMinutes)
        } else {
            return String(format: "%d min", minutes)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
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
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
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
}

struct AboutSettingsView: View {
    var body: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: "About MindraTimer",
                subtitle: "A focused productivity timer for macOS"
            ) {
                SettingsCard(title: "Version Information") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Version 1.0.0")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Built with SwiftUI for macOS")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
        }
    }
}

struct PlaceholderSettingsView: View {
    let title: String
    
    var body: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: title,
                subtitle: "Coming soon..."
            ) {
                SettingsCard(title: "Under Development") {
                    Text("This section is currently being developed.")
                        .foregroundColor(AppColors.secondaryText)
                }
            }
        }
    }
}
