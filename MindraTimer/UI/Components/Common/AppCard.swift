//
//  AppCard.swift
//  MindraTimer
//
//  Reusable card component following design system
//

import SwiftUI

// MARK: - Card Style (moved outside generic type)
enum CardStyle {
    case standard
    case elevated
    case outlined
    case minimal
    
    var backgroundColor: Color {
        switch self {
        case .standard: return AppColors.cardBackground
        case .elevated: return AppColors.elevatedCardBackground
        case .outlined: return AppColors.cardBackground
        case .minimal: return Color.clear
        }
    }
    
    var borderColor: Color? {
        switch self {
        case .outlined: return AppColors.borderColor
        default: return nil
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .outlined: return 1
        default: return 0
        }
    }
}

struct AppCard<Content: View>: View {
    let content: Content
    let style: CardStyle
    let padding: EdgeInsets
    let cornerRadius: CGFloat
    let shadow: ShadowConfig?
    
    struct ShadowConfig {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        static var standard: ShadowConfig {
            ShadowConfig(
                color: AppColors.shadowColor,
                radius: 4,
                x: 0,
                y: 2
            )
        }
        
        static var elevated: ShadowConfig {
            ShadowConfig(
                color: AppColors.shadowColor,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        
        static var subtle: ShadowConfig {
            ShadowConfig(
                color: AppColors.shadowColor.opacity(0.5),
                radius: 2,
                x: 0,
                y: 1
            )
        }
    }
    
    init(
        style: CardStyle = .standard,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = 12,
        shadow: ShadowConfig? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(style.borderColor ?? Color.clear, lineWidth: style.borderWidth)
                    )
                    .shadow(
                        color: shadow?.color ?? Color.clear,
                        radius: shadow?.radius ?? 0,
                        x: shadow?.x ?? 0,
                        y: shadow?.y ?? 0
                    )
            )
    }
}

// MARK: - Card with Title

struct TitledCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    let style: CardStyle
    let titleFont: Font
    let subtitleFont: Font
    
    init(
        _ title: String,
        subtitle: String? = nil,
        style: CardStyle = .standard,
        titleFont: Font = AppFonts.cardTitle,
        subtitleFont: Font = AppFonts.cardSubtitle,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.style = style
        self.titleFont = titleFont
        self.subtitleFont = subtitleFont
    }
    
    var body: some View {
        AppCard(style: style) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(titleFont)
                        .foregroundColor(AppColors.primaryText)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(subtitleFont)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                content
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String?
    let color: Color
    let trend: TrendDirection?
    let trendValue: String?
    
    enum TrendDirection {
        case up
        case down
        case neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return AppColors.successColor
            case .down: return AppColors.errorColor
            case .neutral: return AppColors.secondaryText
            }
        }
    }
    
    init(
        title: String,
        value: String,
        icon: String? = nil,
        color: Color = AppColors.focusColor,
        trend: TrendDirection? = nil,
        trendValue: String? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
        self.trendValue = trendValue
    }
    
    var body: some View {
        AppCard(style: .standard, shadow: .subtle) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(color)
                    }
                    
                    Text(title)
                        .font(AppFonts.captionMedium)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Spacer()
                    
                    if let trend = trend, let trendValue = trendValue {
                        HStack(spacing: 4) {
                            Image(systemName: trend.icon)
                                .font(.system(size: 10, weight: .medium))
                            Text(trendValue)
                                .font(AppFonts.caption2)
                        }
                        .foregroundColor(trend.color)
                    }
                }
                
                Text(value)
                    .font(AppFonts.statValue)
                    .foregroundColor(AppColors.primaryText)
            }
        }
    }
}

// MARK: - Progress Card

struct ProgressCard: View {
    let title: String
    let progress: Double
    let total: Double
    let color: Color
    let showPercentage: Bool
    
    init(
        title: String,
        progress: Double,
        total: Double,
        color: Color = AppColors.focusColor,
        showPercentage: Bool = true
    ) {
        self.title = title
        self.progress = progress
        self.total = total
        self.color = color
        self.showPercentage = showPercentage
    }
    
    private var progressPercentage: Double {
        guard total > 0 else { return 0 }
        return min(1.0, progress / total)
    }
    
    var body: some View {
        AppCard(style: .standard) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(AppFonts.calloutMedium)
                        .foregroundColor(AppColors.primaryText)
                    
                    Spacer()
                    
                    if showPercentage {
                        Text("\(Int(progressPercentage * 100))%")
                            .font(AppFonts.captionMedium)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: color))
                        .background(AppColors.progressBackground)
                    
                    HStack {
                        Text(formatValue(progress))
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Spacer()
                        
                        Text(formatValue(total))
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.tertiaryText)
                    }
                }
            }
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        } else if value >= 60 {
            let hours = Int(value) / 60
            let minutes = Int(value) % 60
            return "\(hours)h \(minutes)m"
        } else {
            return "\(Int(value))"
        }
    }
}

// MARK: - Action Card

struct ActionCard: View {
    let title: String
    let description: String?
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(
        title: String,
        description: String? = nil,
        icon: String,
        color: Color = AppColors.focusColor,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            AppCard(style: .standard) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(color.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppFonts.calloutSemibold)
                            .foregroundColor(AppColors.primaryText)
                        
                        if let description = description {
                            Text(description)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.tertiaryText)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Convenience Extensions

extension AppCard {
    static func standard<T: View>(@ViewBuilder content: () -> T) -> AppCard<T> {
        AppCard<T>(style: .standard, content: content)
    }
    
    static func elevated<T: View>(@ViewBuilder content: () -> T) -> AppCard<T> {
        AppCard<T>(style: .elevated, shadow: .elevated, content: content)
    }
    
    static func outlined<T: View>(@ViewBuilder content: () -> T) -> AppCard<T> {
        AppCard<T>(style: .outlined, content: content)
    }
    
    static func minimal<T: View>(@ViewBuilder content: () -> T) -> AppCard<T> {
        AppCard<T>(style: .minimal, content: content)
    }
}

// MARK: - Preview

#if DEBUG
struct AppCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                TitledCard("Settings", subtitle: "Configure your preferences") {
                    Text("Card content goes here")
                        .foregroundColor(AppColors.secondaryText)
                }
                
                StatCard(
                    title: "Focus Time",
                    value: "2h 45m",
                    icon: "clock.fill",
                    trend: .up,
                    trendValue: "12%"
                )
                
                ProgressCard(
                    title: "Daily Goal",
                    progress: 165,
                    total: 240
                )
                
                ActionCard(
                    title: "Export Data",
                    description: "Download your stats as CSV",
                    icon: "square.and.arrow.up"
                ) { }
            }
            .padding()
        }
        .background(AppColors.primaryBackground)
    }
}
#endif
