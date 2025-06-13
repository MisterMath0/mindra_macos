//
//  TimerModeHeaderView.swift
//  MindraTimer
//
//  🎯 TIMER MODE HEADER COMPONENT
//

import SwiftUI

struct TimerModeHeaderView: View {
    let geometry: GeometryProxy
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        HStack(spacing: max(12, geometry.size.width * 0.015)) {
            ForEach(TimerMode.allCases, id: \.self) { mode in
                TimerModeButton(mode: mode, geometry: geometry)
                    .environmentObject(timerManager)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: timerManager.currentMode)
    }
}

struct TimerModeButton: View {
    let mode: TimerMode
    let geometry: GeometryProxy
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        Button(action: { 
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                timerManager.setMode(mode)
            }
        }) {
            Text(mode.displayName)
                .font(.system(size: max(14, geometry.size.width * 0.016), weight: .medium, design: .rounded))
                .foregroundColor(timerManager.currentMode == mode ? .white : .white.opacity(0.6))
                .padding(.horizontal, max(20, geometry.size.width * 0.025))
                .padding(.vertical, max(10, geometry.size.height * 0.012))
                .background(
                    RoundedRectangle(cornerRadius: max(8, geometry.size.width * 0.01))
                        .fill(timerManager.currentMode == mode ? mode.color : Color.white.opacity(0.08))
                )
                .scaleEffect(timerManager.currentMode == mode ? 1.0 : 0.95)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: timerManager.currentMode)
    }
}
