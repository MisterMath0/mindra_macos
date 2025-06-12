//
//  AppFonts.swift
//  MindraTimer
//
//  Centralized typography system for the application
//

import SwiftUI

struct AppFonts {
    // MARK: - Font Family
    
    static let defaultFamily: Font.Design = .rounded
    
    // MARK: - Font Sizes
    
    struct Size {
        static let extraLarge: CGFloat = 48
        static let large: CGFloat = 32
        static let title: CGFloat = 24
        static let headline: CGFloat = 20
        static let body: CGFloat = 16
        static let callout: CGFloat = 14
        static let caption: CGFloat = 12
        static let caption2: CGFloat = 10
        
        // Timer specific sizes
        static let timerLarge: CGFloat = 72
        static let timerMedium: CGFloat = 48
        static let timerSmall: CGFloat = 32
        
        // Display sizes
        static let display1: CGFloat = 96
        static let display2: CGFloat = 72
        static let display3: CGFloat = 48
    }
    
    struct Weight {
        static let black: Font.Weight = .black
        static let heavy: Font.Weight = .heavy
        static let bold: Font.Weight = .bold
        static let semibold: Font.Weight = .semibold
        static let medium: Font.Weight = .medium
        static let regular: Font.Weight = .regular
        static let light: Font.Weight = .light
        static let thin: Font.Weight = .thin
        static let ultraLight: Font.Weight = .ultraLight
    }
    
    // MARK: - Semantic Font Definitions
    
    // Display fonts (for large timer displays)
    static let timerDisplay = Font.system(size: Size.timerLarge, weight: Weight.black, design: defaultFamily)
    static let clockDisplay = Font.system(size: Size.display1, weight: Weight.black, design: defaultFamily)
    
    // Title fonts
    static let largeTitle = Font.system(size: Size.extraLarge, weight: Weight.bold, design: defaultFamily)
    static let title1 = Font.system(size: Size.large, weight: Weight.bold, design: defaultFamily)
    static let title2 = Font.system(size: Size.title, weight: Weight.semibold, design: defaultFamily)
    static let title3 = Font.system(size: Size.headline, weight: Weight.medium, design: defaultFamily)
    
    // Body fonts
    static let body = Font.system(size: Size.body, weight: Weight.regular, design: defaultFamily)
    static let bodyMedium = Font.system(size: Size.body, weight: Weight.medium, design: defaultFamily)
    static let bodySemibold = Font.system(size: Size.body, weight: Weight.semibold, design: defaultFamily)
    
    // Support fonts
    static let callout = Font.system(size: Size.callout, weight: Weight.regular, design: defaultFamily)
    static let calloutMedium = Font.system(size: Size.callout, weight: Weight.medium, design: defaultFamily)
    static let calloutSemibold = Font.system(size: Size.callout, weight: Weight.semibold, design: defaultFamily)
    
    static let caption = Font.system(size: Size.caption, weight: Weight.regular, design: defaultFamily)
    static let captionMedium = Font.system(size: Size.caption, weight: Weight.medium, design: defaultFamily)
    static let captionSemibold = Font.system(size: Size.caption, weight: Weight.semibold, design: defaultFamily)
    
    static let caption2 = Font.system(size: Size.caption2, weight: Weight.regular, design: defaultFamily)
    
    // MARK: - Component-Specific Fonts
    
    // Button fonts
    static let buttonLarge = Font.system(size: Size.body, weight: Weight.semibold, design: defaultFamily)
    static let buttonMedium = Font.system(size: Size.callout, weight: Weight.semibold, design: defaultFamily)
    static let buttonSmall = Font.system(size: Size.caption, weight: Weight.semibold, design: defaultFamily)
    
    // Navigation fonts
    static let navigationTitle = Font.system(size: Size.headline, weight: Weight.semibold, design: defaultFamily)
    static let navigationItem = Font.system(size: Size.callout, weight: Weight.medium, design: defaultFamily)
    
    // Form fonts
    static let inputLabel = Font.system(size: Size.callout, weight: Weight.medium, design: defaultFamily)
    static let inputText = Font.system(size: Size.body, weight: Weight.regular, design: defaultFamily)
    static let inputHelper = Font.system(size: Size.caption, weight: Weight.regular, design: defaultFamily)
    
    // Card fonts
    static let cardTitle = Font.system(size: Size.headline, weight: Weight.semibold, design: defaultFamily)
    static let cardSubtitle = Font.system(size: Size.callout, weight: Weight.medium, design: defaultFamily)
    static let cardBody = Font.system(size: Size.callout, weight: Weight.regular, design: defaultFamily)
    
    // Stats fonts
    static let statValue = Font.system(size: Size.title, weight: Weight.bold, design: defaultFamily)
    static let statLabel = Font.system(size: Size.caption, weight: Weight.medium, design: defaultFamily)
    
    // Quote fonts
    static let quoteText = Font.system(size: Size.body, weight: Weight.regular, design: defaultFamily)
    static let quoteAuthor = Font.system(size: Size.caption, weight: Weight.medium, design: defaultFamily)
    
    // MARK: - Responsive Font System
    
