//
//  MindraSettingsView.swift
//  MindraTimer
//
//  SETTINGS AS FULL PAGE - PROPER NAVIGATION INTEGRATION
//  No more dialog - integrated as main page like clock/focus
//

import SwiftUI

// MARK: - Settings Coordinator

class SettingsCoordinator: ObservableObject {
    @Published var selectedSection: SettingsSection = .timer
    @Published var userName: String = ""
    @Published var tempUserName: String = ""
    @Published var soundVolume: Double = 70
    @Published var quoteInterval: Double = 5
    
    // Add toggle states to coordinator
    @Published var autoStartTimer: Bool = false
    @Published var soundEnabled: Bool = true
    @Published var showNotifications: Bool = true
    @Published var showGreetings: Bool = true
    @Published var showQuotes: Bool = true
    @Published var enablePersonalizedQuotes: Bool = false
    @Published var showTimerInMenuBar: Bool = true
    @Published var showNotificationsInMenuBar: Bool = true
    @Published var showStreakCounter: Bool = true
    @Published var showStatsNotifications: Bool = true
    
    func loadInitialValues() {
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        tempUserName = userName
        soundVolume = Double(UserDefaults.standard.integer(forKey: "soundVolume"))
        quoteInterval = Double(UserDefaults.standard.integer(forKey: "quoteRefreshInterval"))
    }
    
    func syncWithStatsManager(_ statsManager: StatsManager) {
        autoStartTimer = statsManager.settings.autoStartTimer
        soundEnabled = statsManager.settings.soundEnabled
        showNotifications = statsManager.settings.showNotifications
        showGreetings = statsManager.settings.showGreetings
        showQuotes = statsManager.settings.showQuotes
        enablePersonalizedQuotes = statsManager.settings.enablePersonalizedQuotes
        showTimerInMenuBar = statsManager.settings.showTimerInMenuBar
        showNotificationsInMenuBar = statsManager.settings.showNotificationsInMenuBar
        showStreakCounter = statsManager.settingsManager.showStreakCounter
        showStatsNotifications = statsManager.settingsManager.showNotifications
    }
    
    func saveUserName() {
        userName = tempUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(userName.isEmpty ? nil : userName, forKey: "userName")
    }
    
    func updateSoundVolume(_ volume: Double) {
        soundVolume = volume
        UserDefaults.standard.set(Int(volume), forKey: "soundVolume")
    }
    
    func updateQuoteInterval(_ interval: Double) {
        quoteInterval = interval
        UserDefaults.standard.set(Int(interval), forKey: "quoteRefreshInterval")
    }
    
    // Update methods for toggles
    func updateAutoStartTimer(_ value: Bool, statsManager: StatsManager) {
        autoStartTimer = value
        statsManager.settings.autoStartTimer = value
    }
    
    func updateSoundEnabled(_ value: Bool, statsManager: StatsManager) {
        soundEnabled = value
        statsManager.settings.soundEnabled = value
    }
    

    
    func updateShowGreetings(_ value: Bool, statsManager: StatsManager) {
        showGreetings = value
        statsManager.settings.showGreetings = value
    }
    
    func updateShowQuotes(_ value: Bool, statsManager: StatsManager) {
        showQuotes = value
        statsManager.settings.showQuotes = value
    }
    
    func updateEnablePersonalizedQuotes(_ value: Bool, statsManager: StatsManager, quotesManager: QuotesManager) {
        enablePersonalizedQuotes = value
        statsManager.settings.enablePersonalizedQuotes = value
        quotesManager.setPersonalization(value)
    }
    
    func updateShowTimerInMenuBar(_ value: Bool, statsManager: StatsManager) {
        showTimerInMenuBar = value
        statsManager.settings.showTimerInMenuBar = value
    }
    
    func updateShowNotificationsInMenuBar(_ value: Bool, statsManager: StatsManager) {
        showNotificationsInMenuBar = value
        statsManager.settings.showNotificationsInMenuBar = value
    }
    
    func updateShowStreakCounter(_ value: Bool, statsManager: StatsManager) {
        showStreakCounter = value
        statsManager.settingsManager.showStreakCounter = value
    }
    
    func updateShowStatsNotifications(_ value: Bool, statsManager: StatsManager) {
        showStatsNotifications = value
        statsManager.settingsManager.showNotifications = value
    }
    
    func updateShowNotifications(_ value: Bool, statsManager: StatsManager) {
        showNotifications = value
        statsManager.settings.showNotifications = value
    }
}

// MARK: - MAIN SETTINGS VIEW - FULL PAGE LAYOUT

struct MindraSettingsView: View {
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var appModeManager: AppModeManager
    @EnvironmentObject var quotesManager: QuotesManager
    @EnvironmentObject var greetingManager: GreetingManager
    @EnvironmentObject var navigationManager: AppNavigationManager
    
    @StateObject private var coordinator = SettingsCoordinator()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // FULL PAGE SETTINGS LAYOUT
                HStack(spacing: 0) {
                    // SIDEBAR
                    SettingsSidebar(
                        selectedSection: $coordinator.selectedSection,
                        geometry: geometry
                    )
                    
                    // MAIN CONTENT
                    SettingsDetailView(
                        selectedSection: coordinator.selectedSection,
                        coordinator: coordinator,
                        geometry: geometry
                    )
                    .environmentObject(statsManager)
                    .environmentObject(timerManager)
                    .environmentObject(windowManager)
                    .environmentObject(appModeManager)
                    .environmentObject(quotesManager)
                    .environmentObject(greetingManager)
                }
                
