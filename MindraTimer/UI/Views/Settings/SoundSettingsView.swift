//
//  SoundSettingsView.swift
//  MindraTimer
//
//  🔊 PREMIUM SOUND & NOTIFICATIONS SETTINGS
//  World-class audio settings with beautiful visualizations
//

import SwiftUI

struct SoundSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @EnvironmentObject var statsManager: StatsManager
    
    @State private var showSoundPreview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Sound & Notifications")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Customize your audio experience and notification preferences")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            VStack(spacing: 24) {
                // Core Audio Settings
                VStack(spacing: 16) {
                    SectionHeader(
                        title: "Audio Settings",
                        subtitle: "Control sounds and notification preferences",
                        icon: "speaker.wave.3",
                        color: AppColors.infoColor
                    )
                    
                    VStack(spacing: 12) {
                        ModernToggleCard(
                            title: "Enable Sound Notifications",
                            subtitle: "Audio alerts when timers complete",
                            icon: "speaker.wave.3.fill",
                            color: AppColors.infoColor,
                            isOn: Binding(
                                get: { coordinator.soundEnabled },
                                set: { coordinator.updateSoundEnabled($0, statsManager: statsManager) }
                            ),
                            description: "Play gentle, non-disruptive sounds when focus sessions and breaks complete to keep you informed without breaking concentration."
                        )
                        
                        ModernToggleCard(
                            title: "System Notifications",
                            subtitle: "Show macOS notification banners",
                            icon: "bell.fill",
                            color: AppColors.warningColor,
                            isOn: Binding(
                                get: { coordinator.showNotifications },
                                set: { coordinator.updateShowNotifications($0, statsManager: statsManager) }
                            ),
                            description: "Display notification banners in macOS when timers complete, including session summaries and motivational messages."
                        )
                    }
                }
                
                // Volume Control (only shown when sound is enabled)
                if coordinator.soundEnabled {
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Volume Control",
                            subtitle: "Fine-tune your notification audio levels",
                            icon: "speaker.2",
                            color: AppColors.focusColor
                        )
                        
                        ModernVolumeSlider(
                            title: "Notification Volume",
                            volume: $coordinator.soundVolume,
                            color: AppColors.focusColor
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
                
                // Sound Selection
                if coordinator.soundEnabled {
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Sound Selection",
                            subtitle: "Choose your preferred notification sound",
                            icon: "music.note",
                            color: AppColors.shortBreakColor
                        )
                        
                        ModernSoundPicker(
                            selectedSound: Binding(
                                get: { statsManager.settings.selectedSound.rawValue },
                                set: { newValue in
                                    statsManager.setSelectedSound(newValue)
                                }
                            ),
                            volume: coordinator.soundVolume,
                            showPreview: $showSoundPreview
                        )
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 1.05).combined(with: .opacity)
                    ))
                }
                
                // Menu Bar Settings
                VStack(spacing: 16) {
                    SectionHeader(
                        title: "Menu Bar Integration",
                        subtitle: "Control what appears in your menu bar",
                        icon: "menubar.rectangle",
                        color: AppColors.successColor
                    )
                    
                    VStack(spacing: 12) {
                        ModernToggleCard(
                            title: "Show Timer in Menu Bar",
                            subtitle: "Display countdown in menu bar",
                            icon: "timer",
                            color: AppColors.successColor,
                            isOn: Binding(
                                get: { coordinator.showTimerInMenuBar },
                                set: { coordinator.updateShowTimerInMenuBar($0, statsManager: statsManager) }
                            ),
                            description: "Keep track of your current session without switching apps. Shows remaining time and session type."
                        )
                        
                        ModernToggleCard(
                            title: "Menu Bar Notifications",
                            subtitle: "Show alerts in menu bar area",
                            icon: "bell.badge",
                            color: AppColors.longBreakColor,
                            isOn: Binding(
                                get: { coordinator.showNotificationsInMenuBar },
                                set: { coordinator.updateShowNotificationsInMenuBar($0, statsManager: statsManager) }
                            ),
                            description: "Display notification badges and alerts in the menu bar for quick access to session updates."
                        )
                    }
                }
                
                // Audio Tips Section
                VStack(spacing: 16) {
                    SectionHeader(
                        title: "Audio Tips",
                        subtitle: "Optimize your audio experience",
                        icon: "lightbulb.fill",
                        color: AppColors.warningColor
                    )
                    
                    TitledCard(
                        "Sound Optimization",
                        subtitle: "Best practices for productive audio"
                    ) {
                        VStack(spacing: 16) {
                            AudioTipRow(
                                icon: "speaker.2",
                                title: "Keep volume moderate (30-70%)",
                                description: "Audible without being jarring or disruptive",
                                color: AppColors.focusColor,
                                isOptimal: coordinator.soundVolume >= 30 && coordinator.soundVolume <= 70
                            )
                            
                            AudioTipRow(
                                icon: "bell.badge",
                                title: "Enable both sound and notifications",
                                description: "Dual alerts ensure you never miss a session end",
                                color: AppColors.infoColor,
                                isOptimal: coordinator.soundEnabled && coordinator.showNotifications
                            )
                            
                            AudioTipRow(
                                icon: "menubar.rectangle",
                                title: "Use menu bar timer for awareness",
                                description: "Stay focused while keeping track of time",
                                color: AppColors.successColor,
                                isOptimal: coordinator.showTimerInMenuBar
                            )
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.all, 40)
        .animation(Animation.spring(response: 0.4, dampingFraction: 0.8), value: coordinator.soundEnabled)
    }
}

