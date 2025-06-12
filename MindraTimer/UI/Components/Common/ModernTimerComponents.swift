//
//  ModernTimerComponents.swift
//  MindraTimer
//
//  Modern, beautiful components for timer settings
//

import SwiftUI

// MARK: - Modern Duration Picker

struct ModernDurationPicker: View {
    let title: String
    let icon: String
    let value: Int
    let range: ClosedRange<Int>
    let color: Color
    let onValueChanged: (Int) -> Void
    
    @State private var isExpanded = false
    @State private var tempValue: Int
    
    init(
        title: String,
        icon: String,
        value: Int,
        range: ClosedRange<Int> = 1...60,
        color: Color = AppColors.focusColor,
        onValueChanged: @escaping (Int) -> Void
    ) {
        self.title = title
        self.icon = icon
        self.value = value
        self.range = range
        self.color = color
        self.onValueChanged = onValueChanged
        self._tempValue = State(initialValue: value)
    }
    
    var body: some View {
        AppCard(style: .elevated, shadow: .subtle) {
            VStack(spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    // Icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppFonts.calloutSemibold)
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("\(value) minutes")
                            .font(AppFonts.captionMedium)
                            .foregroundColor(color)
                    }
                    
                    Spacer()
                    
                    // Expand/Collapse button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(color)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Expanded controls
                if isExpanded {
                    VStack(spacing: 16) {
                        // Slider
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(range.lowerBound)")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.tertiaryText)
                                
                                Spacer()
                                
                                Text("\(range.upperBound)")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.tertiaryText)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(tempValue) },
                                    set: { tempValue = Int($0) }
                                ),
                                in: Double(range.lowerBound)...Double(range.upperBound),
                                step: 1
                            ) {
                                Text(title)
                            }
                            .tint(color)
                            .onChange(of: tempValue) { _, newValue in
                                onValueChanged(newValue)
                            }
                        }
                        
                        // Quick preset buttons
                        let presets = getPresets(for: title)
                        if !presets.isEmpty {
                            VStack(spacing: 8) {
                                Text("Quick Presets")
                                    .font(AppFonts.captionMedium)
                                    .foregroundColor(AppColors.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                    ForEach(presets, id: \.self) { preset in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                tempValue = preset
                                                onValueChanged(preset)
                                            }
                                        }) {
                                            Text("\(preset)")
                                                .font(AppFonts.captionSemibold)
                                                .foregroundColor(tempValue == preset ? .white : color)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(tempValue == preset ? color : color.opacity(0.1))
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 1.05).combined(with: .opacity)
                    ))
                }
            }
        }
        .onAppear {
            tempValue = value
        }
        .onChange(of: value) { _, newValue in
            tempValue = newValue
        }
    }
    
    private func getPresets(for title: String) -> [Int] {
        switch title.lowercased() {
        case let x where x.contains("focus"):
            return [15, 25, 30, 45]
        case let x where x.contains("short"):
            return [3, 5, 10, 15]
        case let x where x.contains("long"):
            return [10, 15, 20, 30]
        default:
            return [5, 10, 15, 20]
        }
    }
}

// MARK: - Modern Toggle Card

struct ModernToggleCard: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    let description: String?
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = AppColors.focusColor,
        isOn: Binding<Bool>,
        description: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self._isOn = isOn
        self.description = description
    }
    
    var body: some View {
        AppCard(style: .elevated, shadow: .subtle) {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isOn ? [color, color.opacity(0.7)] : [AppColors.cardBackground, AppColors.cardBackground],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(isOn ? Color.clear : AppColors.borderColor, lineWidth: 1)
                            )
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(isOn ? .white : AppColors.secondaryText)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isOn)
                    
                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppFonts.calloutSemibold)
                            .foregroundColor(AppColors.primaryText)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Modern toggle
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isOn.toggle()
                        }
                    }) {
                        ZStack {
                            // Background
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isOn ? color : AppColors.cardBackground)
                                .frame(width: 50, height: 30)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isOn ? Color.clear : AppColors.borderColor, lineWidth: 1)
                                )
                            
                            // Knob
                            Circle()
                                .fill(.white)
                                .frame(width: 26, height: 26)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                .offset(x: isOn ? 10 : -10)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Description
                if let description = description {
                    Text(description)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.tertiaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Modern Volume Slider

struct ModernVolumeSlider: View {
    let title: String
    @Binding var volume: Double
    let color: Color
    let onValueChanged: (Double) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        AppCard(style: .elevated, shadow: .subtle) {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // Volume icon that changes based on level
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: volumeIcon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                    .animation(.easeInOut(duration: 0.2), value: volumeIcon)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppFonts.calloutSemibold)
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("\(Int(volume))%")
                            .font(AppFonts.captionMedium)
                            .foregroundColor(color)
                    }
                    
                    Spacer()
                }
                
                // Custom slider
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Track
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.cardBackground)
                                .frame(height: 8)
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [color, color.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * (volume / 100), height: 8)
                                .animation(.easeInOut(duration: 0.1), value: volume)
                            
                            // Thumb
                            Circle()
                                .fill(.white)
                                .frame(width: isDragging ? 20 : 16, height: isDragging ? 20 : 16)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                .offset(x: geometry.size.width * (volume / 100) - (isDragging ? 10 : 8))
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    let newValue = min(100, max(0, (value.location.x / geometry.size.width) * 100))
                                    volume = newValue
                                    onValueChanged(newValue)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                    }
                    .frame(height: 20)
                    
                    // Volume level indicators
                    HStack {
                        Text("0%")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.tertiaryText)
                        
                        Spacer()
                        
                        Text("100%")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.tertiaryText)
                    }
                }
            }
        }
    }
    
    private var volumeIcon: String {
        switch volume {
        case 0:
            return "speaker.slash.fill"
        case 1...30:
            return "speaker.fill"
        case 31...70:
            return "speaker.wave.1.fill"
        default:
            return "speaker.wave.3.fill"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ModernTimerComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                ModernDurationPicker(
                    title: "Focus Duration",
                    icon: "brain.head.profile",
                    value: 25,
                    color: AppColors.focusColor
                ) { _ in }
                
                ModernToggleCard(
                    title: "Auto-start breaks",
                    subtitle: "Start break timers automatically",
                    icon: "play.circle.fill",
                    isOn: .constant(true),
                    description: "When enabled, break timers will start automatically after focus sessions complete."
                )
                
                ModernVolumeSlider(
                    title: "Sound Volume",
                    volume: .constant(70),
                    color: AppColors.focusColor
                ) { _ in }
            }
            .padding()
        }
        .background(AppColors.primaryBackground)
    }
}
#endif
