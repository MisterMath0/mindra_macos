//
//  AppNavigationManager.swift
//  MindraTimer
//
//  🧭 PREMIUM NAVIGATION SYSTEM
//  Full-page navigation instead of dialogs - the future of macOS apps
//

import SwiftUI

// MARK: - Navigation Pages

enum AppPage: CaseIterable {
    case clock
    case focus
    case settings
    
    var title: String {
        switch self {
        case .clock: return "Clock"
        case .focus: return "Focus"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .clock: return "house.fill"
        case .focus: return "timer"
        case .settings: return "gearshape"
        }
    }
    
    var description: String {
        switch self {
        case .clock: return "Beautiful world clock with personalized greetings"
        case .focus: return "Pomodoro timer with focus sessions and breaks"
        case .settings: return "Customize your experience and preferences"
        }
    }
}

// MARK: - Navigation Manager

class AppNavigationManager: ObservableObject {
    @Published var currentPage: AppPage = .clock
    @Published var previousPage: AppPage? = nil
    @Published var navigationHistory: [AppPage] = [.clock]
    
    // Navigation animations
    @Published var isTransitioning: Bool = false
    @Published var transitionDirection: TransitionDirection = .forward
    
    enum TransitionDirection {
        case forward
        case backward
        case none
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to a specific page with animation
    func navigateTo(_ page: AppPage, animated: Bool = true) {
        guard page != currentPage else { return }
        
        // Determine transition direction
        let currentIndex = AppPage.allCases.firstIndex(of: currentPage) ?? 0
        let targetIndex = AppPage.allCases.firstIndex(of: page) ?? 0
        transitionDirection = targetIndex > currentIndex ? .forward : .backward
        
        // Update navigation state
        if animated {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                updateNavigation(to: page)
            }
        } else {
            updateNavigation(to: page)
        }
    }
    
    /// Go back to the previous page
    func goBack() {
        guard let previous = previousPage else { return }
        navigateTo(previous)
    }
    
    /// Go to the next logical page
    func goForward() {
        let currentIndex = AppPage.allCases.firstIndex(of: currentPage) ?? 0
        let nextIndex = (currentIndex + 1) % AppPage.allCases.count
        let nextPage = AppPage.allCases[nextIndex]
        navigateTo(nextPage)
    }
    
    /// Check if we can go back
    var canGoBack: Bool {
        return previousPage != nil
    }
    
    /// Check if we can go forward
    var canGoForward: Bool {
        let currentIndex = AppPage.allCases.firstIndex(of: currentPage) ?? 0
        return currentIndex < AppPage.allCases.count - 1
    }
    
    // MARK: - Private Methods
    
    private func updateNavigation(to page: AppPage) {
        isTransitioning = true
        
        // Update history
        if currentPage != page {
            previousPage = currentPage
            addToHistory(page)
        }
        
        // Update current page
        currentPage = page
        
        // Reset transition state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.isTransitioning = false
        }
        
