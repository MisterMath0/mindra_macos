//
//  ModernInputField.swift
//  MindraTimer
//
//  Modern, beautiful input field component
//

import SwiftUI

struct ModernInputField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let isSecure: Bool
    let helpText: String?
    let errorText: String?
    let maxLength: Int?
    
    @State private var isEditing = false
    @State private var isFocused = false
    
    init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        isSecure: Bool = false,
        helpText: String? = nil,
        errorText: String? = nil,
        maxLength: Int? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self.helpText = helpText
        self.errorText = errorText
        self.maxLength = maxLength
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(label)
                .font(AppFonts.inputLabel)
                .foregroundColor(labelColor)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            // Input container
            HStack(spacing: 12) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 20)
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                }
                
                // Text field
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .onChange(of: text) { _, newValue in
                                if let maxLength = maxLength {
                                    text = String(newValue.prefix(maxLength))
                                }
                            }
                    }
                }
                .font(AppFonts.inputText)
                .foregroundColor(AppColors.primaryText)
                .textFieldStyle(PlainTextFieldStyle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = true
                    }
                }
                .onSubmit {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = false
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.inputBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
            
            // Help/Error text
            if let errorText = errorText {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.errorColor)
                    
                    Text(errorText)
                        .font(AppFonts.inputHelper)
                        .foregroundColor(AppColors.errorColor)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if let helpText = helpText {
                Text(helpText)
                    .font(AppFonts.inputHelper)
                    .foregroundColor(AppColors.tertiaryText)
                    .transition(.opacity)
            }
            
            // Character count (if maxLength is set)
            if let maxLength = maxLength {
                HStack {
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(AppFonts.caption2)
                        .foregroundColor(text.count > maxLength * 9 / 10 ? AppColors.warningColor : AppColors.tertiaryText)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorText != nil)
    }
    
    private var labelColor: Color {
        if errorText != nil {
            return AppColors.errorColor
        } else if isFocused {
            return AppColors.focusColor
        } else {
            return AppColors.secondaryText
        }
    }
    
    private var iconColor: Color {
        if errorText != nil {
            return AppColors.errorColor
        } else if isFocused {
            return AppColors.focusColor
        } else {
            return AppColors.tertiaryText
        }
    }
    
    private var borderColor: Color {
        if errorText != nil {
            return AppColors.errorColor
        } else if isFocused {
            return AppColors.focusColor
        } else {
            return AppColors.borderColor
        }
    }
    
    private var borderWidth: CGFloat {
        if errorText != nil {
            return 2
        } else if isFocused {
            return 2
        } else {
            return 1
        }
    }
}

// MARK: - Profile Display Component

struct ProfileDisplayCard: View {
    let name: String
    let subtitle: String?
    let onEdit: () -> Void
    
    var body: some View {
        AppCard(style: .elevated, shadow: .subtle) {
            HStack(spacing: 16) {
                // Avatar circle with initials
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.focusColor, AppColors.focusColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Text(getInitials(from: name))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .shadow(color: AppColors.focusColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Name and details
                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "Add your name" : name)
                        .font(name.isEmpty ? AppFonts.calloutMedium : AppFonts.cardTitle)
                        .foregroundColor(name.isEmpty ? AppColors.tertiaryText : AppColors.primaryText)
                    
                    if let subtitle = subtitle, !name.isEmpty {
                        Text(subtitle)
                            .font(AppFonts.captionMedium)
                            .foregroundColor(AppColors.secondaryText)
                    } else if !name.isEmpty {
                        Text("Focus Master")
                            .font(AppFonts.captionMedium)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Edit button
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.focusColor)
                        .background(
                            Circle()
                                .fill(AppColors.cardBackground)
                                .frame(width: 32, height: 32)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: name.isEmpty)
            }
        }
    }
    
    private func getInitials(from name: String) -> String {
        let words = name.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces)
        if words.count >= 2 {
            let firstInitial = String(words[0].prefix(1)).uppercased()
            let lastInitial = String(words[1].prefix(1)).uppercased()
            return firstInitial + lastInitial
        } else if let firstWord = words.first, !firstWord.isEmpty {
            return String(firstWord.prefix(2)).uppercased()
        } else {
            return "?"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ModernInputField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            ProfileDisplayCard(
                name: "John Doe",
                subtitle: nil
            ) { }
            
            ModernInputField(
                label: "Your Name",
                placeholder: "Enter your name",
                text: .constant("John"),
                icon: "person.fill",
                helpText: "Used for personalized greetings and quotes",
                maxLength: 50
            )
            
            ModernInputField(
                label: "Email Address",
                placeholder: "your@email.com",
                text: .constant(""),
                icon: "envelope.fill",
                errorText: "Please enter a valid email address"
            )
        }
        .padding()
        .background(AppColors.primaryBackground)
    }
}
#endif
