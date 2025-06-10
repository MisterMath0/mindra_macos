//
//  SettingsManager.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 09.06.25.
//

import Foundation

// MARK: - Settings Models

enum QuoteCategory: String, CaseIterable {
    case motivation = "motivation"
    case focus = "focus"
    case productivity = "productivity"
    case wellness = "wellness"
    case success = "success"
    
    var displayName: String {
        switch self {
        case .motivation: return "Motivation"
        case .focus: return "Focus"
        case .productivity: return "Productivity"
        case .wellness: return "Wellness"
        case .success: return "Success"
        }
    }
}

enum SoundOption: String, CaseIterable {
    case sparkle = "sparkle"
    case chime = "chime"
    case bellSoft = "bellSoft"
    case bellLoud = "bellLoud"
    case trainArrival = "trainArrival"
    case commuterJingle = "commuterJingle"
    case gameShow = "gameShow"
    
    var displayName: String {
        switch self {
        case .sparkle: return "Sparkle"
        case .chime: return "Chime"
        case .bellSoft: return "Bell (Soft)"
        case .bellLoud: return "Bell (Loud)"
        case .trainArrival: return "Train Arrival"
        case .commuterJingle: return "Commuter Jingle"
        case .gameShow: return "Game Show"
        }
    }
}

enum VisualizationType: String, CaseIterable {
    case bar = "bar"
    case line = "line"
    case area = "area"
    
    var displayName: String {
        switch self {
        case .bar: return "Bar Chart"
        case .line: return "Line Chart"
        case .area: return "Area Chart"
        }
    }
}

// MARK: - Settings Manager

class SettingsManager: ObservableObject {
    
    // MARK: - Appearance Settings
    @Published var disableAnimations: Bool {
        didSet { UserDefaults.standard.set(disableAnimations, forKey: "disableAnimations") }
    }
    
    @Published var clearMode: Bool {
        didSet { UserDefaults.standard.set(clearMode, forKey: "clearMode") }
    }
    
    @Published var showShareButton: Bool {
        didSet { UserDefaults.standard.set(showShareButton, forKey: "showShareButton") }
    }
    
    // MARK: - Clock Settings
    @Published var use24HourFormat: Bool {
        didSet { UserDefaults.standard.set(use24HourFormat, forKey: "use24HourFormat") }
    }
    
    @Published var showGreetings: Bool {
        didSet { UserDefaults.standard.set(showGreetings, forKey: "showGreetings") }
    }
    
    @Published var showDynamicGreetings: Bool {
        didSet { UserDefaults.standard.set(showDynamicGreetings, forKey: "showDynamicGreetings") }
    }
    
    // MARK: - Quote Settings
    @Published var showQuotes: Bool {
        didSet { UserDefaults.standard.set(showQuotes, forKey: "showQuotes") }
    }
    
    @Published var enablePersonalizedQuotes: Bool {
        didSet { UserDefaults.standard.set(enablePersonalizedQuotes, forKey: "enablePersonalizedQuotes") }
    }
    
    @Published var selectedQuoteCategories: [QuoteCategory] {
        didSet { 
            let categoryStrings = selectedQuoteCategories.map { $0.rawValue }
            UserDefaults.standard.set(categoryStrings, forKey: "selectedQuoteCategories")
        }
    }
    
    @Published var quoteRefreshInterval: Int {
        didSet { UserDefaults.standard.set(quoteRefreshInterval, forKey: "quoteRefreshInterval") }
    }
    
    // MARK: - Notification & Timer Settings
    @Published var showNotifications: Bool {
        didSet { UserDefaults.standard.set(showNotifications, forKey: "showNotifications") }
    }
    
    @Published var autoStartTimer: Bool {
        didSet { UserDefaults.standard.set(autoStartTimer, forKey: "autoStartTimer") }
    }
    
    @Published var showStreakCounter: Bool {
        didSet { UserDefaults.standard.set(showStreakCounter, forKey: "showStreakCounter") }
    }
    
    @Published var showTaskInPicture: Bool {
        didSet { UserDefaults.standard.set(showTaskInPicture, forKey: "showTaskInPicture") }
    }
    
    // MARK: - Sound Settings
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    
    @Published var soundVolume: Int {
        didSet { UserDefaults.standard.set(soundVolume, forKey: "soundVolume") }
    }
    
    @Published var selectedSound: SoundOption {
        didSet { UserDefaults.standard.set(selectedSound.rawValue, forKey: "selectedSound") }
    }
    
    // MARK: - Stats Settings
    @Published var displayPeriod: StatsPeriod {
        didSet { UserDefaults.standard.set(displayPeriod.rawValue, forKey: "displayPeriod") }
    }
    
