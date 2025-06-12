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
                subtitle: "Customize your focus sessions and timer behavior"
            ) {
                VStack(spacing: 24) {
                    // Timer Durations Section
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Timer Durations",
                            subtitle: "Set perfect time blocks for your workflow",
                            icon: "clock.badge"
                        )
                        
                        VStack(spacing: 12) {
                            ModernDurationPicker(
                                title: "Focus Duration",
                                icon: "brain.head.profile",
                                value: timerManager.focusDuration / 60,
                                range: 5...90,
                                color: AppColors.focusColor
                            ) { newValue in
                                timerManager.updateDuration(for: .focus, minutes: newValue)
                            }
                            
                            ModernDurationPicker(
                                title: "Short Break",
                                icon: "cup.and.saucer.fill",
                                value: timerManager.shortBreakDuration / 60,
                                range: 3...30,
                                color: AppColors.shortBreakColor
                            ) { newValue in
                                timerManager.updateDuration(for: .shortBreak, minutes: newValue)
                            }
                            
                            ModernDurationPicker(
                                title: "Long Break",
                                icon: "moon.stars.fill",
                                value: timerManager.longBreakDuration / 60,
                                range: 10...60,
                                color: AppColors.longBreakColor
                            ) { newValue in
                                timerManager.updateDuration(for: .longBreak, minutes: newValue)
                            }
                        }
                    }
                    
                    // Timer Behavior Section
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Automation Settings",
                            subtitle: "Configure how timers transition between modes",
                            icon: "gearshape.2"
                        )
                        
                        VStack(spacing: 12) {
                            ModernToggleCard(
                                title: "Auto-start Next Timer",
                                subtitle: "Seamless workflow transitions",
                                icon: "play.circle.fill",
                                color: AppColors.successColor,
                                isOn: Binding(
                                    get: { coordinator.autoStartTimer },
                                    set: { coordinator.updateAutoStartTimer($0, statsManager: statsManager) }
                                ),
                                description: "Automatically start the next timer when the current one completes. Perfect for maintaining flow state."
                            )
                            
                            ModernToggleCard(
                                title: "Sound Notifications",
                                subtitle: "Audio alerts for timer completion",
                                icon: "speaker.wave.3.fill",
                                color: AppColors.infoColor,
                                isOn: Binding(
                                    get: { coordinator.soundEnabled },
                                    set: { coordinator.updateSoundEnabled($0, statsManager: statsManager) }
                                ),
                                description: "Play a gentle sound when timers complete to notify you without being disruptive."
                            )
                        }
                    }
                    
                    // Volume Control (only shown when sound is enabled)
                    if coordinator.soundEnabled {
                        VStack(spacing: 16) {
                            SectionHeader(
                                title: "Audio Settings",
                                subtitle: "Fine-tune your notification sounds",
                                icon: "waveform"
                            )
                            
                            ModernVolumeSlider(
                                title: "Notification Volume",
                                volume: $coordinator.soundVolume,
                                color: AppColors.infoColor
                            ) { newValue in
                                coordinator.updateSoundVolume(newValue)
                                statsManager.setSoundVolume(newValue)
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 1.05).combined(with: .opacity)
                        ))
                    }
                    
                    // Timer Tips Section
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Pro Tips",
                            subtitle: "Maximize your productivity with these insights",
                            icon: "lightbulb.fill"
                        )
                        
                        TitledCard(
                            "Pomodoro Technique",
                            subtitle: "Science-backed time management"
                        ) {
                            VStack(spacing: 12) {
                                TipRow(
                                    icon: "brain",
                                    title: "25-minute focus blocks",
                                    description: "Optimal attention span for deep work",
                                    color: AppColors.focusColor
                                )
                                
                                TipRow(
                                    icon: "leaf",
                                    title: "5-minute short breaks",
                                    description: "Quick refresh without losing momentum",
                                    color: AppColors.shortBreakColor
                                )
                                
                                TipRow(
                                    icon: "moon.stars",
                                    title: "15-minute long breaks",
                                    description: "Complete mental reset every 4 cycles",
                                    color: AppColors.longBreakColor
                                )
                            }
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: coordinator.soundEnabled)
    }
    
    // MARK: - Helper Views
    
    private func SectionHeader(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppColors.focusColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(AppColors.focusColor.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.cardTitle)
                    .foregroundColor(AppColors.primaryText)
                
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
    }
    
    private func TipRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.captionSemibold)
                    .foregroundColor(AppColors.primaryText)
                
                Text(description)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct ProfileSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @EnvironmentObject var quotesManager: QuotesManager
    @EnvironmentObject var greetingManager: GreetingManager
    
    @State private var isEditing = false
    @State private var tempName = ""
    
    var body: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: "Profile Settings",
                subtitle: "Customize your personal information and preferences"
            ) {
                VStack(spacing: 24) {
                    // Profile Display Card
                    if !isEditing {
                        ProfileDisplayCard(
                            name: coordinator.userName,
                            subtitle: getProfileSubtitle()
                        ) {
                            startEditing()
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 1.05).combined(with: .opacity)
                        ))
                    }
                    
                    // Edit Mode
                    if isEditing {
                        VStack(spacing: 20) {
                            TitledCard(
                                "Edit Profile",
                                subtitle: "Update your personal information",
                                style: .elevated
                            ) {
                                VStack(spacing: 20) {
                                    ModernInputField(
                                        label: "Your Name",
                                        placeholder: "Enter your name",
                                        text: $tempName,
                                        icon: "person.fill",
                                        helpText: "Used for personalized greetings and quotes",
                                        maxLength: 50
                                    )
                                    
                                    // Action buttons
                                    HStack(spacing: 12) {
                                        AppButton.secondary(
                                            "Cancel",
                                            action: { cancelEditing() },
                                            size: .medium,
                                            icon: "xmark"
                                        )
                                        
                                        AppButton.primary(
                                            coordinator.userName.isEmpty ? "Add Name" : "Save Changes",
                                            action: { saveProfile() },
                                            size: .medium,
                                            isEnabled: !tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                            icon: "checkmark"
                                        )
                                    }
                                    
                                    if !coordinator.userName.isEmpty {
                                        AppButton.destructive(
                                            "Remove Name",
                                            action: { removeName() },
                                            size: .small,
                                            icon: "trash"
                                        )
                                    }
                                }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 1.05).combined(with: .opacity)
                        ))
                    }
                    
                    // Profile Stats Card
                    if !coordinator.userName.isEmpty {
                        TitledCard(
                            "Profile Stats",
                            subtitle: "Your personalization impact"
                        ) {
                            VStack(spacing: 12) {
                                StatRow(
                                    icon: "quote.bubble.fill",
                                    title: "Personalized Quotes",
                                    value: coordinator.enablePersonalizedQuotes ? "Enabled" : "Disabled",
                                    color: coordinator.enablePersonalizedQuotes ? AppColors.successColor : AppColors.tertiaryText
                                )
                                
                                StatRow(
                                    icon: "hand.wave.fill",
                                    title: "Personal Greetings",
                                    value: coordinator.showGreetings ? "Enabled" : "Disabled",
                                    color: coordinator.showGreetings ? AppColors.successColor : AppColors.tertiaryText
                                )
                                
                                StatRow(
                                    icon: "calendar.badge.clock",
                                    title: "Profile Created",
                                    value: getProfileCreationDate(),
                                    color: AppColors.secondaryText
                                )
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Tips Card
                    TitledCard(
                        "Profile Tips",
                        subtitle: "Make the most of your MindraTimer experience"
                    ) {
                        VStack(spacing: 16) {
                            TipRow(
                                icon: "lightbulb.fill",
                                title: "Add your name for personalized greetings",
                                description: "Get motivational messages tailored to you",
                                isCompleted: !coordinator.userName.isEmpty
                            )
                            
                            TipRow(
                                icon: "quote.bubble.fill",
                                title: "Enable personalized quotes",
                                description: "Quotes will include your name for extra motivation",
                                isCompleted: coordinator.enablePersonalizedQuotes
                            )
                            
                            TipRow(
                                icon: "gear.badge",
                                title: "Customize your experience",
                                description: "Explore other settings to make MindraTimer yours",
                                isCompleted: false
                            )
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isEditing)
        .onAppear {
            tempName = coordinator.tempUserName
        }
    }
    
    // MARK: - Helper Views
    
    private func StatRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(AppFonts.calloutMedium)
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.captionSemibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
    
    private func TipRow(icon: String, title: String, description: String, isCompleted: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? AppColors.successColor : AppColors.cardBackground)
                    .frame(width: 32, height: 32)
                
                Image(systemName: isCompleted ? "checkmark" : icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isCompleted ? .white : AppColors.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.calloutMedium)
                    .foregroundColor(isCompleted ? AppColors.secondaryText : AppColors.primaryText)
                    .strikethrough(isCompleted)
                
                Text(description)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.3), value: isCompleted)
    }
    
    // MARK: - Helper Methods
    
    private func startEditing() {
        tempName = coordinator.userName
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isEditing = true
        }
    }
    
    private func cancelEditing() {
        tempName = coordinator.userName
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isEditing = false
        }
    }
    
    private func saveProfile() {
        coordinator.tempUserName = tempName
        coordinator.saveUserName()
        quotesManager.setUserName(coordinator.userName.isEmpty ? nil : coordinator.userName)
        greetingManager.setUserName(coordinator.userName.isEmpty ? nil : coordinator.userName)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isEditing = false
        }
    }
    
    private func removeName() {
        coordinator.tempUserName = ""
        coordinator.saveUserName()
        quotesManager.setUserName(nil)
        greetingManager.setUserName(nil)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isEditing = false
        }
    }
    
    private func getProfileSubtitle() -> String? {
        if coordinator.userName.isEmpty {
            return nil
        }
        
        let features = [
            coordinator.enablePersonalizedQuotes ? "Personalized Quotes" : nil,
            coordinator.showGreetings ? "Personal Greetings" : nil
        ].compactMap { $0 }
        
        return features.isEmpty ? nil : features.joined(separator: " • ")
    }
    
    private func getProfileCreationDate() -> String {
        // In a real app, you'd store the actual creation date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
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
                                .onChange(of: coordinator.quoteInterval) { _, newValue in
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
                                        .onChange(of: coordinator.soundVolume) { _, newValue in
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
                        
                        Button("Database Debug Info") {
                            let debugInfo = statsManager.database.getDebugInfo()
                            print(debugInfo)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Clear All Data") {
                            statsManager.clearAllData()
                        }
                        .buttonStyle(SecondaryButtonStyle())
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

// StatCard is now imported from UI/Components/Common/AppCard.swift

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
