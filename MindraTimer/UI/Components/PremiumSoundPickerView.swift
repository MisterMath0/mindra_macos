//
//  PremiumSoundPickerView.swift
//  MindraTimer
//
//  🎵 PREMIUM SOUND PICKER DIALOG
//  Beautiful sound selection interface with live previews
//

import SwiftUI
import AVFoundation

struct PremiumSoundPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var audioService: AudioService
    
    @State private var selectedSound: SoundOption
    @State private var volume: Double
    @State private var isPlaying = false
    @State private var currentlyPlayingSound: SoundOption?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)
    
    private var soundEmojis: [SoundOption: String] = [
        .sparkle: "✨",
        .chime: "🎵",
        .bellSoft: "🔕",
        .bellLoud: "🔔",
        .trainArrival: "🚂",
        .commuterJingle: "🎶",
        .gameShow: "🎪"
    ]
    
    private var soundDescriptions: [SoundOption: String] = [
        .sparkle: "Gentle magical tone",
        .chime: "Classic bell sound",
        .bellSoft: "Subtle notification",
        .bellLoud: "Clear strong bell",
        .trainArrival: "Distinctive arrival tone",
        .commuterJingle: "Pleasant melody",
        .gameShow: "Exciting fanfare sound"
    ]
    
    init() {
        // Initialize with current settings
        let currentSound = UserDefaults.standard.string(forKey: "selectedSound") ?? "sparkle"
        let currentVolume = UserDefaults.standard.object(forKey: "soundVolume") as? Int ?? 70
        
        self._selectedSound = State(initialValue: SoundOption(rawValue: currentSound) ?? .sparkle)
        self._volume = State(initialValue: Double(currentVolume))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sound Effects")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Choose your notification sound")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.tertiaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Divider()
                    .background(AppColors.borderColor)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Sound Grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(SoundOption.allCases, id: \.self) { sound in
                            PremiumSoundCard(
                                sound: sound,
                                emoji: soundEmojis[sound] ?? "🎵",
                                description: soundDescriptions[sound] ?? "",
                                isSelected: selectedSound == sound,
                                isPlaying: currentlyPlayingSound == sound && isPlaying,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedSound = sound
                                        playPreview(sound)
                                    }
                                },
                                onPreview: {
                                    playPreview(sound)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Volume Control
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.focusColor)
                            
                            Text("Volume")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "speaker.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Slider(value: $volume, in: 0...100, step: 1)
                                    .accentColor(AppColors.focusColor)
                                    .onChange(of: volume) { newValue in
                                        statsManager.setSoundVolume(newValue)
                                    }
                                
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Text("\(Int(volume))%")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.tertiaryText)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.cardBackground)
                    )
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }
            
            // Footer Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.secondaryText)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.tertiaryBackground)
                )
                .buttonStyle(PlainButtonStyle())
                
                Button("Play & Save") {
                    saveSelection()
                    playPreview(selectedSound)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.focusColor)
                )
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .frame(width: 520, height: 600)
        .background(AppColors.primaryBackground)
        .onDisappear {
            audioService.stopCurrentSound()
        }
    }
    
    private func playPreview(_ sound: SoundOption) {
        // Stop any currently playing sound
        audioService.stopCurrentSound()
        
        // Update playing state
        currentlyPlayingSound = sound
        isPlaying = true
        
        // Play the sound
        audioService.playSound(sound, volume: Float(volume / 100.0))
        
        // Auto-stop after a reasonable duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isPlaying = false
            currentlyPlayingSound = nil
        }
    }
    
    private func saveSelection() {
        statsManager.setSelectedSound(selectedSound.rawValue)
        statsManager.setSoundVolume(volume)
        
        print("🔊 Sound settings saved: \(selectedSound.displayName) at \(Int(volume))%")
    }
}

// MARK: - Premium Sound Card

struct PremiumSoundCard: View {
    let sound: SoundOption
    let emoji: String
    let description: String
    let isSelected: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    let onPreview: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Main card content
            VStack(spacing: 12) {
                // Emoji with animation
                ZStack {
                    Circle()
                        .fill(
                            isSelected 
                                ? AppColors.focusColor.opacity(0.2)
                                : AppColors.cardBackground
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? AppColors.focusColor : AppColors.borderColor,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                    
                    Text(emoji)
                        .font(.system(size: 28))
                        .scaleEffect(isPlaying ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPlaying)
                }
                
                // Sound name
                Text(sound.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? AppColors.focusColor : AppColors.primaryText)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(description)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.tertiaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Play button
            Button(action: onPreview) {
                HStack(spacing: 4) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 10, weight: .medium))
                    Text(isPlaying ? "Stop" : "Preview")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(isSelected ? .white : AppColors.focusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? AppColors.focusColor : AppColors.focusColor.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? AppColors.focusColor : (isHovered ? AppColors.borderColor.opacity(0.6) : AppColors.borderColor),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ? AppColors.focusColor.opacity(0.3) : .clear,
                    radius: isSelected ? 8 : 0,
                    x: 0,
                    y: isSelected ? 4 : 0
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            
            onTap()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
    }
}

#Preview {
    PremiumSoundPickerView()
        .environmentObject(StatsManager())
        .environmentObject(AudioService())
}
