//
//  StatsSettingsView.swift
//  MindraTimer
//
//  📊 PREMIUM STATS & ACHIEVEMENTS SETTINGS
//  Beautiful statistics overview with modern achievement tracking
//

import SwiftUI

struct StatsSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @EnvironmentObject var statsManager: StatsManager
    
    @State private var showAchievementDetails = false
    
    var body: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: "Stats & Achievements",
                subtitle: "Track your progress and unlock achievements"
            ) {
                VStack(spacing: 24) {
                    // Stats Overview Section
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Your Progress",
                            subtitle: "See how you're doing with your focus goals",
                            icon: "chart.line.uptrend.xyaxis",
                            color: AppColors.successColor
                        )
                        
                        ModernStatsOverviewCard(statsManager: statsManager)
                    }
                    
                    // Stats Configuration
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Stats Configuration",
                            subtitle: "Customize how your statistics are displayed",
                            icon: "gear.badge",
                            color: AppColors.focusColor
                        )
                        
                        VStack(spacing: 12) {
                            ModernToggleCard(
                                title: "Show Streak Counter",
                                subtitle: "Display your current focus streak",
                                icon: "flame.fill",
                                color: AppColors.errorColor,
                                isOn: Binding(
                                    get: { coordinator.showStreakCounter },
                                    set: { coordinator.updateShowStreakCounter($0, statsManager: statsManager) }
                                ),
                                description: "Motivate yourself by tracking consecutive days of successful focus sessions."
                            )
                            
                            ModernToggleCard(
                                title: "Stats Notifications",
                                subtitle: "Get notified about achievements",
                                icon: "bell.badge.fill",
                                color: AppColors.infoColor,
                                isOn: Binding(
                                    get: { coordinator.showStatsNotifications },
                                    set: { coordinator.updateShowStatsNotifications($0, statsManager: statsManager) }
                                ),
                                description: "Receive notifications when you unlock new achievements or reach milestones."
                            )
                        }
                    }
                    
                    // Display Period Selector
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Display Period",
                            subtitle: "Choose the time range for your statistics",
                            icon: "calendar.badge.clock",
                            color: AppColors.longBreakColor
                        )
                        
                        ModernPeriodSelector(
                            selectedPeriod: Binding(
                                get: { statsManager.settingsManager.displayPeriod },
                                set: { statsManager.setDisplayPeriod($0) }
                            )
                        )
                    }
                    
                    // Achievements Section
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Achievements",
                            subtitle: "Your accomplishments and progress milestones",
                            icon: "trophy.fill",
                            color: AppColors.warningColor
                        )
                        
                        ModernAchievementsCard(
                            achievements: statsManager.achievements,
                            showDetails: $showAchievementDetails
                        )
                    }
                    
                    // Debug Section (only in DEBUG builds)
                    #if DEBUG
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Developer Tools",
                            subtitle: "Debug and testing utilities",
                            icon: "hammer.fill",
                            color: AppColors.tertiaryText
                        )
                        
                        ModernDebugToolsCard(statsManager: statsManager)
                    }
                    #endif
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showAchievementDetails)
    }
}

// MARK: - Modern Stats Overview Card

struct ModernStatsOverviewCard: View {
    @ObservedObject var statsManager: StatsManager
    
    var body: some View {
        TitledCard(
            "Statistics Overview",
            subtitle: "Your productivity metrics at a glance"
        ) {
            VStack(spacing: 20) {
                // Primary stats grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                    StatsMetricCard(
                        title: "Focus Time",
                        value: formatTime(statsManager.summary.totalFocusTime),
                        icon: "clock.fill",
                        color: AppColors.focusColor
                    )
                    
                    StatsMetricCard(
                        title: "Sessions",
                        value: "\(statsManager.summary.totalSessions)",
                        icon: "number.circle.fill",
                        color: AppColors.successColor
                    )
                    
                    StatsMetricCard(
                        title: "Completion",
                        value: String(format: "%.1f%%", statsManager.summary.completionRate),
                        icon: "chart.pie.fill",
                        color: AppColors.infoColor
                    )
                }
                
                // Streak information
                HStack(spacing: 16) {
                    StreakCard(
                        title: "Current Streak",
                        value: "\(statsManager.summary.currentStreak)",
                        subtitle: "days",
                        color: AppColors.errorColor
                    )
                    
                    StreakCard(
                        title: "Best Streak",
                        value: "\(statsManager.summary.bestStreak)",
                        subtitle: "days",
                        color: AppColors.warningColor
                    )
                }
                
                // Quick insights
                if statsManager.summary.totalSessions > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Insights")
                            .font(AppFonts.captionSemibold)
                            .foregroundColor(AppColors.secondaryText)
                        
                        HStack(spacing: 12) {
                            InsightBadge(
                                text: "Avg. Session: \(formatTime(statsManager.summary.averageSessionLength))",
                                color: AppColors.longBreakColor
                            )
                            
                            InsightBadge(
                                text: statsManager.streakText,
                                color: AppColors.errorColor
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, remainingMinutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}

// MARK: - Stats Metric Card

struct StatsMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
            
            // Value and title
            VStack(spacing: 4) {
                Text(value)
                    .font(AppFonts.statValue)
                    .foregroundColor(AppColors.primaryText)
                
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(AppFonts.calloutSemibold)
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Insight Badge

struct InsightBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(AppFonts.caption)
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
            )
    }
}

// MARK: - Modern Period Selector

struct ModernPeriodSelector: View {
    @Binding var selectedPeriod: StatsPeriod
    
