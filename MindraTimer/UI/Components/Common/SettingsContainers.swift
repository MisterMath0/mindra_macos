//
//  SettingsContainers.swift
//  MindraTimer
//
//  Settings container components for consistent layouts
//

import SwiftUI

// MARK: - Settings Scroll Container

struct SettingsScrollContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
                .padding(.all, 40)
        }
        .background(AppColors.primaryBackground)
    }
}

// MARK: - Settings Content Section

struct SettingsContentSection<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Header Section
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            // Content
            content
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsContainers_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScrollContainer {
            SettingsContentSection(
                title: "Test Settings",
                subtitle: "This is a test settings section"
            ) {
                VStack(spacing: 16) {
                    Text("Content goes here")
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("More content...")
                        .foregroundColor(AppColors.secondaryText)
                }
            }
        }
    }
}
#endif
