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
                            icon: "clock.badge",
                            color: AppColors.focusColor
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
                            icon: "gearshape.2",
                            color: AppColors.successColor
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
                                icon: "waveform",
                                color: AppColors.infoColor
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
                            icon: "lightbulb.fill",
                            color: AppColors.warningColor
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
        .animation(Animation.spring(response: 0.4, dampingFraction: 0.8), value: coordinator.soundEnabled)
    }
    
    // MARK: - Helper Views
    
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
        .animation(Animation.spring(response: 0.4, dampingFraction: 0.8), value: isEditing)
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
        withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.8)) {
            isEditing = true
        }
    }
    
    private func cancelEditing() {
        tempName = coordinator.userName
        withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.8)) {
            isEditing = false
        }
    }
    
    private func saveProfile() {
        coordinator.tempUserName = tempName
        coordinator.saveUserName()
        quotesManager.setUserName(coordinator.userName.isEmpty ? nil : coordinator.userName)
        greetingManager.setUserName(coordinator.userName.isEmpty ? nil : coordinator.userName)
        
        withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.8)) {
            isEditing = false
        }
    }
    
    private func removeName() {
        coordinator.tempUserName = ""
        coordinator.saveUserName()
        quotesManager.setUserName(nil)
        greetingManager.setUserName(nil)
        
        withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.8)) {
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

struct ClockSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @EnvironmentObject var statsManager: StatsManager
    
    var body: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: "Clock Settings",
                subtitle: "Customize your clock display"
            ) {
                VStack(spacing: 24) {
                    SettingsToggleRow(
                        title: "Show greetings",
                        description: "Display personalized greetings",
                        isOn: Binding(
                            get: { coordinator.showGreetings },
                            set: { coordinator.updateShowGreetings($0, statsManager: statsManager) }
                        ),
                        action: { newValue in
                            coordinator.updateShowGreetings(newValue, statsManager: statsManager)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Settings Toggle Row Component

struct SettingsToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let action: (Bool) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                Text(description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    isOn = newValue
                    action(newValue)
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
        }
        .padding(.vertical, 8)
    }
}
