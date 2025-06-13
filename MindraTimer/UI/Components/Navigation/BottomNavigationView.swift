//
//  BottomNavigationView.swift
//  MindraTimer
//
//  📱 PREMIUM BOTTOM NAVIGATION - CLEAN & SOPHISTICATED
//  Enhanced scaling, refined aesthetics, smooth interactions
//

import SwiftUI

struct BottomNavigationView: View {
    let geometry: GeometryProxy
    @EnvironmentObject var navigationManager: AppNavigationManager
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var timerManager: TimerManager
    
    @State private var showSoundPicker = false
    
    var body: some View {
        HStack {
            // LEFT UTILITIES
            HStack(spacing: max(24, geometry.size.width * 0.03)) {
                PremiumNavButton(
                    icon: "bell", 
                    action: { showSoundPicker = true }, 
                    geometry: geometry,
                    style: .utility
                )
            }
            .frame(width: max(80, geometry.size.width * 0.1), alignment: .leading)
            
            Spacer()
            
            // CENTER NAVIGATION - Main pages
            HStack(spacing: max(40, geometry.size.width * 0.05)) {
                PremiumNavButton(
                    icon: "house.fill",
                    action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            navigationManager.navigateTo(.clock)
                        }
                    },
                    geometry: geometry,
                    isActive: navigationManager.currentPage == .clock,
                    style: .primary
                )
                
                PremiumNavButton(
                    icon: "timer",
                    action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            navigationManager.navigateTo(.focus)
                        }
                    },
                    geometry: geometry,
                    isActive: navigationManager.currentPage == .focus,
                    style: .primary
                )
                
                PremiumNavButton(
                    icon: "gearshape",
                    action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            navigationManager.navigateTo(.settings)
                        }
                    },
                    geometry: geometry,
                    isActive: navigationManager.currentPage == .settings,
                    style: .primary
                )
            }
            .padding(.horizontal, max(24, geometry.size.width * 0.03))
            .padding(.vertical, max(12, geometry.size.height * 0.015))
            .background(
                RoundedRectangle(cornerRadius: max(16, geometry.size.width * 0.02))
                    .fill(.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: max(16, geometry.size.width * 0.02))
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            Spacer()
            
            // RIGHT WINDOW CONTROLS
            HStack(spacing: max(16, geometry.size.width * 0.02)) {
                PremiumNavButton(
                    icon: "rectangle.compress.vertical", 
                    action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            windowManager.toggleCompactMode()
                        }
                    }, 
                    geometry: geometry,
                    style: .utility
                )
                
                PremiumNavButton(
                    icon: windowManager.isAlwaysOnTop ? "pin.fill" : "pin", 
                    action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            windowManager.toggleAlwaysOnTop()
                        }
                    }, 
                    geometry: geometry,
                    isActive: windowManager.isAlwaysOnTop,
                    style: .utility
                )
            }
            .frame(width: max(100, geometry.size.width * 0.12), alignment: .trailing)
        }
        .padding(.horizontal, max(48, geometry.size.width * 0.06))
        .padding(.bottom, max(36, geometry.size.height * 0.045))
        .sheet(isPresented: $showSoundPicker) {
            SoundPickerView()
                .environmentObject(StatsManager())
        }
    }
}

// MARK: - 🎯 PREMIUM NAV BUTTON

struct PremiumNavButton: View {
    let icon: String
    let action: () -> Void
    let geometry: GeometryProxy
    let isActive: Bool
    let style: ButtonStyle
    
    @EnvironmentObject var timerManager: TimerManager
    @State private var isHovered = false
    
    enum ButtonStyle {
        case primary
        case utility
    }
    
    init(
        icon: String, 
        action: @escaping () -> Void, 
        geometry: GeometryProxy, 
        isActive: Bool = false,
        style: ButtonStyle = .primary
    ) {
        self.icon = icon
        self.action = action
        self.geometry = geometry
        self.isActive = isActive
        self.style = style
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(
                    size: max(16, geometry.size.width * 0.02), 
                    weight: .medium
                ))
                .foregroundColor(foregroundColor)
                .frame(
                    width: buttonSize,
                    height: buttonSize
                )
                .background(backgroundView)
                .scaleEffect(isActive || isHovered ? 1.1 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
    }
    
    private var buttonSize: CGFloat {
        switch style {
        case .primary:
            return max(48, geometry.size.width * 0.05)
        case .utility:
            return max(40, geometry.size.width * 0.04)
        }
    }
    
    private var foregroundColor: Color {
        if isActive {
            return style == .primary ? timerManager.currentMode.color : AppColors.focusColor
        } else if isHovered {
            return .white.opacity(0.9)
        } else {
            return .white.opacity(0.6)
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isActive {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            (style == .primary ? timerManager.currentMode.color : AppColors.focusColor).opacity(0.2),
                            (style == .primary ? timerManager.currentMode.color : AppColors.focusColor).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            (style == .primary ? timerManager.currentMode.color : AppColors.focusColor).opacity(0.4), 
                            lineWidth: 1
                        )
                )
        } else if isHovered {
            Circle()
                .fill(.white.opacity(0.08))
        } else {
            Circle()
                .fill(.clear)
        }
    }
}
