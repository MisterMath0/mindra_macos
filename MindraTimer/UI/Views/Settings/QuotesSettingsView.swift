//
//  QuotesSettingsView.swift
//  MindraTimer
//
//  🌟 PREMIUM QUOTES SETTINGS
//  Completely redesigned with world-class UI components
//

import SwiftUI

struct QuotesSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var quotesManager: QuotesManager
    
    @State private var showCurrentQuote = false
    
    var body: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: "Quotes Settings",
                subtitle: "Customize your inspirational quotes and motivation"
            ) {
                VStack(spacing: 24) {
                    // Main Quote Settings
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Quote Preferences",
                            subtitle: "Configure how quotes appear in your app",
                            icon: "quote.bubble",
                            color: AppColors.infoColor
                        )
                        
                        VStack(spacing: 12) {
                            ModernToggleCard(
                                title: "Show Inspirational Quotes",
                                subtitle: "Display motivational quotes during focus",
                                icon: "quote.bubble.fill",
                                color: AppColors.infoColor,
                                isOn: Binding(
                                    get: { coordinator.showQuotes },
                                    set: { coordinator.updateShowQuotes($0, statsManager: statsManager) }
                                ),
                                description: "Beautiful, carefully curated quotes to inspire and motivate you during your focus sessions."
                            )
                            
                            if coordinator.showQuotes {
                                ModernToggleCard(
                                    title: "Personalized Quotes",
                                    subtitle: "Include your name in quotes",
                                    icon: "person.fill.badge.plus",
                                    color: AppColors.successColor,
                                    isOn: Binding(
                                        get: { coordinator.enablePersonalizedQuotes },
                                        set: { coordinator.updateEnablePersonalizedQuotes($0, statsManager: statsManager, quotesManager: quotesManager) }
                                    ),
                                    description: "Transform quotes to include your name for a more personal, motivating experience."
                                )
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                                    removal: .scale(scale: 1.05).combined(with: .opacity)
                                ))
                            }
                        }
                    }
                    
                    // Quote Categories (only shown when quotes are enabled)
                    if coordinator.showQuotes {
                        VStack(spacing: 16) {
                            SectionHeader(
                                title: "Quote Categories",
                                subtitle: "Choose the types of quotes you'd like to see",
                                icon: "tag.fill",
                                color: AppColors.warningColor
                            )
                            
                            TitledCard(
                                "Categories",
                                subtitle: "Select your preferred quote themes"
                            ) {
                                ModernCategoryGrid(
                                    categories: Array(QuoteCategory.allCases),
                                    selectedCategories: Binding(
                                        get: { statsManager.settings.selectedQuoteCategories },
                                        set: { statsManager.settings.selectedQuoteCategories = $0 }
                                    ),
                                    categoryDisplayName: { $0.displayName },
                                    categoryIcon: { $0.icon },
                                    categoryColor: { $0.color }
                                )
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 1.05).combined(with: .opacity)
                        ))
                        
                        // Quote Timing Settings
                        VStack(spacing: 16) {
                            SectionHeader(
                                title: "Quote Timing",
                                subtitle: "Control when and how often quotes change",
                                icon: "clock.arrow.2.circlepath",
                                color: AppColors.focusColor
                            )
                            
                            ModernQuoteIntervalSlider(
                                interval: $coordinator.quoteInterval,
                                color: AppColors.focusColor
                            ) { newValue in
                                coordinator.updateQuoteInterval(newValue)
                                statsManager.settingsManager.quoteRefreshInterval = Int(newValue)
                                quotesManager.setQuoteInterval(minutes: Int(newValue))
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 1.05).combined(with: .opacity)
                        ))
                        
                        // Current Quote Display
                        VStack(spacing: 16) {
                            SectionHeader(
                                title: "Current Quote",
                                subtitle: "Preview and refresh your inspiration",
                                icon: "sparkles",
                                color: AppColors.shortBreakColor
                            )
                            
                            ModernQuoteDisplayCard(
                                quote: quotesManager.currentQuote,
                                showQuote: $showCurrentQuote,
                                color: AppColors.shortBreakColor
                            ) {
                                // Refresh quote action
                                quotesManager.updateQuoteIfNeeded(force: true)
                                withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showCurrentQuote.toggle()
                                }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 1.05).combined(with: .opacity)
                        ))
                        
                        // Quote Statistics
                        VStack(spacing: 16) {
                            SectionHeader(
                                title: "Quote Statistics",
                                subtitle: "Your quote preferences and usage",
                                icon: "chart.bar.fill",
                                color: AppColors.successColor
                            )
                            
                            QuoteStatsCard(
                                categoriesCount: statsManager.settings.selectedQuoteCategories.count,
                                totalCategories: QuoteCategory.allCases.count,
                                intervalMinutes: Int(coordinator.quoteInterval),
                                isPersonalized: coordinator.enablePersonalizedQuotes
                            )
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 1.05).combined(with: .opacity)
                        ))
                    }
                    
                    // Quote Tips Section
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Pro Tips",
                            subtitle: "Maximize your motivation with these insights",
                            icon: "lightbulb.fill",
                            color: AppColors.warningColor
                        )
                        
                        TitledCard(
                            "Quote Optimization",
                            subtitle: "Get the most out of your quotes"
                        ) {
                            VStack(spacing: 16) {
                                QuoteTipRow(
                                    icon: "person.crop.circle.badge.plus",
                                    title: "Add your name for personalization",
                                    description: "Quotes become 3x more motivating when they include your name",
                                    color: AppColors.successColor,
                                    isCompleted: !coordinator.userName.isEmpty && coordinator.enablePersonalizedQuotes
                                )
                                
                                QuoteTipRow(
                                    icon: "tag.fill",
                                    title: "Select multiple categories",
                                    description: "Mix different themes for varied daily inspiration",
                                    color: AppColors.infoColor,
                                    isCompleted: statsManager.settings.selectedQuoteCategories.count >= 3
                                )
                                
                                QuoteTipRow(
                                    icon: "clock.arrow.2.circlepath",
                                    title: "Optimize refresh interval",
                                    description: "5-10 minutes keeps quotes fresh without distraction",
                                    color: AppColors.focusColor,
                                    isCompleted: coordinator.quoteInterval >= 5 && coordinator.quoteInterval <= 10
                                )
                            }
                        }
                    }
                }
            }
        }
        .animation(Animation.spring(response: 0.4, dampingFraction: 0.8), value: coordinator.showQuotes)
        .onAppear {
            showCurrentQuote = true
        }
    }
}

