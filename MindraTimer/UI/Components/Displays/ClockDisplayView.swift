//
//  ClockDisplayView.swift
//  MindraTimer
//
//  🕰️ RESTORED BOLD CLOCK DISPLAY - BACK TO ORIGINAL IMPACT
//  Bold, chunky, beautiful - enhanced but not replaced
//

import SwiftUI

struct ClockDisplayView: View {
    let geometry: GeometryProxy
    @EnvironmentObject var statsManager: StatsManager
    
    var body: some View {
        VStack(spacing: max(28, geometry.size.height * 0.035)) {
            // 🕰️ BOLD TIME DISPLAY - Back to original chunky style
            Text(getCurrentTime())
                .font(.system(
                    size: max(140, min(geometry.size.width * 0.2, 280)), 
                    weight: .black, 
                    design: .rounded
                ))
                .foregroundColor(.white)
                .tracking(max(6, geometry.size.width * 0.007))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.5), value: getCurrentTime())
            
            // 📅 CLEAN DATE
            Text(getCurrentDate())
                .font(.system(
                    size: max(22, geometry.size.width * 0.026), 
                    weight: .medium, 
                    design: .rounded
                ))
                .foregroundColor(.white.opacity(0.8))
                .tracking(max(1, geometry.size.width * 0.0012))
                .animation(.easeInOut(duration: 0.3), value: getCurrentDate())
            
            // ✨ CLEAN STATS (Only if there's meaningful data)
            if statsManager.settings.showGreetings && shouldShowStats() {
                ClockStatsView(geometry: geometry)
                    .environmentObject(statsManager)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: Date())
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private func shouldShowStats() -> Bool {
        // Only show stats if there's meaningful data
        return statsManager.getSessionsToday() > 0 || 
               statsManager.getCurrentStreak() > 0 || 
               statsManager.getTotalHours() > 0
    }
}
