import SwiftUI

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.dark.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .dark
    }
    
    func toggleTheme() {
        currentTheme = currentTheme == .dark ? .light : .dark
    }
    
    // Color scheme based on current theme
    var backgroundColor: Color {
        switch currentTheme {
        case .dark: return Color.black
        case .light: return Color.white
        case .auto: return Color.black // Default to dark for auto
        }
    }
    
    var primaryTextColor: Color {
        switch currentTheme {
        case .dark: return Color.white
        case .light: return Color.black
        case .auto: return Color.white // Default to dark for auto
        }
    }
    
    var secondaryTextColor: Color {
        switch currentTheme {
        case .dark: return Color.white.opacity(0.7)
        case .light: return Color.black.opacity(0.7)
        case .auto: return Color.white.opacity(0.7) // Default to dark for auto
        }
    }
    
    var accentColor: Color {
        switch currentTheme {
        case .dark: return Color.purple
        case .light: return Color.blue
        case .auto: return Color.purple // Default to dark for auto
        }
    }
    
    var buttonBackgroundColor: Color {
        switch currentTheme {
        case .dark: return Color.white.opacity(0.1)
        case .light: return Color.black.opacity(0.1)
        case .auto: return Color.white.opacity(0.1) // Default to dark for auto
        }
    }
    
    var buttonHoverColor: Color {
        switch currentTheme {
        case .dark: return Color.white.opacity(0.2)
        case .light: return Color.black.opacity(0.2)
        case .auto: return Color.white.opacity(0.2) // Default to dark for auto
        }
    }
} 