//
//  AppConfiguration.swift
//  MindraTimer
//
//  Centralized app configuration and dependency injection
//

import SwiftUI

class AppConfiguration: ObservableObject {
    // MARK: - Services
    let audioService: AudioServiceProtocol
    let notificationService: NotificationServiceProtocol
    let analyticsService: AnalyticsServiceProtocol
    
    // MARK: - Managers
    @Published var timerManager: TimerManager
    @Published var settingsManager: SettingsManager
    @Published var statsManager: StatsManager
    @Published var windowManager: WindowManager
    @Published var quotesManager: QuotesManager
    @Published var greetingManager: GreetingManager
    @Published var appModeManager: AppModeManager
    @Published var themeManager: ThemeManager
    
    // MARK: - App State
    @Published var isInitialized = false
    @Published var hasError = false
    @Published var errorMessage: String?
    
    // MARK: - Configuration
    private let isTestEnvironment: Bool
    
    init(isTestEnvironment: Bool = false) {
        self.isTestEnvironment = isTestEnvironment
        
        // Initialize services (use mocks in test environment)
        if isTestEnvironment {
            self.audioService = MockAudioService()
            self.notificationService = MockNotificationService()
            self.analyticsService = MockAnalyticsService()
        } else {
            self.audioService = AudioService()
            self.notificationService = NotificationService()
            self.analyticsService = AnalyticsService()
        }
        
        // Initialize managers
        self.timerManager = TimerManager()
        self.settingsManager = SettingsManager()
        self.statsManager = StatsManager()
        self.windowManager = WindowManager()
        self.quotesManager = QuotesManager()
        self.greetingManager = GreetingManager()
        self.appModeManager = AppModeManager()
        self.themeManager = ThemeManager()
        
        initializeApp()
    }
    
    // MARK: - Initialization
    
    private func initializeApp() {
        do {
            try setupDependencies()
            loadUserSettings()
            setupNotifications()
            
            isInitialized = true
            print("✅ App configuration initialized successfully")
        } catch {
            handleInitializationError(error)
        }
    }
    
    private func setupDependencies() throws {
        // Connect timer manager with stats manager
        timerManager.setStatsManager(statsManager)
        
        // Connect managers with services
        timerManager.setAudioService(audioService)
        timerManager.setAnalyticsService(analyticsService)
        
        // Set up user name synchronization
        let userName = UserDefaults.standard.string(forKey: "userName")
        quotesManager.setUserName(userName)
        greetingManager.setUserName(userName)
        
        print("✅ Dependencies configured")
    }
    
    private func loadUserSettings() {
        // Load and apply user settings
        let settings = settingsManager.exportSettings()
        
        // Apply theme settings
        if let themeString = settings["theme"] as? String,
           let theme = AppTheme(rawValue: themeString) {
            themeManager.currentTheme = theme
        }
        
        print("✅ User settings loaded")
    }
    
    private func setupNotifications() {
        Task {
            let granted = await notificationService.requestPermission()
            if granted {
                notificationService.setupNotificationCategories()
                print("✅ Notifications configured")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
    
    private func handleInitializationError(_ error: Error) {
        hasError = true
        errorMessage = error.localizedDescription
        print("❌ App initialization failed: \(error)")
    }
    
    // MARK: - Public Methods
    
    func retryInitialization() {
        hasError = false
        errorMessage = nil
        isInitialized = false
        initializeApp()
    }
    
    func updateUserName(_ name: String?) {
        UserDefaults.standard.set(name, forKey: "userName")
        quotesManager.setUserName(name)
        greetingManager.setUserName(name)
        
        analyticsService.trackSettingsChanged(setting: "userName", value: name ?? "")
    }
    
    func resetAllData() {
        // Clear all user data (with confirmation)
        statsManager.clearAllData()
        UserDefaults.standard.removeObject(forKey: "userName")
        settingsManager.resetToDefaults()
        
        // Reinitialize
        initializeApp()
        
        analyticsService.trackSettingsChanged(setting: "dataReset", value: "all")
        print("🗑️ All user data reset")
    }
    
    // MARK: - Debug Methods
    
    func getDebugInfo() -> String {
        return """
        🔧 App Configuration Debug Info:
        
        Services:
        • Audio: \(type(of: audioService))
        • Notifications: \(type(of: notificationService))
        • Analytics: \(type(of: analyticsService))
        
        State:
        • Initialized: \(isInitialized)
        • Has Error: \(hasError)
        • Error: \(errorMessage ?? "none")
        • Test Environment: \(isTestEnvironment)
        """
    }
}

// MARK: - Environment Key

struct AppConfigurationKey: EnvironmentKey {
    static let defaultValue: AppConfiguration? = nil
}

extension EnvironmentValues {
    var appConfiguration: AppConfiguration? {
        get { self[AppConfigurationKey.self] }
        set { self[AppConfigurationKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    func appConfiguration(_ configuration: AppConfiguration) -> some View {
        self.environment(\.appConfiguration, configuration)
    }
}
