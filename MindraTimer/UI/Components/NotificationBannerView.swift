//
//  NotificationBannerView.swift
//  MindraTimer
//
//  SwiftUI component for displaying in-app notification banners
//

import SwiftUI

struct NotificationBannerView: View {
    let banner: NotificationBanner
    let onDismiss: () -> Void
    let onAction: ((String) -> Void)?
    
    @State private var isVisible = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(banner.type.color.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: banner.type.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(banner.type.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(banner.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                
                Text(banner.message)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Action button or dismiss
            HStack(spacing: 8) {
                if let actionText = banner.actionText,
                   let actionIdentifier = banner.actionIdentifier {
                    Button(actionText) {
                        onAction?(actionIdentifier)
                        onDismiss()
                    }
                    .buttonStyle(NotificationActionButtonStyle(color: banner.type.color))
                }
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.tertiaryText)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(AppColors.cardBackground)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(banner.type.color.opacity(0.3), lineWidth: 1)
        )
        .offset(x: dragOffset.width, y: dragOffset.height)
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow upward dragging
                    if value.translation.height < 0 {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    if value.translation.height < -50 {
                        // Dismiss if dragged up enough
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dragOffset = CGSize(width: 0, height: -200)
                            isVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Notification Action Button Style

struct NotificationActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Notification Banner Overlay

struct NotificationBannerOverlay: View {
    @ObservedObject var notificationService: NotificationService
    let onAction: ((String) -> Void)?
    
    var body: some View {
        VStack {
            if notificationService.showingBanner,
               let banner = notificationService.currentBanner {
                NotificationBannerView(
                    banner: banner,
                    onDismiss: {
                        notificationService.dismissCurrentBanner()
                    },
                    onAction: onAction
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            Spacer()
        }
        .allowsHitTesting(notificationService.showingBanner)
    }
}

// MARK: - Achievement Celebration View

struct AchievementCelebrationView: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.1
    @State private var rotation: Double = 0
    @State private var sparkleScale: CGFloat = 0
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            VStack(spacing: 24) {
                // Achievement icon with celebration effects
                ZStack {
                    // Sparkle effects
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(AppColors.warningColor.opacity(0.8))
                            .frame(width: 8, height: 8)
                            .offset(
                                x: cos(Double(index) * .pi / 4) * 100,
                                y: sin(Double(index) * .pi / 4) * 100
                            )
                            .scaleEffect(sparkleScale)
                    }
                    
                    // Main achievement circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.warningColor, AppColors.warningColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                    
                    // Achievement icon
                    Text(achievement.icon)
                        .font(.system(size: 48))
                        .rotationEffect(.degrees(rotation))
                }
                .scaleEffect(scale)
                
                if showContent {
                    VStack(spacing: 16) {
                        // Achievement title
                        Text("Achievement Unlocked!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        // Achievement details
                        VStack(spacing: 8) {
                            Text(achievement.title)
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.warningColor)
                                .multilineTextAlignment(.center)
                            
                            Text(achievement.description)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        // Dismiss button
                        Button("Awesome!") {
                            dismissWithAnimation()
                        }
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(AppColors.warningColor)
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(40)
        }
        .onAppear {
            startCelebrationAnimation()
        }
    }
    
    private func startCelebrationAnimation() {
        // Icon scale and rotation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.0
        }
        
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Sparkle effects
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            sparkleScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            sparkleScale = 0.0
        }
        
        // Show content after icon animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 0.1
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @ObservedObject var notificationService: NotificationService
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("In-App Notifications")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                VStack(spacing: 12) {
                    NotificationToggleRow(
                        title: "Banner Notifications",
                        description: "Show notification banners within the app",
                        isOn: $notificationService.enableInAppBanners
                    ) { enabled in
                        notificationService.updateBannerSettings(enabled)
                    }
                    
                    NotificationToggleRow(
                        title: "Milestone Progress",
                        description: "Get notified when you reach achievement milestones",
                        isOn: $notificationService.enableMilestoneNotifications
                    ) { enabled in
                        notificationService.updateMilestoneSettings(enabled)
                    }
                    
                    NotificationToggleRow(
                        title: "Achievement Celebrations",
                        description: "Celebrate when you unlock new achievements",
                        isOn: $notificationService.enableAchievementCelebrations
                    ) { enabled in
                        notificationService.updateAchievementSettings(enabled)
                    }
                    
                    NotificationToggleRow(
                        title: "Streak Reminders",
                        description: "Gentle reminders to maintain your focus streak",
                        isOn: $notificationService.enableStreakReminders
                    ) { enabled in
                        notificationService.updateStreakSettings(enabled)
                    }
                    
                    NotificationToggleRow(
                        title: "Encouragement Messages",
                        description: "Motivational messages to keep you going",
                        isOn: $notificationService.enableEncouragementMessages
                    ) { enabled in
                        notificationService.updateEncouragementSettings(enabled)
                    }
                }
            }
            
            // Recent notifications section
            if !notificationService.recentNotifications.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Recent Notifications")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        Spacer()
                        
                        Button("Clear All") {
                            notificationService.clearAllNotifications()
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.errorColor)
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(notificationService.recentNotifications.prefix(10)) { notification in
                                RecentNotificationRow(notification: notification) {
                                    notificationService.markNotificationAsRead(notification)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
        .padding()
    }
}

// MARK: - Helper Views

struct NotificationToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    isOn = newValue
                    onToggle(newValue)
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
        }
        .padding(.vertical, 8)
    }
}

struct RecentNotificationRow: View {
    let notification: NotificationBanner
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(notification.type.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(notification.isRead ? AppColors.tertiaryText : AppColors.primaryText)
                    .lineLimit(1)
                
                Text(notification.message)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(timeAgoString(from: notification.timestamp))
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(AppColors.tertiaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(notification.isRead ? AppColors.cardBackground.opacity(0.5) : AppColors.cardBackground)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        NotificationBannerView(
            banner: NotificationBanner(
                type: .sessionComplete,
                title: "Focus Complete! 🎯",
                message: "You focused for 25 minutes. Time for a well-deserved break!",
                actionText: "Start Break",
                actionIdentifier: "start_break"
            ),
            onDismiss: {},
            onAction: { _ in }
        )
        .padding()
        
        Spacer()
    }
    .background(AppColors.primaryBackground)
}