    @Published var showStreak: Bool {
        didSet { UserDefaults.standard.set(showStreak, forKey: "showStreak") }
    }
    
    @Published var showAchievements: Bool {
        didSet { UserDefaults.standard.set(showAchievements, forKey: "showAchievements") }
    }
    
    @Published var showTotalTime: Bool {
        didSet { UserDefaults.standard.set(showTotalTime, forKey: "showTotalTime") }
    }
    
    @Published var showCompletionRate: Bool {
        didSet { UserDefaults.standard.set(showCompletionRate, forKey: "showCompletionRate") }
    }
    
    @Published var showAverageSessionLength: Bool {
        didSet { UserDefaults.standard.set(showAverageSessionLength, forKey: "showAverageSessionLength") }
    }
    
    @Published var enableNotificationsForAchievements: Bool {
        didSet { UserDefaults.standard.set(enableNotificationsForAchievements, forKey: "enableNotificationsForAchievements") }
    }
    
    @Published var visualizationType: VisualizationType {
        didSet { UserDefaults.standard.set(visualizationType.rawValue, forKey: "visualizationType") }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load appearance settings
        self.disableAnimations = UserDefaults.standard.bool(forKey: "disableAnimations")
        self.clearMode = UserDefaults.standard.bool(forKey: "clearMode")
        self.showShareButton = UserDefaults.standard.object(forKey: "showShareButton") as? Bool ?? true
        
        // Load clock settings
        self.use24HourFormat = UserDefaults.standard.bool(forKey: "use24HourFormat")
        self.showGreetings = UserDefaults.standard.object(forKey: "showGreetings") as? Bool ?? true
        self.showDynamicGreetings = UserDefaults.standard.object(forKey: "showDynamicGreetings") as? Bool ?? true
        
        // Load quote settings
        self.showQuotes = UserDefaults.standard.object(forKey: "showQuotes") as? Bool ?? true
        self.enablePersonalizedQuotes = UserDefaults.standard.bool(forKey: "enablePersonalizedQuotes")
        self.quoteRefreshInterval = UserDefaults.standard.object(forKey: "quoteRefreshInterval") as? Int ?? 5
        
        // Load quote categories
        let categoryStrings = UserDefaults.standard.stringArray(forKey: "selectedQuoteCategories") ?? ["motivation", "focus", "productivity"]
        self.selectedQuoteCategories = categoryStrings.compactMap { QuoteCategory(rawValue: $0) }
        
        // Load notification & timer settings
        self.showNotifications = UserDefaults.standard.object(forKey: "showNotifications") as? Bool ?? true
        self.autoStartTimer = UserDefaults.standard.object(forKey: "autoStartTimer") as? Bool ?? true
        self.showStreakCounter = UserDefaults.standard.object(forKey: "showStreakCounter") as? Bool ?? true
        self.showTaskInPicture = UserDefaults.standard.bool(forKey: "showTaskInPicture")
        
        // Load sound settings
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.soundVolume = UserDefaults.standard.object(forKey: "soundVolume") as? Int ?? 70
        let soundString = UserDefaults.standard.string(forKey: "selectedSound") ?? "sparkle"
        self.selectedSound = SoundOption(rawValue: soundString) ?? .sparkle
        
        // Load stats settings
        let periodString = UserDefaults.standard.string(forKey: "displayPeriod") ?? "week"
        self.displayPeriod = StatsPeriod(rawValue: periodString) ?? .week
        self.showStreak = UserDefaults.standard.object(forKey: "showStreak") as? Bool ?? true
        self.showAchievements = UserDefaults.standard.object(forKey: "showAchievements") as? Bool ?? true
        self.showTotalTime = UserDefaults.standard.bool(forKey: "showTotalTime")
        self.showCompletionRate = UserDefaults.standard.bool(forKey: "showCompletionRate")
        self.showAverageSessionLength = UserDefaults.standard.bool(forKey: "showAverageSessionLength")
        self.enableNotificationsForAchievements = UserDefaults.standard.bool(forKey: "enableNotificationsForAchievements")
        
        let visualizationString = UserDefaults.standard.string(forKey: "visualizationType") ?? "bar"
        self.visualizationType = VisualizationType(rawValue: visualizationString) ?? .bar
    }
    
    // MARK: - Convenience Methods
    
    func toggleQuoteCategory(_ category: QuoteCategory) {
        if selectedQuoteCategories.contains(category) {
            selectedQuoteCategories.removeAll { $0 == category }
        } else {
            selectedQuoteCategories.append(category)
        }
    }
    