// MARK: - Modern Sound Picker

struct ModernSoundPicker: View {
    @Binding var selectedSound: String
    let volume: Double
    @Binding var showPreview: Bool
    
    @State private var isPlayingPreview = false
    
    private let soundOptions: [(String, String, String)] = [
        ("bell", "Bell", "bell.fill"),
        ("chime", "Chime", "tuningfork"),
        ("ding", "Ding", "bell.circle.fill"),
        ("gentle", "Gentle", "waveform"),
        ("subtle", "Subtle", "speaker.wave.1.fill")
    ]
    
    var body: some View {
        AppCard(style: .elevated, shadow: .subtle) {
            VStack(spacing: 16) {
                // Header with preview button
                HStack {
                    Image(systemName: "music.note")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.shortBreakColor)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(AppColors.shortBreakColor.opacity(0.1))
                        )
                    
                    Text("Notification Sound")
                        .font(AppFonts.calloutSemibold)
                        .foregroundColor(AppColors.primaryText)
                    
                    Spacer()
                    
                    Button(action: {
                        playPreview()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isPlayingPreview ? "stop.fill" : "play.fill")
                                .font(.system(size: 12, weight: .medium))
                            Text(isPlayingPreview ? "Stop" : "Preview")
                                .font(AppFonts.caption)
                        }
                        .foregroundColor(AppColors.shortBreakColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppColors.shortBreakColor.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Sound options grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(soundOptions, id: \.0) { option in
                        SoundOptionCard(
                            soundId: option.0,
                            displayName: option.1,
                            icon: option.2,
                            isSelected: selectedSound == option.0,
                            volume: volume
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedSound = option.0
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func playPreview() {
        withAnimation(Animation.spring(response: 0.3, dampingFraction: 0.7)) {
            isPlayingPreview = true
        }
        
        // In a real implementation, you would play the actual sound here
        // AudioManager.shared.playSound(selectedSound, volume: volume)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(Animation.spring(response: 0.3, dampingFraction: 0.7)) {
                isPlayingPreview = false
            }
        }
    }
}

// MARK: - Sound Option Card

struct SoundOptionCard: View {
    let soundId: String
    let displayName: String
    let icon: String
    let isSelected: Bool
    let volume: Double
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon with waveform visualization
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [AppColors.shortBreakColor, AppColors.shortBreakColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [AppColors.tertiaryBackground, AppColors.tertiaryBackground],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : AppColors.tertiaryText)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .shadow(
                    color: isSelected ? AppColors.shortBreakColor.opacity(0.4) : .clear,
                    radius: isSelected ? 8 : 0,
                    x: 0,
                    y: isSelected ? 4 : 0
                )
                
                // Sound name
                Text(displayName)
                    .font(AppFonts.captionMedium)
                    .foregroundColor(isSelected ? AppColors.primaryText : AppColors.secondaryText)
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.shortBreakColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? AppColors.shortBreakColor.opacity(0.5) : AppColors.borderColor,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(Animation.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(Animation.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .onTapGesture {
            withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Audio Tip Row

struct AudioTipRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isOptimal: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isOptimal ? color : AppColors.tertiaryBackground)
                    .frame(width: 40, height: 40)
                
                Image(systemName: isOptimal ? "checkmark" : icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isOptimal ? .white : AppColors.tertiaryText)
            }
            .animation(Animation.spring(response: 0.3, dampingFraction: 0.7), value: isOptimal)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.calloutMedium)
                    .foregroundColor(isOptimal ? AppColors.secondaryText : AppColors.primaryText)
                    .strikethrough(isOptimal)
                
                Text(description)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#if DEBUG
struct SoundSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SoundSettingsView(coordinator: SettingsCoordinator())
            .environmentObject(StatsManager())
    }
}
#endif