                // BOTTOM NAVIGATION - INTEGRATED LIKE OTHER PAGES
                SettingsBottomNavigation(geometry: geometry)
                    .environmentObject(navigationManager)
                    .environmentObject(windowManager)
                    .environmentObject(timerManager)
            }
            .background(AppColors.primaryBackground)
        }
        .onAppear {
            coordinator.loadInitialValues()
            coordinator.syncWithStatsManager(statsManager)
            
            // Ensure achievements are properly initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if statsManager.achievements.isEmpty {
                    print("⚠️ Achievements still empty after initialization - triggering reload")
                    statsManager.debugAchievements()
                }
            }
        }
    }
}

// MARK: - SETTINGS BOTTOM NAVIGATION

struct SettingsBottomNavigation: View {
    let geometry: GeometryProxy
    @EnvironmentObject var navigationManager: AppNavigationManager
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        HStack {
            // Left side controls
            HStack(spacing: max(20, geometry.size.width * 0.025)) {
                navButton(icon: "bell", action: { }, geometry: geometry)
            }
            .frame(width: max(60, geometry.size.width * 0.08), alignment: .leading)
            
            Spacer()
            
            // Center navigation
            HStack(spacing: max(32, geometry.size.width * 0.04)) {
                navButton(
                    icon: "house.fill",
                    action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            navigationManager.navigateTo(.clock)
                        }
                    },
                    geometry: geometry,
                    isActive: false
                )
                navButton(
                    icon: "timer",
                    action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            navigationManager.navigateTo(.focus)
                        }
                    },
                    geometry: geometry,
                    isActive: false
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
                    action: { }, // Already in settings
                    geometry: geometry,
                    isActive: true
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
}

// MARK: - Settings Sidebar - NO DISMISS BUTTON

struct SettingsSidebar: View {
    @Binding var selectedSection: SettingsSection
    let geometry: GeometryProxy
    
    private let sectionGroups: [(String, [(SettingsSection, String, String)])] = [
        ("CORE", [
            (.timer, "timer", "Timer"),
            (.clock, "clock", "Clock"),
            (.sounds, "speaker.wave.2", "Sounds"),
            (.stats, "chart.bar", "Stats")
        ]),
        ("PERSONALIZATION", [
            (.profile, "person.circle", "Profile"),
            (.quotes, "quote.bubble", "Quotes"),
            (.appearance, "paintbrush", "Appearance")
        ]),
        ("OTHER", [
            (.general, "gearshape", "General"),
            (.about, "info.circle", "About")
        ])
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // HEADER - NO DISMISS BUTTON
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Customize your experience")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 32)
            
            // SECTIONS
            VStack(alignment: .leading, spacing: 24) {
                ForEach(sectionGroups, id: \.0) { group in
                    SettingsSectionGroup(
                        title: group.0,
                        items: group.1,
                        selectedSection: $selectedSection
                    )
                }
            }
            .padding(.leading, 24)
            
            Spacer()
            
            // FOOTER
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
        .frame(width: max(280, geometry.size.width * 0.28))
        .background(AppColors.sidebarBackground)
    }
}

// MARK: - Sidebar Components (Unchanged)

struct SettingsSectionGroup: View {
    let title: String
    let items: [(SettingsSection, String, String)]
    @Binding var selectedSection: SettingsSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.tertiaryText)
                .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.0) { item in
                    SettingsSidebarItem(
                        section: item.0,
                        icon: item.1,
                        title: item.2,
                        isSelected: selectedSection == item.0,
                        onTap: { selectedSection = item.0 }
                    )
                }
            }
        }
    }
}

struct SettingsSidebarItem: View {
    let section: SettingsSection
    let icon: String
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? AppColors.primaryText : AppColors.secondaryText)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? AppColors.primaryText : AppColors.secondaryText)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppColors.selectedBackground : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Settings Detail View (Unchanged)

struct SettingsDetailView: View {
    let selectedSection: SettingsSection
    @ObservedObject var coordinator: SettingsCoordinator
    let geometry: GeometryProxy
    
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var appModeManager: AppModeManager
    @EnvironmentObject var quotesManager: QuotesManager
    @EnvironmentObject var greetingManager: GreetingManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch selectedSection {
            case .timer:
                TimerSettingsView(coordinator: coordinator)
                    .environmentObject(timerManager)
                    .environmentObject(statsManager)
            case .clock:
                ClockSettingsView(coordinator: coordinator)
                    .environmentObject(statsManager)
            case .sounds:
                SoundSettingsView(coordinator: coordinator)
                    .environmentObject(statsManager)
            case .stats:
                StatsSettingsView(coordinator: coordinator)
                    .environmentObject(statsManager)
            case .profile:
                ProfileSettingsView(coordinator: coordinator)
                    .environmentObject(quotesManager)
                    .environmentObject(greetingManager)
            case .quotes:
                QuotesSettingsView(coordinator: coordinator)
                    .environmentObject(statsManager)
                    .environmentObject(quotesManager)
            case .appearance:
                PlaceholderSettingsView(title: "Appearance")
            case .general:
                PlaceholderSettingsView(title: "General Settings")
            case .about:
                AboutSettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.primaryBackground)
    }
}

// MARK: - Supporting Enums

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

// MARK: - Placeholder Views

struct PlaceholderSettingsView: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Coming soon...")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.all, 40)
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                Text("MindraTimer - Your Focus Companion")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Version 1.0.0")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Built with SwiftUI for macOS")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.all, 40)
    }
}

// MARK: - Preview

#Preview {
    MindraSettingsView()
        .environmentObject(WindowManager())
        .environmentObject(AppNavigationManager())
        .environmentObject(StatsManager())
        .environmentObject(TimerManager())
        .environmentObject(AppModeManager())
        .environmentObject(QuotesManager())
        .environmentObject(GreetingManager())
}
