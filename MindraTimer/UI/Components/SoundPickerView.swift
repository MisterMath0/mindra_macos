import SwiftUI
import AVFoundation

struct SoundPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var statsManager: StatsManager
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    @State private var selectedSound: SoundOption?
    @State private var isPlaying = false
    @StateObject private var audioService = AudioService()
    
    private var soundEmojis: [SoundOption: String] = [
        .sparkle: "✨",
        .chime: "🎵",
        .bellSoft: "🔔",
        .bellLoud: "🔔",
        .trainArrival: "🚂",
        .commuterJingle: "🎶",
        .gameShow: "🎪"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Sound Effects")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Sound grid
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(SoundOption.allCases, id: \.self) { sound in
                    soundButton(sound)
                }
            }
            .padding(.horizontal)
            
            // Volume slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Volume")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
                
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(AppColors.secondaryText)
                    Slider(value: Binding(
                        get: { Double(statsManager.settings.soundVolume) },
                        set: { statsManager.setSoundVolume($0) }
                    ), in: 0...100)
                    .accentColor(AppColors.focusColor)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .padding(.horizontal)
        }
        .padding(24)
        .frame(width: 400, height: 400)
        .background(AppColors.primaryBackground)
    }
    
    private func soundButton(_ sound: SoundOption) -> some View {
        Button(action: {
            selectedSound = sound
            statsManager.setSelectedSound(sound.rawValue)
            
            // Use AudioService to play the sound
            let volume = Float(statsManager.settings.soundVolume) / 100.0
            audioService.playSound(sound, volume: volume)
        }) {
            VStack(spacing: 8) {
                Text(soundEmojis[sound] ?? "🎵")
                    .font(.system(size: 24))
                Text(sound.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedSound == sound ? AppColors.selectedBackground : AppColors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SoundPickerView()
        .environmentObject(StatsManager())
} 