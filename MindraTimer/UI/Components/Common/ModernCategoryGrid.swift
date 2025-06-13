//
//  ModernCategoryGrid.swift
//  MindraTimer
//
//  🏷️ MODERN CATEGORY SELECTION GRID
//  Beautiful grid for selecting categories with smooth animations
//

import SwiftUI

struct ModernCategoryGrid<T: Hashable & CaseIterable>: View where T: RawRepresentable, T.RawValue == String {
    let categories: [T]
    @Binding var selectedCategories: [T]
    let columns: Int
    let categoryDisplayName: (T) -> String
    let categoryIcon: (T) -> String
    let categoryColor: (T) -> Color
    
    init(
        categories: [T],
        selectedCategories: Binding<[T]>,
        columns: Int = 2,
        categoryDisplayName: @escaping (T) -> String,
        categoryIcon: @escaping (T) -> String,
        categoryColor: @escaping (T) -> Color = { _ in AppColors.focusColor }
    ) {
        self.categories = categories
        self._selectedCategories = selectedCategories
        self.columns = columns
        self.categoryDisplayName = categoryDisplayName
        self.categoryIcon = categoryIcon
        self.categoryColor = categoryColor
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 12) {
            ForEach(categories, id: \.self) { category in
                CategoryCard(
                    category: category,
                    isSelected: selectedCategories.contains(category),
                    displayName: categoryDisplayName(category),
                    icon: categoryIcon(category),
                    color: categoryColor(category)
                ) {
                    toggleCategory(category)
                }
            }
        }
    }
    
    private func toggleCategory(_ category: T) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedCategories.contains(category) {
                selectedCategories.removeAll { $0 == category }
            } else {
                selectedCategories.append(category)
            }
        }
    }
}

// MARK: - Category Card

private struct CategoryCard<T: Hashable>: View {
    let category: T
    let isSelected: Bool
    let displayName: String
    let icon: String
    let color: Color
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon with animated background
                ZStack {
                    Circle()
                        .fill(
                            isSelected 
                                ? LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [AppColors.tertiaryBackground, AppColors.tertiaryBackground],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 48, height: 48)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : AppColors.tertiaryText)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .shadow(
                    color: isSelected ? color.opacity(0.4) : .clear,
                    radius: isSelected ? 8 : 0,
                    x: 0,
                    y: isSelected ? 4 : 0
                )
                
                // Category name
                Text(displayName)
                    .font(AppFonts.captionMedium)
                    .foregroundColor(isSelected ? AppColors.primaryText : AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? color.opacity(0.5) : AppColors.borderColor,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ModernCategoryGrid_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Quote Categories")
                .font(AppFonts.cardTitle)
                .foregroundColor(AppColors.primaryText)
            
            ModernCategoryGrid(
                categories: Array(QuoteCategory.allCases),
                selectedCategories: .constant([.motivation, .focus]),
                categoryDisplayName: { $0.displayName },
                categoryIcon: { $0.icon },
                categoryColor: { $0.color }
            )
        }
        .padding()
        .background(AppColors.primaryBackground)
    }
}
#endif
