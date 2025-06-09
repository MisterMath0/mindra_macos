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
    }
    
    private func setupWindow() {
        guard let window = window else { return }
        
        // Show native window controls (red, yellow, green buttons)
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false
        
        // Set window properties
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.title = "MindraTimer"
        
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
        
        // Set window level
        window.level = isAlwaysOnTop ? .floating : .normal
        
        // Update window size with smooth animation
        let newSize = NSSize(
            width: isCompact ? 260 : 1000,
            height: isCompact ? 140 : 700
        )
        
        // Set minimum and maximum sizes
        if isCompact {
            window.minSize = NSSize(width: 260, height: 140)
            window.maxSize = NSSize(width: 260, height: 140)
        } else {
            window.minSize = NSSize(width: 800, height: 600)
            window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
        
        window.setContentSize(newSize)
        
        // Center window when switching modes
        if let screen = window.screen {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            let centerX = screenFrame.midX - windowFrame.width / 2
            let centerY = screenFrame.midY - windowFrame.height / 2
            window.setFrameOrigin(NSPoint(x: centerX, y: centerY))
        }
        
        // Update window style for compact mode
        if isCompact {
            window.styleMask.remove(.resizable)
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
        } else {
            window.styleMask.insert(.resizable)
            window.titlebarAppearsTransparent = false
            window.titleVisibility = .visible
        }
    }
}
