//
//  AppColors.swift
//  MindraTimer
//
//  Centralized color system for the application
//

import SwiftUI

struct AppColors {
    // MARK: - Primary Color Palette
    
    // Background colors
    static let primaryBackground = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let secondaryBackground = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let tertiaryBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
    
    // Sidebar and card colors
    static let sidebarBackground = Color(red: 0.04, green: 0.04, blue: 0.04)
    static let cardBackground = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let elevatedCardBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
    
    // Interactive states
    static let selectedBackground = Color.white.opacity(0.1)
    static let hoverBackground = Color.white.opacity(0.05)
    static let pressedBackground = Color.white.opacity(0.15)
    
    // MARK: - Text Colors
    
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let tertiaryText = Color.white.opacity(0.5)
    static let quaternaryText = Color.white.opacity(0.3)
    static let disabledText = Color.white.opacity(0.2)
    
    // MARK: - Timer Mode Colors
    
    static let focusColor = Color(red: 0.6, green: 0.4, blue: 0.9) // Purple
    static let shortBreakColor = Color(red: 0.9, green: 0.5, blue: 0.7) // Pink
    static let longBreakColor = Color(red: 0.3, green: 0.6, blue: 0.9) // Blue
    
    // Timer mode variations
    static let focusColorLight = focusColor.opacity(0.3)
    static let focusColorDark = focusColor.opacity(0.8)
    static let shortBreakColorLight = shortBreakColor.opacity(0.3)
    static let shortBreakColorDark = shortBreakColor.opacity(0.8)
    static let longBreakColorLight = longBreakColor.opacity(0.3)
    static let longBreakColorDark = longBreakColor.opacity(0.8)
    
    // MARK: - Semantic Colors
    
    static let successColor = Color(red: 0.2, green: 0.8, blue: 0.3) // Green
    static let warningColor = Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
    static let errorColor = Color(red: 0.9, green: 0.2, blue: 0.3) // Red
    static let infoColor = Color(red: 0.2, green: 0.7, blue: 1.0) // Blue
    
    // Semantic variations
    static let successColorLight = successColor.opacity(0.2)
    static let warningColorLight = warningColor.opacity(0.2)
    static let errorColorLight = errorColor.opacity(0.2)
    static let infoColorLight = infoColor.opacity(0.2)
    
    // MARK: - UI Element Colors
    
    static let dividerColor = Color.white.opacity(0.1)
    static let borderColor = Color.white.opacity(0.15)
    static let shadowColor = Color.black.opacity(0.3)
    
    // Button colors
    static let primaryButtonBackground = focusColor
    static let primaryButtonHover = focusColor.opacity(0.8)
    static let primaryButtonPressed = focusColor.opacity(0.9)
    static let primaryButtonText = Color.white
    
    static let secondaryButtonBackground = Color.white.opacity(0.08)
    static let secondaryButtonHover = Color.white.opacity(0.12)
    static let secondaryButtonPressed = Color.white.opacity(0.16)
    static let secondaryButtonText = secondaryText
    
    // Input field colors
    static let inputBackground = cardBackground
    static let inputBorder = borderColor
    static let inputFocusBorder = focusColor
    static let inputText = primaryText
    static let inputPlaceholder = tertiaryText
    
    // MARK: - Progress and Status Colors
    
    static let progressBackground = Color.white.opacity(0.1)
    static let progressFill = focusColor
    
    static let activeIndicator = successColor
    static let inactiveIndicator = Color.white.opacity(0.3)
    static let pausedIndicator = warningColor
    
    // MARK: - Theme Support
    
    enum Theme {
        case dark
        case light
        case auto
    }
    
    static func color(for theme: Theme, primary: Color, light: Color? = nil) -> Color {
        switch theme {
        case .dark:
            return primary
        case .light:
            return light ?? primary
        case .auto:
            // Would need system theme detection
            return primary
        }
    }
    
    // MARK: - Accessibility Colors
    
    static let highContrastPrimary = Color.white
    static let highContrastSecondary = Color(red: 0.9, green: 0.9, blue: 0.9)
    static let highContrastAccent = Color(red: 1.0, green: 0.8, blue: 0.0) // High contrast yellow
    
    // MARK: - Gradient Definitions
    
    static let primaryGradient = LinearGradient(
        colors: [focusColor, focusColor.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [primaryBackground, secondaryBackground],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGradient = LinearGradient(
        colors: [cardBackground, elevatedCardBackground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Color Helpers
    
    static func timerColor(for mode: TimerMode) -> Color {
        switch mode {
        case .focus: return focusColor
        case .shortBreak: return shortBreakColor
        case .longBreak: return longBreakColor
        }
    }
    
    static func timerColorLight(for mode: TimerMode) -> Color {
        return timerColor(for: mode).opacity(0.3)
    }
    
    static func semanticColor(for type: SemanticColorType) -> Color {
        switch type {
        case .success: return successColor
        case .warning: return warningColor
        case .error: return errorColor
        case .info: return infoColor
        }
    }
    
    static func adaptiveColor(
        light: Color,
        dark: Color,
        for colorScheme: ColorScheme
    ) -> Color {
        return colorScheme == .dark ? dark : light
    }
}

// MARK: - Supporting Enums

enum SemanticColorType {
    case success
    case warning
    case error
    case info
}

// MARK: - Color Extensions

extension Color {
    // Create color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Get hex string representation
    var hexString: String {
        guard let components = cgColor?.components, components.count >= 3 else {
            return "#000000"
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
    
    // Create lighter version
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
    
    // Create darker version
    func darker(by percentage: CGFloat = 0.2) -> Color {
        return self.opacity(1.0 + percentage)
    }
    
    // Check if color is light or dark
    var isLight: Bool {
        guard let components = cgColor?.components, components.count >= 3 else {
            return false
        }
        
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return brightness > 0.5
    }
}

// MARK: - Color Scheme Support

struct AppColorScheme {
    let primary: Color
    let secondary: Color
    let background: Color
    let surface: Color
    let accent: Color
    
    static let dark = AppColorScheme(
        primary: AppColors.primaryText,
        secondary: AppColors.secondaryText,
        background: AppColors.primaryBackground,
        surface: AppColors.cardBackground,
        accent: AppColors.focusColor
    )
    
    static let light = AppColorScheme(
        primary: Color.black,
        secondary: Color.gray,
        background: Color.white,
        surface: Color(red: 0.95, green: 0.95, blue: 0.95),
        accent: AppColors.focusColor
    )
}

// MARK: - Environment Key for Color Scheme

struct AppColorSchemeKey: EnvironmentKey {
    static let defaultValue = AppColorScheme.dark
}

extension EnvironmentValues {
    var appColorScheme: AppColorScheme {
        get { self[AppColorSchemeKey.self] }
        set { self[AppColorSchemeKey.self] = newValue }
    }
}

// MARK: - View Modifier for Color Scheme

struct AppColorSchemeModifier: ViewModifier {
    let colorScheme: AppColorScheme
    
    func body(content: Content) -> some View {
        content
            .environment(\.appColorScheme, colorScheme)
    }
}

extension View {
    func appColorScheme(_ scheme: AppColorScheme) -> some View {
        modifier(AppColorSchemeModifier(colorScheme: scheme))
    }
}
