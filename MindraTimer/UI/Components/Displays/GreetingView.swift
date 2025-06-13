//
//  GreetingView.swift
//  MindraTimer
//
//  👋 PREMIUM GREETING - ELEGANT & PERSONALIZED
//  Clean typography, subtle animations
//

import SwiftUI

struct GreetingView: View {
    let geometry: GeometryProxy
    @EnvironmentObject var greetingManager: GreetingManager
    
    var body: some View {
        VStack(spacing: max(8, geometry.size.height * 0.01)) {
            let greeting = greetingManager.getGreeting()
            if !greeting.isEmpty {
                Text(greeting)
                    .font(.system(
                        size: max(20, geometry.size.width * 0.024), 
                        weight: .medium, 
                        design: .rounded
                    ))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.9), .white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .multilineTextAlignment(.center)
                    .tracking(max(0.5, geometry.size.width * 0.0006))
                    .animation(.easeInOut(duration: 0.6), value: greeting)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}
