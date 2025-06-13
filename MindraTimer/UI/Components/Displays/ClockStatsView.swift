//
//  ClockStatsView.swift
//  MindraTimer
//
//  ✨ CLOCK STATS CARDS COMPONENT
//

import SwiftUI

struct ClockStatsView: View {
    let geometry: GeometryProxy
    @EnvironmentObject var statsManager: StatsManager
    
    var body: some View {
        HStack(spacing: max(16, geometry.size.width * 0.02)) {
            // Today's sessions
            ClockStatCard(
                title: "Today",
                value: "\(statsManager.getSessionsToday())",
                subtitle: "sessions",
                icon: "calendar.badge.clock",
                color: AppColors.successColor,
                geometry: geometry
            )
            
            // Current streak
            ClockStatCard(
                title: "Streak",
                value: "\(statsManager.getCurrentStreak())",
                subtitle: "days",
                icon: "flame.fill",
                color: AppColors.warningColor,
                geometry: geometry
            )
            
            // Time spent
            ClockStatCard(
                title: "Total",
                value: "\(statsManager.getTotalHours())h",
                subtitle: "focused",
                icon: "brain.head.profile",
                color: AppColors.focusColor,
                geometry: geometry
            )
        }
        .padding(.top, max(16, geometry.size.height * 0.02))
    }
}

struct ClockStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: max(6, geometry.size.height * 0.008)) {
            HStack(spacing: max(6, geometry.size.width * 0.008)) {
                Image(systemName: icon)
                    .font(.system(size: max(12, geometry.size.width * 0.014), weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: max(11, geometry.size.width * 0.013), weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(max(0.5, geometry.size.width * 0.0006))
            }
            
            Text(value)
                .font(.system(size: max(18, geometry.size.width * 0.022), weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: max(10, geometry.size.width * 0.012), weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, max(12, geometry.size.width * 0.015))
        .padding(.vertical, max(8, geometry.size.height * 0.01))
        .background(
            RoundedRectangle(cornerRadius: max(8, geometry.size.width * 0.01))
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: max(8, geometry.size.width * 0.01))
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
