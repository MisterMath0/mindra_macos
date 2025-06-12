//
//  ButtonStyles.swift
//  MindraTimer
//
//  Standardized button styles for the application
//

import SwiftUI

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    let size: ButtonSize
    let isEnabled: Bool
    
    enum ButtonSize {
        case small
        case medium
        case large
        
        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .medium:
                return EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
            case .large:
                return EdgeInsets(top: 14, leading: 28, bottom: 14, trailing: 28)
            }
        }
        
        var font: Font {
            switch self {
            case .small: return AppFonts.buttonSmall
            case .medium: return AppFonts.buttonMedium
            case .large: return AppFonts.buttonLarge
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 12
            }
        }
        
        var minHeight: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }
    }
    
    init(size: ButtonSize = .medium, isEnabled: Bool = true) {
        self.size = size
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(isEnabled ? AppColors.primaryButtonText : AppColors.disabledText)
            .padding(size.padding)
            .frame(minHeight: size.minHeight)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(backgroundGradient(for: configuration))
                    .shadow(
                        color: shadowColor(for: configuration),
                        radius: shadowRadius(for: configuration),
                        x: 0,
                        y: shadowOffset(for: configuration)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .disabled(!isEnabled)
    }
    
    private func backgroundGradient(for configuration: Configuration) -> LinearGradient {
        let baseColor = isEnabled ? AppColors.primaryButtonBackground : AppColors.disabledText.opacity(0.3)
        let topColor = configuration.isPressed ? baseColor.opacity(0.8) : baseColor
        let bottomColor = configuration.isPressed ? baseColor.opacity(1.0) : baseColor.opacity(0.9)
        
        return LinearGradient(
            colors: [topColor, bottomColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func shadowColor(for configuration: Configuration) -> Color {
        if !isEnabled { return .clear }
        return configuration.isPressed ? 
            AppColors.focusColor.opacity(0.2) : 
            AppColors.focusColor.opacity(0.4)
    }
    
    private func shadowRadius(for configuration: Configuration) -> CGFloat {
        if !isEnabled { return 0 }
        return configuration.isPressed ? 2 : 4
    }
    
    private func shadowOffset(for configuration: Configuration) -> CGFloat {
        if !isEnabled { return 0 }
        return configuration.isPressed ? 1 : 2
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    let size: PrimaryButtonStyle.ButtonSize
    let isEnabled: Bool
    
    init(size: PrimaryButtonStyle.ButtonSize = .medium, isEnabled: Bool = true) {
        self.size = size
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(isEnabled ? AppColors.secondaryButtonText : AppColors.disabledText)
            .padding(size.padding)
            .frame(minHeight: size.minHeight)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(backgroundColor(for: configuration))
                    .stroke(borderColor(for: configuration), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .disabled(!isEnabled)
    }
    
    private func backgroundColor(for configuration: Configuration) -> Color {
        if !isEnabled { return AppColors.disabledText.opacity(0.1) }
        return configuration.isPressed ? 
            AppColors.secondaryButtonPressed : 
            AppColors.secondaryButtonBackground
    }
    
    private func borderColor(for configuration: Configuration) -> Color {
        if !isEnabled { return AppColors.disabledText.opacity(0.2) }
        return configuration.isPressed ? 
            AppColors.borderColor.opacity(0.8) : 
            AppColors.borderColor
    }
}

// MARK: - Icon Button Style

struct IconButtonStyle: ButtonStyle {
    let size: IconSize
    let variant: IconVariant
    let isActive: Bool
    
    enum IconSize {
        case small
        case medium
        case large
        case extraLarge
        
        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            case .extraLarge: return 72
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            case .extraLarge: return 32
            }
        }
        
        var cornerRadius: CGFloat {
            return dimension / 2
        }
    }
    
    enum IconVariant {
        case filled
        case outlined
        case ghost
        case floating
        
        func backgroundColor(isActive: Bool, isPressed: Bool) -> Color {
            switch self {
            case .filled:
                if isActive {
                    return isPressed ? AppColors.focusColor.opacity(0.8) : AppColors.focusColor
                } else {
                    return isPressed ? AppColors.cardBackground.opacity(0.8) : AppColors.cardBackground
                }
            case .outlined:
                return isPressed ? AppColors.selectedBackground : Color.clear
            case .ghost:
                return isPressed ? AppColors.hoverBackground : Color.clear
            case .floating:
                return isPressed ? AppColors.cardBackground.opacity(0.9) : AppColors.cardBackground
            }
        }
        
        func borderColor(isActive: Bool) -> Color? {
            switch self {
            case .outlined:
                return isActive ? AppColors.focusColor : AppColors.borderColor
            case .floating:
                return AppColors.borderColor.opacity(0.3)
            default:
                return nil
            }
        }
        
        func iconColor(isActive: Bool) -> Color {
            switch self {
            case .filled:
                return isActive ? .white : AppColors.primaryText
            case .outlined, .ghost:
                return isActive ? AppColors.focusColor : AppColors.primaryText
            case .floating:
                return AppColors.primaryText
            }
        }
    }
    
    init(size: IconSize = .medium, variant: IconVariant = .ghost, isActive: Bool = false) {
        self.size = size
        self.variant = variant
        self.isActive = isActive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.iconSize, weight: .medium))
            .foregroundColor(variant.iconColor(isActive: isActive))
            .frame(width: size.dimension, height: size.dimension)
            .background(
                Circle()
                    .fill(variant.backgroundColor(isActive: isActive, isPressed: configuration.isPressed))
                    .overlay(
                        Circle()
                            .stroke(variant.borderColor(isActive: isActive) ?? Color.clear, lineWidth: 1)
                    )
                    .shadow(
                        color: variant == .floating ? AppColors.shadowColor : .clear,
                        radius: variant == .floating ? 4 : 0,
                        x: 0,
                        y: variant == .floating ? 2 : 0
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
}

// MARK: - Timer Control Button Style

struct TimerControlButtonStyle: ButtonStyle {
    let isPrimary: Bool
    let timerMode: TimerMode
    
    init(isPrimary: Bool = false, timerMode: TimerMode = .focus) {
        self.isPrimary = isPrimary
        self.timerMode = timerMode
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(foregroundColor(for: configuration))
            .frame(width: 56, height: 56)
            .background(
                Circle()
                    .fill(backgroundColor(for: configuration))
                    .shadow(
                        color: shadowColor(for: configuration),
                        radius: shadowRadius(for: configuration),
                        x: 0,
                        y: shadowOffset(for: configuration)
                    )
            )
            .scaleEffect(scaleEffect(for: configuration))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
    
    private func backgroundColor(for configuration: Configuration) -> Color {
        if isPrimary {
            let baseColor = AppColors.timerColor(for: timerMode)
            return configuration.isPressed ? baseColor.opacity(0.8) : baseColor
        } else {
            return configuration.isPressed ? 
                AppColors.secondaryButtonPressed : 
                AppColors.secondaryButtonBackground
        }
    }
    
    private func foregroundColor(for configuration: Configuration) -> Color {
        return isPrimary ? .white : AppColors.primaryText
    }
    
    private func shadowColor(for configuration: Configuration) -> Color {
        if isPrimary {
            return configuration.isPressed ? 
                AppColors.timerColor(for: timerMode).opacity(0.3) : 
                AppColors.timerColor(for: timerMode).opacity(0.5)
        } else {
            return .clear
        }
    }
    
    private func shadowRadius(for configuration: Configuration) -> CGFloat {
        return isPrimary ? (configuration.isPressed ? 3 : 6) : 0
    }
    
    private func shadowOffset(for configuration: Configuration) -> CGFloat {
        return isPrimary ? (configuration.isPressed ? 1 : 3) : 0
    }
    
    private func scaleEffect(for configuration: Configuration) -> CGFloat {
        if isPrimary {
            return configuration.isPressed ? 0.94 : 1.0
        } else {
            return configuration.isPressed ? 0.96 : 1.0
        }
    }
}

// MARK: - Mode Selection Button Style

struct ModeSelectionButtonStyle: ButtonStyle {
    let isSelected: Bool
    let mode: TimerMode
    
    init(isSelected: Bool, mode: TimerMode) {
        self.isSelected = isSelected
        self.mode = mode
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(textColor(for: configuration))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor(for: configuration))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor(for: configuration), lineWidth: isSelected ? 1 : 0)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isSelected ? 1.0 : 0.98))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    private func backgroundColor(for configuration: Configuration) -> Color {
        if isSelected {
            let baseColor = AppColors.timerColor(for: mode)
            return configuration.isPressed ? baseColor.opacity(0.8) : baseColor
        } else {
            return configuration.isPressed ? 
                AppColors.hoverBackground : 
                AppColors.cardBackground.opacity(0.5)
        }
    }
    
    private func textColor(for configuration: Configuration) -> Color {
        return isSelected ? .white : AppColors.secondaryText
    }
    
    private func borderColor(for configuration: Configuration) -> Color {
        return isSelected ? AppColors.timerColor(for: mode).opacity(0.5) : .clear
    }
}

// MARK: - Navigation Button Style

struct NavigationButtonStyle: ButtonStyle {
    let isActive: Bool
    
    init(isActive: Bool = false) {
        self.isActive = isActive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(foregroundColor(for: configuration))
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(backgroundColor(for: configuration))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isActive ? 1.05 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
    
    private func backgroundColor(for configuration: Configuration) -> Color {
        if isActive {
            return configuration.isPressed ? 
                AppColors.focusColor.opacity(0.2) : 
                AppColors.focusColor.opacity(0.15)
        } else {
            return configuration.isPressed ? 
                AppColors.hoverBackground : 
                Color.clear
        }
    }
    
    private func foregroundColor(for configuration: Configuration) -> Color {
        return isActive ? AppColors.focusColor : AppColors.secondaryText
    }
}

// MARK: - Button Extensions

extension View {
    func primaryButtonStyle(size: PrimaryButtonStyle.ButtonSize = .medium, isEnabled: Bool = true) -> some View {
        self.buttonStyle(PrimaryButtonStyle(size: size, isEnabled: isEnabled))
    }
    
    func secondaryButtonStyle(size: PrimaryButtonStyle.ButtonSize = .medium, isEnabled: Bool = true) -> some View {
        self.buttonStyle(SecondaryButtonStyle(size: size, isEnabled: isEnabled))
    }
    
    func iconButtonStyle(
        size: IconButtonStyle.IconSize = .medium,
        variant: IconButtonStyle.IconVariant = .ghost,
        isActive: Bool = false
    ) -> some View {
        self.buttonStyle(IconButtonStyle(size: size, variant: variant, isActive: isActive))
    }
    
    func timerControlButtonStyle(isPrimary: Bool = false, timerMode: TimerMode = .focus) -> some View {
        self.buttonStyle(TimerControlButtonStyle(isPrimary: isPrimary, timerMode: timerMode))
    }
    
    func modeSelectionButtonStyle(isSelected: Bool, mode: TimerMode) -> some View {
        self.buttonStyle(ModeSelectionButtonStyle(isSelected: isSelected, mode: mode))
    }
    
    func navigationButtonStyle(isActive: Bool = false) -> some View {
        self.buttonStyle(NavigationButtonStyle(isActive: isActive))
    }
}

// MARK: - Accessibility Support

extension PrimaryButtonStyle {
    func accessibilityButtonStyle() -> some View {
        // Return a modified version with better accessibility
        EmptyView() // Placeholder for accessibility implementation
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct ButtonStylePreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Group {
                Button("Primary Large") {}
                    .primaryButtonStyle(size: .large)
                
                Button("Primary Medium") {}
                    .primaryButtonStyle(size: .medium)
                
                Button("Primary Small") {}
                    .primaryButtonStyle(size: .small)
                
                Button("Secondary") {}
                    .secondaryButtonStyle()
                
                Button(action: {}) {
                    Image(systemName: "play.fill")
                }
                .iconButtonStyle(variant: .filled, isActive: true)
                
                Button(action: {}) {
                    Image(systemName: "gear")
                }
                .iconButtonStyle(variant: .ghost)
            }
            
            HStack {
                Button("FOCUS") {}
                    .modeSelectionButtonStyle(isSelected: true, mode: .focus)
                
                Button("BREAK") {}
                    .modeSelectionButtonStyle(isSelected: false, mode: .shortBreak)
            }
        }
        .padding()
        .background(AppColors.primaryBackground)
    }
}

struct ButtonStylePreview_Previews: PreviewProvider {
    static var previews: some View {
        ButtonStylePreview()
    }
}
#endif
