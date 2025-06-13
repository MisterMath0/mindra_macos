//
//  MindraTimerApp.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 09.06.25.
//

import SwiftUI

@main
struct MindraTimerApp: App {
    @StateObject private var windowManager = WindowManager()
    @StateObject private var navigationManager = AppNavigationManager()
    @StateObject private var statsManager = StatsManager()
    @StateObject private var timerManager = TimerManager()
    @StateObject private var appModeManager = AppModeManager()
    @StateObject private var quotesManager = QuotesManager()
    @StateObject private var greetingManager = GreetingManager()
    @StateObject private var audioService = AudioService()
    
    init() {
        // Set appearance when the app is ready
        DispatchQueue.main.async {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(windowManager)
                .environmentObject(navigationManager)
                .environmentObject(statsManager)
                .environmentObject(timerManager)
                .environmentObject(appModeManager)
                .environmentObject(quotesManager)
                .environmentObject(greetingManager)
                .environmentObject(audioService)
                .background(WindowAccessor(windowManager: windowManager))
                .onAppear {
                    // Connect timer manager with stats manager
                    timerManager.setStatsManager(statsManager)
                    
                    // Connect timer manager with audio service
                    timerManager.setAudioService(audioService)
                    
                    // Set up user name synchronization
                    let userName = UserDefaults.standard.string(forKey: "userName")
                    quotesManager.setUserName(userName)
                    greetingManager.setUserName(userName)
                    
                    // One-time database fix (for development)
                    #if DEBUG
                    runDatabaseFixIfNeeded()
                    #endif
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize) // Always allow resizing
    }
    
    private func runDatabaseFixIfNeeded() {
        // Check if we need to run the database fix
        let fixKey = "database_fix_applied_v1"
        if !UserDefaults.standard.bool(forKey: fixKey) {
            print("🚀 Running one-time database fix...")
            
            // Run the fix
            DatabaseManager.shared.fixDatabaseIssuesNow()
            
            // Mark as complete
            UserDefaults.standard.set(true, forKey: fixKey)
            
            // Initialize default achievements if needed
            if statsManager.achievements.isEmpty {
                statsManager.initializeDefaultAchievements()
            }
            
            print("✅ Database fix complete!")
        }
    }
}

// Helper to access the underlying NSWindow
struct WindowAccessor: NSViewRepresentable {
    let windowManager: WindowManager
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                windowManager.setWindow(window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                windowManager.setWindow(window)
            }
        }
    }
}
