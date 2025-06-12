//
//  AudioService.swift
//  MindraTimer
//
//  Centralized audio playback service
//

import Foundation
import AVFoundation
import AppKit

protocol AudioServiceProtocol {
    func playSound(_ sound: SoundOption, volume: Float)
    func stopCurrentSound()
    func preloadSounds()
}

class AudioService: AudioServiceProtocol, ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var preloadedSounds: [SoundOption: AVAudioPlayer] = [:]
    
    init() {
        setupAudioSession()
        preloadSounds()
    }
    
    // MARK: - Public Methods
    
    func playSound(_ sound: SoundOption, volume: Float = 0.7) {
        // Stop any currently playing sound
        stopCurrentSound()
        
        // Try to use preloaded sound first
        if let preloadedPlayer = preloadedSounds[sound] {
            preloadedPlayer.volume = volume
            preloadedPlayer.currentTime = 0 // Reset to beginning
            preloadedPlayer.play()
            audioPlayer = preloadedPlayer
            return
        }
        
        // Fallback to loading sound on demand
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") else {
            print("🔊 Sound file not found: \(sound.fileName).mp3")
            playSystemBeep()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.play()
            print("🔊 Playing sound: \(sound.displayName)")
        } catch {
            print("🔊 Error playing sound \(sound.displayName): \(error)")
            playSystemBeep()
        }
    }
    
    func stopCurrentSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func preloadSounds() {
        print("🔊 Preloading sounds...")
        
        for sound in SoundOption.allCases {
            guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") else {
                print("🔊 Warning: Sound file not found for preloading: \(sound.fileName).mp3")
                continue
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                preloadedSounds[sound] = player
                print("🔊 Preloaded: \(sound.displayName)")
            } catch {
                print("🔊 Error preloading sound \(sound.displayName): \(error)")
            }
        }
        
        print("🔊 Preloaded \(preloadedSounds.count)/\(SoundOption.allCases.count) sounds")
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        // macOS doesn't require audio session management like iOS
        // AVAudioPlayer handles audio routing automatically
        print("🔊 Audio service ready for macOS")
    }
    
    private func playSystemBeep() {
        NSSound.beep()
    }
    
    // MARK: - Testing and Debug
    
    func testSound(_ sound: SoundOption) {
        print("🔊 Testing sound: \(sound.displayName)")
        playSound(sound, volume: 0.5)
    }
    
    func getAvailableSounds() -> [SoundOption] {
        return SoundOption.allCases.filter { sound in
            Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") != nil
        }
    }
    
    func getSoundInfo() -> String {
        let available = getAvailableSounds()
        let preloaded = preloadedSounds.keys.map { $0.displayName }.sorted()
        
        return """
        🔊 Audio Service Info:
        • Available sounds: \(available.count)/\(SoundOption.allCases.count)
        • Preloaded: \(preloaded.joined(separator: ", "))
        • Current player: \(audioPlayer != nil ? "Active" : "None")
        """
    }
}

// MARK: - Mock Service for Testing

class MockAudioService: AudioServiceProtocol {
    private(set) var lastPlayedSound: SoundOption?
    private(set) var lastVolume: Float?
    private(set) var playCount = 0
    private(set) var stopCount = 0
    
    func playSound(_ sound: SoundOption, volume: Float) {
        lastPlayedSound = sound
        lastVolume = volume
        playCount += 1
        print("🔊 Mock: Playing \(sound.displayName) at volume \(volume)")
    }
    
    func stopCurrentSound() {
        stopCount += 1
        print("🔊 Mock: Stopping sound")
    }
    
    func preloadSounds() {
        print("🔊 Mock: Preloading sounds")
    }
    
    func reset() {
        lastPlayedSound = nil
        lastVolume = nil
        playCount = 0
        stopCount = 0
    }
}
