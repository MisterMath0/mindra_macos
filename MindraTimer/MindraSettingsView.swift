//
//  MindraSettingsView.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 09.06.25.
//

import SwiftUI

struct MindraSettingsView: View {
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var appModeManager: AppModeManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: SettingsSection = .timer
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left sidebar
                sidebar(geometry: geometry)
                
                // Main content area
                mainContent(geometry: geometry)
            }
            .background(Color(red: 0.05, green: 0.05, blue: 0.05))
        }
        .frame(width: 900, height: 650)
    }
    
    // MARK: - Sidebar
    
    private func sidebar(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
            
            // Navigation sections
            VStack(alignment: .leading, spacing: 24) {
                sectionGroup(
                    title: "CORE",
                    items: [
                        (.timer, "timer", "Timer"),
                        (.clock, "clock", "Clock"),
                        (.sounds, "speaker.wave.2", "Sounds"),
                        (.stats, "chart.bar", "Stats")
                    ],
                    geometry: geometry
                )
                
                sectionGroup(
                    title: "OTHER",
                    items: [
                        (.general, "gearshape", "General"),
                        (.about, "info.circle", "About")
                    ],
                    geometry: geometry
                )
            }
            .padding(.leading, 24)
            
            Spacer()
            
            // Debug section (development only)
            if AppConfiguration.isDebug {
                VStack(spacing: 8) {
                    Button("Add Test Data") {
                        statsManager.addTestData()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Clear All Data") {
                        statsManager.clearAllData()
                    }
                    .foregroundColor(.red)
                }
                .font(.system(size: 12))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            
            // App info
            VStack(spacing: 4) {
                Text("MindraTimer")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Version 1.0.0")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: geometry.size.width * 0.3)
        .background(Color(red: 0.05, green: 0.05, blue: 0.05))
    }
    
    private func sectionGroup(title: String, items: [(SettingsSection, String, String)], geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.0) { item in
                    sidebarItem(
                        section: item.0,
                        icon: item.1,
                        title: item.2,
                        geometry: geometry
                    )
                }
            }
        }
    }
    
    private func sidebarItem(section: SettingsSection, icon: String, title: String, geometry: GeometryProxy) -> some View {
        Button(action: { selectedSection = section }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedSection == section ? .white : .white.opacity(0.6))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(selectedSection == section ? .white : .white.opacity(0.6))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedSection == section ? Color.white.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Main Content
    
    private func mainContent(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            switch selectedSection {
            case .timer:
                timerSettingsView(geometry: geometry)
            case .clock:
                clockSettingsView(geometry: geometry)
            case .sounds:
                soundSettingsView(geometry: geometry)
            case .stats:
                statsSettingsView(geometry: geometry)
            case .general:
                generalSettingsView(geometry: geometry)
            case .about:
                aboutView(geometry: geometry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.05, green: 0.05, blue: 0.05))
    }
    
    // MARK: - Settings Views
    
    private func timerSettingsView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Timer Settings")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 20) {
                    // Timer durations
                    durationSetting(title: "Focus Duration", value: timerManager.focusDuration / 60, range: 1...60) { newValue in
                        timerManager.updateDuration(for: .focus, minutes: newValue)
                    }
                    
                    durationSetting(title: "Short Break", value: timerManager.shortBreakDuration / 60, range: 1...30) { newValue in
                        timerManager.updateDuration(for: .shortBreak, minutes: newValue)
                    }
                    
                    durationSetting(title: "Long Break", value: timerManager.longBreakDuration / 60, range: 1...60) { newValue in
                        timerManager.updateDuration(for: .longBreak, minutes: newValue)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Timer behavior
                    Toggle("Auto-start next timer", isOn: Binding(
                        get: { statsManager.settings.autoStartTimer },
                        set: { _ in statsManager.toggleAutoStartTimer() }
                    ))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    
                    Toggle("Show streak counter", isOn: Binding(
                        get: { statsManager.settings.showStreakCounter },
                        set: { _ in statsManager.toggleStreakCounter() }
                    ))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.all, 32)
        }
    }
    
    private func clockSettingsView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Clock Settings")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 20) {
                    Toggle("Use 24-hour format", isOn: Binding(
                        get: { statsManager.settings.use24HourFormat },
                        set: { _ in statsManager.toggle24HourFormat() }
                    ))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    
                    Toggle("Show greetings", isOn: Binding(
                        get: { statsManager.settings.showGreetings },
                        set: { _ in statsManager.toggleGreetings() }
                    ))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.all, 32)
        }
    }
    
    private func soundSettingsView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Sound Settings")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 20) {
                    Toggle("Enable sounds", isOn: Binding(
                        get: { statsManager.settings.soundEnabled },
                        set: { _ in statsManager.toggleSound() }
                    ))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    
                    if statsManager.settings.soundEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Volume")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("0")
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Slider(value: Binding(
                                get: { Double(statsManager.settings.soundVolume) },
                                set: { statsManager.setSoundVolume($0) }
                                ), in: 0...100)
                                .accentColor(.purple)
                                
                                Text("100")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .font(.system(size: 12))
                            
                            Text("Sound Type")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            
                            Picker("Sound", selection: Binding(
                                get: { statsManager.settings.selectedSound.rawValue },
                                set: { statsManager.setSelectedSound($0) }
                            )) {
                                ForEach(SoundOption.allCases, id: \.rawValue) { option in
                                    Text(option.displayName).tag(option.rawValue)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: 200, alignment: .leading)
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
            VStack(alignment: .leading, spacing: 24) {
                Text("Statistics")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 20) {
                    // Stats summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Summary")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        statsRow("Total Sessions", value: "\(statsManager.summary.totalSessions)")
                        statsRow("Focus Time", value: "\(statsManager.summary.totalFocusTime) min")
                        statsRow("Completion Rate", value: String(format: "%.1f%%", statsManager.summary.completionRate))
                        statsRow("Current Streak", value: "\(statsManager.summary.currentStreak) days")
                        statsRow("Best Streak", value: "\(statsManager.summary.bestStreak) days")
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Display period
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Period")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Picker("Period", selection: Binding(
                        get: { statsManager.settings.displayPeriod },
                        set: { statsManager.setDisplayPeriod($0) }
                        )) {
                            ForEach(StatsPeriod.allCases, id: \.rawValue) { period in
                                Text(period.displayName).tag(period)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Spacer()
            }
            .padding(.all, 32)
        }
    }
    
    private func generalSettingsView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("General Settings")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 20) {
                    Toggle("Show notifications", isOn: Binding(
                        get: { statsManager.settings.showNotifications },
                        set: { _ in statsManager.toggleNotifications() }
                    ))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    
                    Toggle("Disable animations", isOn: Binding(
                        get: { statsManager.settings.disableAnimations },
                        set: { newValue in 
                            statsManager.settings.disableAnimations = newValue
                        }
                    ))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.all, 32)
        }
    }
    
    private func aboutView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("About MindraTimer")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("A focused productivity timer for macOS")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Version 1.0.0")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Built with SwiftUI")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(.all, 32)
        }
    }
    
    // MARK: - Helper Views
    
    private func durationSetting(title: String, value: Int, range: ClosedRange<Int>, onChange: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(value) min")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Slider(value: Binding(
                get: { Double(value) },
                set: { onChange(Int($0)) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
            .accentColor(.purple)
        }
    }
    
    private func statsRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Settings Section Enum (removed theme sections)

enum SettingsSection: CaseIterable {
    case timer, clock, sounds, stats, general, about
    
    var title: String {
        switch self {
        case .timer: return "Timer"
        case .clock: return "Clock"
        case .sounds: return "Sounds"
        case .stats: return "Statistics"
        case .general: return "General"
        case .about: return "About"
        }
    }
}

// MARK: - App Configuration

struct AppConfiguration {
    static let isDebug = true // Set to false for release builds
}

#Preview {
    MindraSettingsView()
        .environmentObject(WindowManager())
        .environmentObject(StatsManager())
        .environmentObject(TimerManager())
        .environmentObject(AppModeManager())
}