        // Analytics/Logging
        print("🧭 Navigated to: \(page.title)")
    }
    
    private func addToHistory(_ page: AppPage) {
        // Add to history, keeping last 10 entries
        navigationHistory.append(page)
        if navigationHistory.count > 10 {
            navigationHistory.removeFirst()
        }
    }
    
    // MARK: - Page Validation
    
    /// Check if the current page requires specific conditions
    func validateCurrentPage() -> Bool {
        switch currentPage {
        case .clock:
            return true // Clock is always available
        case .focus:
            return true // Focus is always available
        case .settings:
            return true // Settings is always available
        }
    }
    
    // MARK: - Keyboard Navigation Support
    
    func handleKeyboardNavigation(_ key: String) {
        switch key {
        case "1", "h":
            navigateTo(.clock)
        case "2", "f":
            navigateTo(.focus)
        case "3", "s":
            navigateTo(.settings)
        case "ArrowLeft", "j":
            if canGoBack { goBack() }
        case "ArrowRight", "k":
            if canGoForward { goForward() }
        default:
            break
        }
    }
    
    // MARK: - State Persistence
    
    /// Save current navigation state
    func saveNavigationState() {
        UserDefaults.standard.set(currentPage.title, forKey: "LastNavigationPage")
    }
    
    /// Restore navigation state from UserDefaults
    func restoreNavigationState() {
        if let savedPage = UserDefaults.standard.string(forKey: "LastNavigationPage"),
           let page = AppPage.allCases.first(where: { $0.title == savedPage }) {
            navigateTo(page, animated: false)
        }
    }
    
    // MARK: - Debug Helpers
    
    func debugNavigationState() {
        print("🧭 Navigation Debug:")
        print("   Current: \(currentPage.title)")
        print("   Previous: \(previousPage?.title ?? "None")")
        print("   History: \(navigationHistory.map { $0.title }.joined(separator: " → "))")
        print("   Can go back: \(canGoBack)")
        print("   Can go forward: \(canGoForward)")
    }
}

// MARK: - Navigation Transition Views

/// Custom transition for page navigation
struct NavigationTransition: ViewModifier {
    let direction: AppNavigationManager.TransitionDirection
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .transition(.asymmetric(
                insertion: insertionTransition,
                removal: removalTransition
            ))
    }
    
    private var insertionTransition: AnyTransition {
        switch direction {
        case .forward:
            return AnyTransition.move(edge: .trailing)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.95))
        case .backward:
            return AnyTransition.move(edge: .leading)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.95))
        case .none:
            return AnyTransition.opacity
                .combined(with: .scale(scale: 0.98))
        }
    }
    
    private var removalTransition: AnyTransition {
        switch direction {
        case .forward:
            return AnyTransition.move(edge: .leading)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 1.05))
        case .backward:
            return AnyTransition.move(edge: .trailing)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 1.05))
        case .none:
            return AnyTransition.opacity
                .combined(with: .scale(scale: 1.02))
        }
    }
}

extension View {
    func navigationTransition(
        direction: AppNavigationManager.TransitionDirection,
        isActive: Bool = true
    ) -> some View {
        modifier(NavigationTransition(direction: direction, isActive: isActive))
    }
}

// MARK: - Navigation Bar Component

struct PremiumNavigationBar: View {
    @ObservedObject var navigationManager: AppNavigationManager
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: max(32, geometry.size.width * 0.04)) {
            ForEach(AppPage.allCases, id: \.self) { page in
                navigationButton(for: page)
            }
        }
        .padding(.horizontal, max(40, geometry.size.width * 0.05))
        .padding(.vertical, max(16, geometry.size.height * 0.02))
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground.opacity(0.8))
                .backdrop(radius: 10, opaque: true)
        )
    }
    
    private func navigationButton(for page: AppPage) -> some View {
        Button(action: {
            navigationManager.navigateTo(page)
        }) {
            HStack(spacing: 8) {
                Image(systemName: page.icon)
                    .font(.system(size: max(16, geometry.size.width * 0.018), weight: .medium))
                
                Text(page.title)
                    .font(.system(size: max(14, geometry.size.width * 0.016), weight: .medium, design: .rounded))
            }
            .foregroundColor(navigationManager.currentPage == page ? .white : AppColors.secondaryText)
            .padding(.horizontal, max(16, geometry.size.width * 0.02))
            .padding(.vertical, max(12, geometry.size.height * 0.015))
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(navigationManager.currentPage == page ? AppColors.focusColor : Color.clear)
            )
            .scaleEffect(navigationManager.currentPage == page ? 1.0 : 0.95)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: navigationManager.currentPage)
    }
}

// MARK: - Backdrop Effect Extension

extension View {
    func backdrop(radius: CGFloat, opaque: Bool = false) -> some View {
        self
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(opaque ? 1 : 0.8)
            )
    }
}