    private let periods: [(StatsPeriod, String, String)] = [
        (.day, "Today", "calendar"),
        (.week, "This Week", "calendar.badge.clock"),
        (.month, "This Month", "calendar.badge.plus"),
        (.all, "All Time", "calendar.badge.exclamationmark")
    ]
    
    var body: some View {
        AppCard(style: .elevated, shadow: .subtle) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.longBreakColor)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(AppColors.longBreakColor.opacity(0.1))
                        )
                    
                    Text("Statistics Period")
                        .font(AppFonts.calloutSemibold)
                        .foregroundColor(AppColors.primaryText)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(periods, id: \.0) { period in
                        PeriodOptionCard(
                            period: period.0,
                            title: period.1,
                            icon: period.2,
                            isSelected: selectedPeriod == period.0
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPeriod = period.0
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Period Option Card

struct PeriodOptionCard: View {
    let period: StatsPeriod
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : AppColors.secondaryText)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? AppColors.longBreakColor : AppColors.tertiaryBackground)
                    )
                
                Text(title)
                    .font(AppFonts.captionMedium)
                    .foregroundColor(isSelected ? AppColors.primaryText : AppColors.secondaryText)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? AppColors.longBreakColor.opacity(0.5) : AppColors.borderColor,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Modern Achievements Card

struct ModernAchievementsCard: View {
    let achievements: [Achievement]
    @Binding var showDetails: Bool
    
    private var unlockedCount: Int {
        achievements.filter { $0.unlocked }.count
    }
    
    private var totalCount: Int {
        achievements.count
    }
    
    var body: some View {
        TitledCard(
            "Achievements",
            subtitle: "\(unlockedCount)/\(totalCount) unlocked"
        ) {
            VStack(spacing: 16) {
                // Progress overview
                HStack(spacing: 16) {
                    // Achievement progress circle
                    ZStack {
                        Circle()
                            .stroke(AppColors.progressBackground, lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: totalCount > 0 ? CGFloat(unlockedCount) / CGFloat(totalCount) : 0)
                            .stroke(AppColors.warningColor, lineWidth: 8)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 60, height: 60)
                        
                        VStack(spacing: 2) {
                            Text("\(unlockedCount)")
                                .font(AppFonts.calloutSemibold)
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("/\(totalCount)")
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Achievement Progress")
                            .font(AppFonts.calloutMedium)
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("\(Int(Double(unlockedCount) / Double(max(totalCount, 1)) * 100))% completed")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        if unlockedCount > 0 {
                            Text("Great progress! Keep it up!")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.successColor)
                        }
                    }
                    
                    Spacer()
                }
                
                // Recent achievements preview
                if !achievements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Achievements")
                            .font(AppFonts.captionSemibold)
                            .foregroundColor(AppColors.secondaryText)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            ForEach(achievements.prefix(8), id: \.id) { achievement in
                                AchievementBadge(achievement: achievement)
                            }
                        }
                    }
                }
                
                // View all button
                AppButton.secondary(
                    "View All Achievements",
                    action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showDetails.toggle()
                        }
                    },
                    size: .medium,
                    icon: "trophy.fill"
                )
            }
        }
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 6) {
            Text(achievement.icon)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(achievement.unlocked ? AppColors.warningColor.opacity(0.2) : AppColors.tertiaryBackground)
                )
                .grayscale(achievement.unlocked ? 0 : 1)
                .opacity(achievement.unlocked ? 1.0 : 0.5)
            
            Text(achievement.title)
                .font(AppFonts.caption2)
                .foregroundColor(achievement.unlocked ? AppColors.primaryText : AppColors.tertiaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(6)
    }
}

// MARK: - Modern Debug Tools Card

#if DEBUG
struct ModernDebugToolsCard: View {
    @ObservedObject var statsManager: StatsManager
    
    var body: some View {
        TitledCard(
            "Debug Tools",
            subtitle: "Development and testing utilities"
        ) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    AppButton.secondary(
                        "Debug Stats",
                        action: {
                            statsManager.debugStats()
                        },
                        size: .small,
                        icon: "info.circle"
                    )
                    
                    AppButton.secondary(
                        "Debug Achievements",
                        action: {
                            statsManager.debugAchievements()
                        },
                        size: .small,
                        icon: "trophy"
                    )
                }
                
                HStack(spacing: 12) {
                    AppButton.primary(
                        "Add Test Data",
                        action: {
                            statsManager.addTestData()
                        },
                        size: .small,
                        icon: "plus.circle"
                    )
                    
                    AppButton.destructive(
                        "Clear All Data",
                        action: {
                            statsManager.clearAllData()
                        },
                        size: .small,
                        icon: "trash"
                    )
                }
            }
        }
    }
}
#endif

// MARK: - Preview

#if DEBUG
struct StatsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsSettingsView(coordinator: SettingsCoordinator())
            .environmentObject(StatsManager())
    }
}
#endif
