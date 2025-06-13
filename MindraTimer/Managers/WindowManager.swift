//
//  WindowManager.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 09.06.25.
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
            
            // Make it resizable with proper size constraints
            window.styleMask = [.resizable, .fullSizeContentView]
            window.minSize = NSSize(width: 320, height: 200)
            window.maxSize = NSSize(width: 480, height: 320)
            
            // Hide title bar completely
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            
            // Set initial compact size
            let newSize = NSSize(width: 360, height: 240)
            window.setContentSize(newSize)
            
            // Add rounded corners
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.cornerRadius = 18
            window.contentView?.layer?.masksToBounds = true
            
            // Make window background transparent
            window.isOpaque = false
            window.backgroundColor = .clear
            
        } else {
            // Full mode: Premium sizing with responsive behavior
            window.level = isAlwaysOnTop ? .floating : .normal
            
            // Show native window controls
            window.standardWindowButton(.closeButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = false
            window.standardWindowButton(.zoomButton)?.isHidden = false
            
            // Full window styling
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            
            // PREMIUM SIZING: Responsive to screen size
            let screenSize = getOptimalWindowSize()
            window.minSize = NSSize(width: screenSize.minWidth, height: screenSize.minHeight)
            window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            
            // Show title bar
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = true
            
            // Set premium default size
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
    
    // MARK: - Premium Sizing Logic
    
    private func getOptimalWindowSize() -> (defaultWidth: CGFloat, defaultHeight: CGFloat, minWidth: CGFloat, minHeight: CGFloat) {
        guard let screen = NSScreen.main else {
            // Fallback sizes
            return (defaultWidth: 1400, defaultHeight: 900, minWidth: 1000, minHeight: 650)
        }
        
        let screenSize = screen.visibleFrame.size
        
        // Calculate optimal sizes based on screen dimensions
        let defaultWidth: CGFloat
        let defaultHeight: CGFloat
        let minWidth: CGFloat
        let minHeight: CGFloat
        
        if screenSize.width >= 2560 { // 4K+ displays
            defaultWidth = 1600
            defaultHeight = 1000
            minWidth = 1200
            minHeight = 750
        } else if screenSize.width >= 1920 { // 1080p+ displays
            defaultWidth = 1400
            defaultHeight = 900
            minWidth = 1000
            minHeight = 650
        } else if screenSize.width >= 1440 { // Smaller displays
            defaultWidth = 1200
            defaultHeight = 800
            minWidth = 900
            minHeight = 600
        } else { // Very small displays
            defaultWidth = 1000
            defaultHeight = 700
            minWidth = 800
            minHeight = 550
        }
        
        // Ensure we don't exceed 80% of screen size
        let maxAllowedWidth = screenSize.width * 0.8
        let maxAllowedHeight = screenSize.height * 0.8
        
        return (
            defaultWidth: min(defaultWidth, maxAllowedWidth),
            defaultHeight: min(defaultHeight, maxAllowedHeight),
            minWidth: min(minWidth, maxAllowedWidth * 0.7),
            minHeight: min(minHeight, maxAllowedHeight * 0.7)
        )
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
