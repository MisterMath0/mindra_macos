//
//  AppButton.swift
//  MindraTimer
//
//  Reusable button component following design system
//

import SwiftUI

struct AppButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyleType
    let size: ButtonSize
    let isEnabled: Bool
    let icon: String?
    
    enum ButtonStyleType {
        case primary
        case secondary
        case destructive
        case ghost
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 52
            }
        }
        
        var font: Font {
            switch self {
            case .small: return AppFonts.buttonSmall
            case .medium: return AppFonts.buttonMedium
            case .large: return AppFonts.buttonLarge
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            }
        }
    }
    
    init(
        _ title: String,
        action: @escaping () -> Void,
        style: ButtonStyleType = .primary,
        size: ButtonSize = .medium,
        isEnabled: Bool = true,
        icon: String? = nil
    ) {
        self.title = title
        self.action = action
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.icon = icon
    }
    
    var body: some View {
        Group {
            switch style {
            case .primary:
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(PrimaryButtonStyle(size: primaryButtonSize, isEnabled: isEnabled))
                
            case .secondary:
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(SecondaryButtonStyle(size: primaryButtonSize, isEnabled: isEnabled))
                
            case .destructive:
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(DestructiveButtonStyle(size: primaryButtonSize, isEnabled: isEnabled))
                
            case .ghost:
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(GhostButtonStyle(size: primaryButtonSize, isEnabled: isEnabled))
            }
        }
        .disabled(!isEnabled)
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: size.iconSize, weight: .medium))
            }
            
            Text(title)
                .font(size.font)
        }
    }
    
    private var primaryButtonSize: PrimaryButtonStyle.ButtonSize {
        switch size {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }
}

// MARK: - Destructive Button Style

struct DestructiveButtonStyle: ButtonStyle {
    let size: PrimaryButtonStyle.ButtonSize
    let isEnabled: Bool
    
    init(size: PrimaryButtonStyle.ButtonSize = .medium, isEnabled: Bool = true) {
        self.size = size
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(isEnabled ? .white : AppColors.disabledText)
            .padding(size.padding)
            .frame(minHeight: size.minHeight)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(backgroundColor(for: configuration))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .disabled(!isEnabled)
    }
    
    private func backgroundColor(for configuration: Configuration) -> Color {
        if !isEnabled { return AppColors.disabledText.opacity(0.3) }
        return configuration.isPressed ? 
            AppColors.errorColor.opacity(0.8) : 
            AppColors.errorColor
    }
}

// MARK: - Ghost Button Style

struct GhostButtonStyle: ButtonStyle {
    let size: PrimaryButtonStyle.ButtonSize
    let isEnabled: Bool
    
    init(size: PrimaryButtonStyle.ButtonSize = .medium, isEnabled: Bool = true) {
        self.size = size
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(isEnabled ? AppColors.primaryText : AppColors.disabledText)
            .padding(size.padding)
            .frame(minHeight: size.minHeight)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(backgroundColor(for: configuration))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .disabled(!isEnabled)
    }
    
    private func backgroundColor(for configuration: Configuration) -> Color {
        if !isEnabled { return .clear }
        return configuration.isPressed ? 
            AppColors.pressedBackground : 
            AppColors.hoverBackground
    }
}

// MARK: - Convenience Initializers

extension AppButton {
    static func primary(
        _ title: String,
        action: @escaping () -> Void,
        size: ButtonSize = .medium,
        isEnabled: Bool = true,
        icon: String? = nil
    ) -> AppButton {
        AppButton(title, action: action, style: .primary, size: size, isEnabled: isEnabled, icon: icon)
    }
    
    static func secondary(
        _ title: String,
        action: @escaping () -> Void,
        size: ButtonSize = .medium,
        isEnabled: Bool = true,
        icon: String? = nil
    ) -> AppButton {
        AppButton(title, action: action, style: .secondary, size: size, isEnabled: isEnabled, icon: icon)
    }
    
    static func destructive(
        _ title: String,
        action: @escaping () -> Void,
        size: ButtonSize = .medium,
        isEnabled: Bool = true,
        icon: String? = nil
    ) -> AppButton {
        AppButton(title, action: action, style: .destructive, size: size, isEnabled: isEnabled, icon: icon)
    }
    
    static func ghost(
        _ title: String,
        action: @escaping () -> Void,
        size: ButtonSize = .medium,
        isEnabled: Bool = true,
        icon: String? = nil
    ) -> AppButton {
        AppButton(title, action: action, style: .ghost, size: size, isEnabled: isEnabled, icon: icon)
    }
}

// MARK: - Preview

#if DEBUG
struct AppButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            AppButton.primary("Primary Button", action: { })
            AppButton.secondary("Secondary Button", action: { })
            AppButton.destructive("Delete", action: { }, icon: "trash")
            AppButton.ghost("Cancel", action: { })
            
            HStack {
                AppButton.primary("Small", action: { }, size: .small)
                AppButton.primary("Medium", action: { }, size: .medium)
                AppButton.primary("Large", action: { }, size: .large)
            }
            
            AppButton.primary("Disabled", action: { }, isEnabled: false)
        }
        .padding()
        .background(AppColors.primaryBackground)
    }
}
#endif