// MARK: - Modern Quote Interval Slider

struct ModernQuoteIntervalSlider: View {
    @Binding var interval: Double
    let color: Color
    let onValueChanged: (Double) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        AppCard(style: .elevated, shadow: .subtle) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(color.opacity(0.1))
                        )
                    
                    Text("Quote Refresh Interval")
                        .font(AppFonts.calloutSemibold)
                        .foregroundColor(AppColors.primaryText)
                    
                    Spacer()
                    
                    Text("\(Int(interval)) min")
                        .font(AppFonts.captionSemibold)
                        .foregroundColor(color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(color.opacity(0.1))
                        )
                }
                
                // Custom slider with time markers
                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            Capsule()
                                .fill(AppColors.progressBackground)
                                .frame(height: 8)
                            
                            // Progress
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [color, color.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: progressWidth(for: geometry.size.width),
                                    height: 8
                                )
                            
                            // Thumb
                            Circle()
                                .fill(.white)
                                .frame(width: 20, height: 20)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                .overlay(
                                    Circle()
                                        .stroke(color, lineWidth: 2)
                                )
                                .offset(x: thumbOffset(for: geometry.size.width))
                                .scaleEffect(isDragging ? 1.3 : 1.0)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            isDragging = true
                                            let newInterval = intervalFromOffset(value.location.x, width: geometry.size.width)
                                            interval = newInterval
                                            onValueChanged(newInterval)
                                        }
                                        .onEnded { _ in
                                            isDragging = false
                                        }
                                )
                        }
                    }
                    .frame(height: 20)
                    
                    // Time markers
                    HStack {
                        Text("1 min")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.tertiaryText)
                        
                        Spacer()
                        
                        Text("30 min")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.tertiaryText)
                        
                        Spacer()
                        
                        Text("60 min")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.tertiaryText)
                    }
                }
                
                // Preset intervals
                HStack(spacing: 12) {
                    ForEach([5, 10, 15, 30], id: \.self) { preset in
                        Button(action: {
                            withAnimation(Animation.spring(response: 0.3, dampingFraction: 0.7)) {
                                interval = Double(preset)
                            }
                            onValueChanged(Double(preset))
                        }) {
                            Text("\(preset)m")
                                .font(AppFonts.caption)
                                .foregroundColor(Int(interval) == preset ? .white : AppColors.secondaryText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Int(interval) == preset ? color : AppColors.tertiaryBackground)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Text("How often quotes change during focus sessions")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .animation(Animation.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        let progress = (interval - 1) / (60 - 1)
        return max(0, min(totalWidth, totalWidth * CGFloat(progress)))
    }
    
    private func thumbOffset(for totalWidth: CGFloat) -> CGFloat {
        let progress = (interval - 1) / (60 - 1)
        return max(0, min(totalWidth - 10, (totalWidth - 20) * CGFloat(progress)))
    }
    
    private func intervalFromOffset(_ offset: CGFloat, width: CGFloat) -> Double {
        let progress = max(0, min(1, offset / width))
        return 1 + (progress * 59) // 1 to 60 minutes
    }
}

// MARK: - Modern Quote Display Card

struct ModernQuoteDisplayCard: View {
    let quote: String
    @Binding var showQuote: Bool
    let color: Color
    let onRefresh: () -> Void
    
    @State private var isRefreshing = false
    
    var body: some View {
        AppCard(style: .elevated, shadow: .elevated) {
            VStack(spacing: 20) {
                // Quote text with typing animation
                VStack(spacing: 16) {
                    if showQuote {
                        Text("\"\(quote)\"")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.primaryText)
                            .multilineTextAlignment(.center)
                            .italic()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .leading)),
                                removal: .opacity.combined(with: .move(edge: .trailing))
                            ))
                    }
                }
                .frame(minHeight: 60)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(color.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Refresh button
                AppButton.secondary(
                    "Get New Quote",
                    action: {
                        withAnimation(Animation.spring(response: 0.3, dampingFraction: 0.7)) {
                            isRefreshing = true
                            showQuote = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onRefresh()
                            
                            withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.8)) {
                                showQuote = true
                                isRefreshing = false
                            }
                        }
                    },
                    size: .medium,
                    icon: isRefreshing ? "arrow.2.circlepath" : "sparkles"
                )
            }
        }
        .animation(Animation.spring(response: 0.4, dampingFraction: 0.8), value: showQuote)
    }
}

