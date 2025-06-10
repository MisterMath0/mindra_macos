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
        window.title = "MindraTimer"
        
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
            window.styleMask = [.titled, .resizable, .fullSizeContentView]
            window.minSize = NSSize(width: 240, height: 140)
            window.maxSize = NSSize(width: 400, height: 300)
            
            // Hide title bar completely
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            
            // Set initial size
            let newSize = NSSize(width: 280, height: 160)
            window.setContentSize(newSize)
            
        } else {
            // Full mode: Normal window behavior
            window.level = isAlwaysOnTop ? .floating : .normal
            
            // Show native window controls
            window.standardWindowButton(.closeButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = false
            window.standardWindowButton(.zoomButton)?.isHidden = false
            
            // Full window styling
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window.minSize = NSSize(width: 800, height: 600)
            window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            
            // Show title bar
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = true
            
            // Set full size
            let newSize = NSSize(width: 1000, height: 700)
            window.setContentSize(newSize)
        }
        
        // Re-apply appearance settings
        window.appearance = NSAppearance(named: .darkAqua)
        
        // Center window when switching modes
        if let screen = window.screen {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            let centerX = screenFrame.midX - windowFrame.width / 2
            let centerY = screenFrame.midY - windowFrame.height / 2
            window.setFrameOrigin(NSPoint(x: centerX, y: centerY))
        }
    }
}