    static func responsiveFont(
        baseSize: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = defaultFamily,
        scaleFactor: CGFloat = 1.0
    ) -> Font {
        let adjustedSize = baseSize * scaleFactor
        return Font.system(size: adjustedSize, weight: weight, design: design)
    }
    
    static func timerFont(for size: CGSize) -> Font {
        let scaleFactor = min(size.width / 320, size.height / 568) // Base iPhone SE size
        let fontSize = Size.timerLarge * scaleFactor
        return Font.system(size: fontSize, weight: Weight.black, design: defaultFamily)
    }
    
    static func clockFont(for size: CGSize) -> Font {
        let scaleFactor = min(size.width / 800, size.height / 600) // Base desktop size
        let fontSize = Size.display1 * scaleFactor
        return Font.system(size: fontSize, weight: Weight.black, design: defaultFamily)
    }
    
    // MARK: - Dynamic Type Support
    
    static func scaledFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = defaultFamily,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        return Font.system(size: size, weight: weight, design: design)
            .monospacedDigit() // Useful for timer displays
    }
    
    // MARK: - Text Styling Helpers
    
    struct TextStyle {
        let font: Font
        let color: Color
        let lineSpacing: CGFloat?
        let tracking: CGFloat?
        
        init(
            font: Font,
            color: Color = AppColors.primaryText,
            lineSpacing: CGFloat? = nil,
            tracking: CGFloat? = nil
        ) {
            self.font = font
            self.color = color
            self.lineSpacing = lineSpacing
            self.tracking = tracking
        }
    }
    
    // Predefined text styles
    static let timerDisplayStyle = TextStyle(
        font: timerDisplay,
        color: AppColors.primaryText,
        tracking: 2
    )
    
    static let titleStyle = TextStyle(
        font: title1,
        color: AppColors.primaryText,
        lineSpacing: 4
    )
    
    static let bodyStyle = TextStyle(
        font: body,
        color: AppColors.primaryText,
        lineSpacing: 2
    )
    
    static let captionStyle = TextStyle(
        font: caption,
        color: AppColors.secondaryText,
        tracking: 0.5
    )
    
    static let quoteStyle = TextStyle(
        font: quoteText,
        color: AppColors.secondaryText,
        lineSpacing: 4,
        tracking: 0.3
    )
}

// MARK: - Font Environment

struct AppFontEnvironment {
    let scaleFactor: CGFloat
    let preferMonospaced: Bool
    let accessibilityEnabled: Bool
    
    static let `default` = AppFontEnvironment(
        scaleFactor: 1.0,
        preferMonospaced: false,
        accessibilityEnabled: false
    )
}

struct AppFontEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppFontEnvironment.default
}

extension EnvironmentValues {
    var appFontEnvironment: AppFontEnvironment {
        get { self[AppFontEnvironmentKey.self] }
        set { self[AppFontEnvironmentKey.self] = newValue }
    }
}

// MARK: - Text Modifiers

struct AppTextStyle: ViewModifier {
    let style: AppFonts.TextStyle
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(style.color)
            .apply {
                if let lineSpacing = style.lineSpacing {
                    $0.lineSpacing(lineSpacing)
                } else {
                    $0
                }
            }
            .apply {
                if let tracking = style.tracking {
                    $0.tracking(tracking)
                } else {
                    $0
                }
            }
    }
}

extension View {
    func appTextStyle(_ style: AppFonts.TextStyle) -> some View {
        modifier(AppTextStyle(style: style))
    }
    
    func timerDisplayStyle() -> some View {
        appTextStyle(AppFonts.timerDisplayStyle)
    }
    
    func titleStyle() -> some View {
        appTextStyle(AppFonts.titleStyle)
    }
    
    func bodyStyle() -> some View {
        appTextStyle(AppFonts.bodyStyle)
    }
    
    func captionStyle() -> some View {
        appTextStyle(AppFonts.captionStyle)
    }
    
    func quoteStyle() -> some View {
        appTextStyle(AppFonts.quoteStyle)
    }
}

// MARK: - Helper Extension

extension View {
    @ViewBuilder
    func apply<Content: View>(@ViewBuilder transform: (Self) -> Content) -> some View {
        transform(self)
    }
}

// MARK: - Accessibility Support

extension AppFonts {
    static func accessibilityFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = defaultFamily
    ) -> Font {
        // In a real implementation, this would scale based on accessibility settings
        let scaledSize = size * 1.2 // Example scaling for accessibility
        return Font.system(size: scaledSize, weight: weight, design: design)
    }
    
    static var accessibilityTextStyles: [String: TextStyle] {
        return [
            "title": TextStyle(
                font: accessibilityFont(size: Size.large, weight: Weight.bold),
                color: AppColors.highContrastPrimary,
                lineSpacing: 6
            ),
            "body": TextStyle(
                font: accessibilityFont(size: Size.body),
                color: AppColors.highContrastPrimary,
                lineSpacing: 4
            ),
            "caption": TextStyle(
                font: accessibilityFont(size: Size.callout),
                color: AppColors.highContrastSecondary,
                tracking: 1
            )
        ]
    }
}
