//
//  SectionHeader.swift
//  MindraTimer
//
//  📋 MODERN SECTION HEADER
//  Beautiful section headers with icons and descriptions
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = AppColors.focusColor
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 16) {
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
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.cardTitle)
                    .foregroundColor(AppColors.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppFonts.captionMedium)
                        .foregroundColor(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#if DEBUG
struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SectionHeader(
                title: "Timer Durations",
                subtitle: "Set perfect time blocks for your workflow",
                icon: "clock.badge",
                color: AppColors.focusColor
            )
            
            SectionHeader(
                title: "Quote Categories",
                subtitle: "Choose the types of quotes you'd like to see",
                icon: "tag.fill",
                color: AppColors.infoColor
            )
            
            SectionHeader(
                title: "Pro Tips",
                subtitle: "Maximize your productivity with these insights",
                icon: "lightbulb.fill",
                color: AppColors.warningColor
            )
        }
        .padding()
        .background(AppColors.primaryBackground)
    }
}
#endif
