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
        
        // 🎯 SET OPTIMAL INITIAL SIZE
        setOptimalInitialSize()
        
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
            
            // 📱 OPTIMIZED COMPACT CONSTRAINTS
            window.styleMask = [.resizable, .fullSizeContentView]
            window.minSize = NSSize(width: 320, height: 200)
            window.maxSize = NSSize(width: 600, height: 400)
            
            // Clean PiP appearance
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            
            // 🎯 OPTIMAL COMPACT SIZE - Better proportions
            let compactSize = getOptimalCompactSize()
            window.setContentSize(compactSize)
            print("📱 COMPACT MODE: \(compactSize.width) x \(compactSize.height)")
            
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
            
            // 🎯 Set optimal default size
            let newSize = NSSize(width: screenSize.defaultWidth, height: screenSize.defaultHeight)
            window.setContentSize(newSize)
            print("🖥️ FULL MODE: \(screenSize.defaultWidth) x \(screenSize.defaultHeight)")
            
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
    
    // MARK: - 🎯 OPTIMAL WINDOW SIZING - RESEARCH-BASED IMPLEMENTATION
    
    private func getOptimalWindowSize() -> (defaultWidth: CGFloat, defaultHeight: CGFloat, minWidth: CGFloat, minHeight: CGFloat) {
        guard let screen = NSScreen.main else {
            // Conservative fallback - Use research-recommended standard size
            return (defaultWidth: 1000, defaultHeight: 750, minWidth: 900, minHeight: 650)
        }
        
        let screenSize = screen.visibleFrame.size
        print("🖥️ Detected screen: \(screenSize.width) x \(screenSize.height)")
        
        // 🎯 RESEARCH-BASED OPTIMAL SIZING
        // Based on analysis: Settings content is 1636px tall, needs optimization
        let defaultWidth: CGFloat
        let defaultHeight: CGFloat
        let minWidth: CGFloat
        let minHeight: CGFloat
        
        if screenSize.width >= 2560 && screenSize.height >= 1440 { // 4K+ displays
            // Large: 1400×950px - Spacious for large displays
            defaultWidth = 1400
            defaultHeight = 950
            minWidth = 1200
            minHeight = 850
        } else if screenSize.width >= 1920 && screenSize.height >= 1080 { // 1080p+ displays
            // Comfortable: 1200×850px - Good for larger MacBooks
            defaultWidth = 1200
            defaultHeight = 850
            minWidth = 1000
            minHeight = 750
        } else if screenSize.width >= 1440 && screenSize.height >= 900 { // MacBook Air 13"+ displays
            // 🎯 STANDARD: 1000×750px - OPTIMAL DEFAULT SIZE
            defaultWidth = 1000
            defaultHeight = 750
            minWidth = 900
            minHeight = 650
        } else { // Smaller displays
            // Compact: 900×650px - Minimal viable for all MacBooks
            defaultWidth = 900
            defaultHeight = 650
            minWidth = 800
            minHeight = 600
        }
        
        // Safety check: Ensure window fits on screen (80% max for safety)
        let maxAllowedWidth = screenSize.width * 0.8
        let maxAllowedHeight = screenSize.height * 0.8
        
        let finalSizing = (
            defaultWidth: min(defaultWidth, maxAllowedWidth),
            defaultHeight: min(defaultHeight, maxAllowedHeight),
            minWidth: min(minWidth, maxAllowedWidth * 0.7),
            minHeight: min(minHeight, maxAllowedHeight * 0.7)
        )
        
        print("🎯 OPTIMAL SIZING APPLIED: \(finalSizing.defaultWidth) x \(finalSizing.defaultHeight)")
        print("📱 Minimum size: \(finalSizing.minWidth) x \(finalSizing.minHeight)")
        return finalSizing
    }
    
    private func getOptimalCompactSize() -> NSSize {
        guard let screen = NSScreen.main else {
            return NSSize(width: 400, height: 250)
        }
        
        let screenSize = screen.visibleFrame.size
        
        // 📱 COMPACT SIZE OPTIMIZATION
        // Scale based on screen size but keep reasonable proportions
        let compactWidth: CGFloat
        let compactHeight: CGFloat
        
        if screenSize.width >= 2560 { // Large displays
            compactWidth = 480
            compactHeight = 300
        } else if screenSize.width >= 1920 { // 1080p displays
            compactWidth = 450
            compactHeight = 280
        } else if screenSize.width >= 1440 { // MacBook displays
            compactWidth = 400
            compactHeight = 250
        } else { // Smaller displays
            compactWidth = 360
            compactHeight = 220
        }
        
        return NSSize(width: compactWidth, height: compactHeight)
    }
    
    // MARK: - 🎯 OPTIMAL INITIAL SIZING
    
    private func setOptimalInitialSize() {
        guard let window = window else { return }
        
        let sizing = getOptimalWindowSize()
        
        // Set initial size to optimal default
        let initialSize = NSSize(width: sizing.defaultWidth, height: sizing.defaultHeight)
        window.setContentSize(initialSize)
        
        // Set size constraints
        window.minSize = NSSize(width: sizing.minWidth, height: sizing.minHeight)
        
        // Center the window after sizing
        centerWindowOnScreen()
        
        print("✨ INITIAL WINDOW SIZE SET: \(sizing.defaultWidth) x \(sizing.defaultHeight)")
        print("🔒 Minimum size constraint: \(sizing.minWidth) x \(sizing.minHeight)")
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