    func resetToDefaults() {
        // Appearance
        disableAnimations = false
        clearMode = false
        showShareButton = true
        
        // Clock
        use24HourFormat = false
        showGreetings = true
        showDynamicGreetings = true
        
        // Quotes
        showQuotes = true
        enablePersonalizedQuotes = false
        selectedQuoteCategories = [.motivation, .focus, .productivity]
        quoteRefreshInterval = 5
        
        // Notifications & Timer
        showNotifications = true
        autoStartTimer = true
        showStreakCounter = true
        showTaskInPicture = false
        
        // Sound
        soundEnabled = true
        soundVolume = 70
        selectedSound = .sparkle
        
        // Stats
        displayPeriod = .week
        showStreak = true
        showAchievements = true
        showTotalTime = false
        showCompletionRate = false
        showAverageSessionLength = false
        enableNotificationsForAchievements = false
        visualizationType = .bar
    }
    
    // MARK: - Export/Import Settings
    
    func exportSettings() -> [String: Any] {
        return [
            "disableAnimations": disableAnimations,
            "clearMode": clearMode,
            "showShareButton": showShareButton,
            "use24HourFormat": use24HourFormat,
            "showGreetings": showGreetings,
            "showDynamicGreetings": showDynamicGreetings,
            "showQuotes": showQuotes,
            "enablePersonalizedQuotes": enablePersonalizedQuotes,
            "selectedQuoteCategories": selectedQuoteCategories.map { $0.rawValue },
            "quoteRefreshInterval": quoteRefreshInterval,
            "showNotifications": showNotifications,
            "autoStartTimer": autoStartTimer,
            "showStreakCounter": showStreakCounter,
            "showTaskInPicture": showTaskInPicture,
            "soundEnabled": soundEnabled,
            "soundVolume": soundVolume,
            "selectedSound": selectedSound.rawValue,
            "displayPeriod": displayPeriod.rawValue,
            "showStreak": showStreak,
            "showAchievements": showAchievements,
            "showTotalTime": showTotalTime,
            "showCompletionRate": showCompletionRate,
            "showAverageSessionLength": showAverageSessionLength,
            "enableNotificationsForAchievements": enableNotificationsForAchievements,
            "visualizationType": visualizationType.rawValue
        ]
    }
    
    func importSettings(from data: [String: Any]) {
        if let value = data["disableAnimations"] as? Bool { disableAnimations = value }
        if let value = data["clearMode"] as? Bool { clearMode = value }
        if let value = data["showShareButton"] as? Bool { showShareButton = value }
        if let value = data["use24HourFormat"] as? Bool { use24HourFormat = value }
        if let value = data["showGreetings"] as? Bool { showGreetings = value }
        if let value = data["showDynamicGreetings"] as? Bool { showDynamicGreetings = value }
        if let value = data["showQuotes"] as? Bool { showQuotes = value }
        if let value = data["enablePersonalizedQuotes"] as? Bool { enablePersonalizedQuotes = value }
        if let value = data["quoteRefreshInterval"] as? Int { quoteRefreshInterval = value }
        if let value = data["showNotifications"] as? Bool { showNotifications = value }
        if let value = data["autoStartTimer"] as? Bool { autoStartTimer = value }
        if let value = data["showStreakCounter"] as? Bool { showStreakCounter = value }
        if let value = data["showTaskInPicture"] as? Bool { showTaskInPicture = value }
        if let value = data["soundEnabled"] as? Bool { soundEnabled = value }
        if let value = data["soundVolume"] as? Int { soundVolume = value }
        if let value = data["showStreak"] as? Bool { showStreak = value }
        if let value = data["showAchievements"] as? Bool { showAchievements = value }
        if let value = data["showTotalTime"] as? Bool { showTotalTime = value }
        if let value = data["showCompletionRate"] as? Bool { showCompletionRate = value }
        if let value = data["showAverageSessionLength"] as? Bool { showAverageSessionLength = value }
        if let value = data["enableNotificationsForAchievements"] as? Bool { enableNotificationsForAchievements = value }
        
        if let categoryStrings = data["selectedQuoteCategories"] as? [String] {
            selectedQuoteCategories = categoryStrings.compactMap { QuoteCategory(rawValue: $0) }
        }
        
        if let soundString = data["selectedSound"] as? String {
            selectedSound = SoundOption(rawValue: soundString) ?? .sparkle
        }
        
        if let periodString = data["displayPeriod"] as? String {
            displayPeriod = StatsPeriod(rawValue: periodString) ?? .week
        }
        
        if let visualizationString = data["visualizationType"] as? String {
            visualizationType = VisualizationType(rawValue: visualizationString) ?? .bar
        }
    }
}
