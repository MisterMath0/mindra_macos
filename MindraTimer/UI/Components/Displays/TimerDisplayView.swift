//
//  TimerDisplayView.swift
//  MindraTimer
//  
//  ⏱️ RESTORED BOLD TIMER DISPLAY - BACK TO ORIGINAL POWER
//  Bold, chunky, impactful design - enhanced but not replaced
//

import SwiftUI

struct TimerDisplayView: View {
    let geometry: GeometryProxy
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        VStack(spacing: max(32, geometry.size.height * 0.04)) {
            // ⏱️ BOLD TIMER RING - Back to original impact
            ZStack {
                // Background ring - more prominent
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: max(8, geometry.size.width * 0.008))
                    .frame(width: max(280, geometry.size.width * 0.32))
                
                // Progress ring - bold and beautiful
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        timerManager.currentMode.color,
                        style: StrokeStyle(
                            lineWidth: max(8, geometry.size.width * 0.008), 
                            lineCap: .round
                        )
                    )
                    .frame(width: max(280, geometry.size.width * 0.32))
                    .rotationEffect(.degrees(-90))
                    .shadow(
                        color: timerManager.currentMode.color.opacity(0.4), 
                        radius: 6, 
                        x: 0, 
                        y: 3
                    )
                    .animation(.easeInOut(duration: 1), value: timerManager.progress)
                
                // BOLD TIME DISPLAY - Back to original chunky style
                Text(timerManager.formattedTime)
                    .font(.system(
                        size: max(96, min(geometry.size.width * 0.14, 160)), 
                        weight: .black, 
                        design: .rounded
                    ))
                    .foregroundColor(.white)
                    .tracking(max(4, geometry.size.width * 0.005))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .animation(.easeInOut(duration: 0.3), value: timerManager.formattedTime)
            }
            
            // 🎮 PREMIUM CONTROLS - Use the fixed FullMode components
            FullModeTimerControls(geometry: geometry)
                .environmentObject(timerManager)
            
            // 📊 SESSION STATS (Only show if meaningful)
            if timerManager.sessionsCompleted > 0 {
                FullModeSessionCounter(geometry: geometry)
                    .environmentObject(timerManager)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}
