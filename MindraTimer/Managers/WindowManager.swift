//
//  WindowManager.swift
//  MindraTimer
//
//  🎨 FIXED WINDOW MANAGEMENT - PROPER SCALING RESTORED
//  Better default sizes, proper settings display
//

import SwiftUI
import AppKit

class WindowManager: ObservableObject {
    @Published var isCompact: Bool = false
    @Published var isAlwaysOnTop: Bool = false
    
    private var window: NSWindow?
    
    func setWindow(_ window: NSWindow) {
        self.window = window
        setupWindow()
        
        // Add notification observer for window focus changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: window
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: window
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func windowDidResignKey() {
        guard let window = window else { return }
        // Maintain dark appearance when window loses focus
        window.appearance = NSAppearance(named: .darkAqua)
    }
    
    @objc private func windowDidBecomeKey() {
        guard let window = window else { return }
        // Ensure dark appearance when window gains focus
        window.appearance = NSAppearance(named: .darkAqua)
    }
    
    private func setupWindow() {
        guard let window = window else { return }
        
        // Set window properties
        window.isMovableByWindowBackground = true
        window.title = "Mindra"
        
        // Set window appearance and style
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor.black
        window.isOpaque = false
        
        // Configure title bar
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .visible
        window.styleMask.insert(.fullSizeContentView)
        
        updateWindowMode()
    }
    
    func toggleCompactMode() {
        isCompact.toggle()
        updateWindowMode()
    }
    
    func toggleAlwaysOnTop() {
        isAlwaysOnTop.toggle()
        updateWindowMode()
    }
    
    private func updateWindowMode() {
        guard let window = window else { return }
        
        if isCompact {
            // PiP mode: Always on top, resizable, hide native controls
            window.level = .floating
            
            // Hide native window controls (red/yellow/green buttons)
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            
            // 📱 COMPACT CONSTRAINTS
            window.styleMask = [.resizable, .fullSizeContentView]
            window.minSize = NSSize(width: 320, height: 200)
            window.maxSize = NSSize(width: 600, height: 400)
            
            // Clean PiP appearance
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            
            // OPTIMAL COMPACT SIZE
            let newSize = NSSize(width: 400, height: 250)
            window.setContentSize(newSize)
            
            // ROUNDED CORNERS
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.cornerRadius = 20
            window.contentView?.layer?.masksToBounds = true
            
            // Make window background transparent
            window.isOpaque = false
            window.backgroundColor = .clear
            
        } else {
            // Full mode: Restore to better proportions
            window.level = isAlwaysOnTop ? .floating : .normal
            
            // Show native window controls
            window.standardWindowButton(.closeButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = false
            window.standardWindowButton(.zoomButton)?.isHidden = false
            
            // Full window styling
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            
            // BETTER SIZING - More reasonable for the content
            let screenSize = getOptimalWindowSize()
            window.minSize = NSSize(width: screenSize.minWidth, height: screenSize.minHeight)
            window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            
            // Show title bar
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = true
            
            // Set good default size
            let newSize = NSSize(width: screenSize.defaultWidth, height: screenSize.defaultHeight)
            window.setContentSize(newSize)
            
            // Remove rounded corners for full mode
            window.contentView?.layer?.cornerRadius = 0
            window.contentView?.layer?.masksToBounds = false
            
            // Restore normal background
            window.isOpaque = false
            window.backgroundColor = NSColor.black
        }
        
        // Re-apply appearance settings
        window.appearance = NSAppearance(named: .darkAqua)
        
        // Smart window positioning
        centerWindowOnScreen()
    }
    
    // MARK: - 🎯 BETTER RESPONSIVE SIZING LOGIC
    
    private func getOptimalWindowSize() -> (defaultWidth: CGFloat, defaultHeight: CGFloat, minWidth: CGFloat, minHeight: CGFloat) {
        guard let screen = NSScreen.main else {
            // Conservative fallback
            return (defaultWidth: 1200, defaultHeight: 800, minWidth: 1000, minHeight: 700)
        }
        
        let screenSize = screen.visibleFrame.size
        print("🖥️ Detected screen: \(screenSize.width) x \(screenSize.height)")
        
        // BETTER SIZING - More reasonable proportions
        let defaultWidth: CGFloat
        let defaultHeight: CGFloat
        let minWidth: CGFloat
        let minHeight: CGFloat
        
        if screenSize.width >= 3000 { // 4K+ Ultra-wide displays
            defaultWidth = 1400
            defaultHeight = 900
            minWidth = 1200
            minHeight = 800
        } else if screenSize.width >= 2560 { // 4K displays
            defaultWidth = 1300
            defaultHeight = 850
            minWidth = 1100
            minHeight = 750
        } else if screenSize.width >= 1920 { // 1080p+ displays
            defaultWidth = 1200
            defaultHeight = 800
            minWidth = 1000
            minHeight = 700
        } else if screenSize.width >= 1440 { // MacBook displays
            defaultWidth = 1100
            defaultHeight = 750
            minWidth = 950
            minHeight = 650
        } else { // Smaller displays
            defaultWidth = 1000
            defaultHeight = 700
            minWidth = 900
            minHeight = 600
        }
        
        // Ensure reasonable screen utilization (65% max)
        let maxAllowedWidth = screenSize.width * 0.65
        let maxAllowedHeight = screenSize.height * 0.65
        
        let finalSizing = (
            defaultWidth: min(defaultWidth, maxAllowedWidth),
            defaultHeight: min(defaultHeight, maxAllowedHeight),
            minWidth: min(minWidth, maxAllowedWidth * 0.7),
            minHeight: min(minHeight, maxAllowedHeight * 0.7)
        )
        
        print("🎯 Selected sizing: \(finalSizing.defaultWidth) x \(finalSizing.defaultHeight)")
        return finalSizing
    }
    
    private func centerWindowOnScreen() {
        guard let window = window else { return }
        
        if let screen = window.screen ?? NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            
            // Calculate center position
            let centerX = screenFrame.midX - windowFrame.width / 2
            let centerY = screenFrame.midY - windowFrame.height / 2
            
            // Ensure window stays within screen bounds
            let constrainedX = max(screenFrame.minX, min(centerX, screenFrame.maxX - windowFrame.width))
            let constrainedY = max(screenFrame.minY, min(centerY, screenFrame.maxY - windowFrame.height))
            
            window.setFrameOrigin(NSPoint(x: constrainedX, y: constrainedY))
        }
    }
}