// MARK: - Quote Stats Card

struct QuoteStatsCard: View {
    let categoriesCount: Int
    let totalCategories: Int
    let intervalMinutes: Int
    let isPersonalized: Bool
    
    var body: some View {
        TitledCard(
            "Quote Statistics",
            subtitle: "Your quote preferences overview"
        ) {
            VStack(spacing: 16) {
                HStack(spacing: 24) {
                    StatItem(
                        icon: "tag.fill",
                        title: "Categories",
                        value: "\(categoriesCount)/\(totalCategories)",
                        color: AppColors.infoColor
                    )
                    
                    StatItem(
                        icon: "clock.arrow.2.circlepath",
                        title: "Interval",
                        value: "\(intervalMinutes)m",
                        color: AppColors.focusColor
                    )
                    
                    StatItem(
                        icon: "person.fill.badge.plus",
                        title: "Personal",
                        value: isPersonalized ? "Yes" : "No",
                        color: isPersonalized ? AppColors.successColor : AppColors.tertiaryText
                    )
                }
                
                // Progress bar for category selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Category Coverage")
                            .font(AppFonts.captionMedium)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Spacer()
                        
                        Text("\(Int(Double(categoriesCount) / Double(totalCategories) * 100))%")
                            .font(AppFonts.captionSemibold)
                            .foregroundColor(AppColors.infoColor)
                    }
                    
                    ProgressView(value: Double(categoriesCount), total: Double(totalCategories))
                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.infoColor))
                        .background(AppColors.progressBackground)
                }
            }
        }
    }
    
    private func StatItem(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(spacing: 2) {
                Text(value)
                    .font(AppFonts.calloutSemibold)
                    .foregroundColor(AppColors.primaryText)
                
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quote Tip Row

struct QuoteTipRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isCompleted ? color : AppColors.tertiaryBackground)
                    .frame(width: 40, height: 40)
                
                Image(systemName: isCompleted ? "checkmark" : icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isCompleted ? .white : AppColors.tertiaryText)
            }
            .animation(Animation.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.calloutMedium)
                    .foregroundColor(isCompleted ? AppColors.secondaryText : AppColors.primaryText)
                    .strikethrough(isCompleted)
                
                Text(description)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#if DEBUG
struct QuotesSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        QuotesSettingsView(coordinator: SettingsCoordinator())
            .environmentObject(StatsManager())
            .environmentObject(QuotesManager())
    }
}
#endif
