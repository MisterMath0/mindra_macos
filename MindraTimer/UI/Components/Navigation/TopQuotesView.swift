//
//  TopQuotesView.swift
//  MindraTimer
//
//  💭 PREMIUM QUOTES - MINIMAL & ELEGANT
//  Clean typography, subtle presence
//

import SwiftUI

struct TopQuotesView: View {
    let geometry: GeometryProxy
    @EnvironmentObject var quotesManager: QuotesManager
    
    var body: some View {
        HStack {
            Spacer()
            
            if !quotesManager.currentQuote.isEmpty {
                Text("\"\(quotesManager.currentQuote)\"")
                    .font(.system(
                        size: max(12, geometry.size.width * 0.013), 
                        weight: .medium, 
                        design: .rounded
                    ))
                    .foregroundColor(.white.opacity(0.4))
                    .italic()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: geometry.size.width * 0.4)
                    .lineLimit(2)
                    .tracking(0.3)
                    .animation(.easeInOut(duration: 0.6), value: quotesManager.currentQuote)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, max(40, geometry.size.width * 0.05))
        .padding(.top, max(20, geometry.size.height * 0.025))
    }
}
