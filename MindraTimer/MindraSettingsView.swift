//
//  MindraSettingsView.swift
//  MindraTimer
//
//  Refactored version with improved architecture and component separation
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
        // Sync coordinator with stats manager
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
    
    func updateShowNotifications(_ value: Bool, statsManager: StatsManager) {
        showNotifications = value
        statsManager.settings.showNotifications = value
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
}

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
            .padding(.vertical, 12)
            .frame(minWidth: 80, minHeight: 44) // Ensure minimum touch target
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
            .padding(.vertical, 12)
            .frame(minWidth: 80, minHeight: 44) // Ensure minimum touch target
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

// MARK: - Main Settings Container

struct MindraSettingsView: View {
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var appModeManager: AppModeManager
    @EnvironmentObject var quotesManager: QuotesManager
    @EnvironmentObject var greetingManager: GreetingManager
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var coordinator = SettingsCoordinator()
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                SettingsSidebar(
                    selectedSection: $coordinator.selectedSection,
                    onDismiss: { dismiss() },
                    geometry: geometry
                )
                
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
            .background(AppColors.primaryBackground)
        }
        .frame(width: 900, height: 650)
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

// MARK: - Settings Sidebar

struct SettingsSidebar: View {
    @Binding var selectedSection: SettingsSection
    let onDismiss: () -> Void
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
            SettingsSidebarHeader(onDismiss: onDismiss)
            
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
            
            SettingsSidebarFooter()
        }
        .frame(width: geometry.size.width * 0.3)
        .background(AppColors.sidebarBackground)
    }
}

// MARK: - Sidebar Components

struct SettingsSidebarHeader: View {
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.secondaryText)
                    .frame(width: 32, height: 32) // Larger hit area
                    .contentShape(Rectangle()) // Make entire frame clickable
            }
            .buttonStyle(PlainButtonStyle())
            .help("Close Settings") // Tooltip for better UX
            
            Text("Settings")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryText)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 32)
    }
}

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
            .padding(.vertical, 12) // Increased padding for better hit area
            .contentShape(Rectangle()) // Make entire area clickable
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppColors.selectedBackground : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected) // Smooth selection animation
    }
}

struct SettingsSidebarFooter: View {
    var body: some View {
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
}

// MARK: - Layout Components

struct SettingsScrollContainer<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        ScrollView {
            content
                .padding(.all, 40)
        }
    }
}

struct SettingsContentSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content
    
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            
            VStack(alignment: .leading, spacing: 24) {
                content
            }
            
            Spacer(minLength: 200)
        }
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryText)
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
        )
    }
}

// MARK: - Form Components

struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Custom toggle - smaller visual size, same touch area
                ZStack {
                    // Invisible touch area
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 44, height: 44) // Keep large touch target
                    
                    // Visual toggle - smaller
                    ZStack {
                        Capsule()
                            .fill(isOn ? AppColors.focusColor : Color.gray.opacity(0.3))
                            .frame(width: 42, height: 24) // Reduced from 51x31
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20) // Reduced from 27x27
                            .offset(x: isOn ? 9 : -9) // Adjusted for smaller size
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    }
                    .animation(.easeInOut(duration: 0.2), value: isOn)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .contentShape(Rectangle()) // Make entire row clickable
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
                .contentShape(Rectangle())
        )
        .onHover { hovering in
            // Optional: Add hover effect
        }
    }
}

struct DurationSettingRow: View {
    let title: String
    let value: Int
    let onValueChanged: (Int) -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                Button(action: {
                    let newValue = max(1, value - 1)
                    onValueChanged(newValue)
                }) {
                    ZStack {
                        // Invisible large touch area
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44) // Keep large touch target
                        
                        // Smaller visual button
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.focusColor.opacity(0.1))
                            .frame(width: 32, height: 32) // Reduced visual size
                            .overlay(
                                Image(systemName: "minus")
                                    .font(.system(size: 14, weight: .semibold)) // Slightly smaller icon
                                    .foregroundColor(AppColors.focusColor)
                            )
                    }
                    .contentShape(Rectangle()) // Make entire area clickable
                }
                .buttonStyle(PlainButtonStyle())
                .help("Decrease duration")
                
                Text("\(value) min")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                    .frame(minWidth: 60)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.cardBackground)
                            .stroke(AppColors.dividerColor, lineWidth: 1)
                    )
                
                Button(action: {
                    let newValue = value + 1
                    onValueChanged(newValue)
                }) {
                    ZStack {
                        // Invisible large touch area
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44) // Keep large touch target
                        
                        // Smaller visual button
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.focusColor.opacity(0.1))
                            .frame(width: 32, height: 32) // Reduced visual size
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold)) // Slightly smaller icon
                                    .foregroundColor(AppColors.focusColor)
                            )
                    }
                    .contentShape(Rectangle()) // Make entire area clickable
                }
                .buttonStyle(PlainButtonStyle())
                .help("Increase duration")
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Settings Detail View

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

// MARK: - Preview

#Preview {
    MindraSettingsView()
        .environmentObject(WindowManager())
        .environmentObject(StatsManager())
        .environmentObject(TimerManager())
        .environmentObject(AppModeManager())
        .environmentObject(QuotesManager())
        .environmentObject(GreetingManager())
}
