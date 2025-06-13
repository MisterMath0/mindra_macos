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
                .background(WindowAccessor(windowManager: windowManager))
                .onAppear {
                    // Connect timer manager with stats manager
                    timerManager.setStatsManager(statsManager)
                    
                    // Set up user name synchronization
                    let userName = UserDefaults.standard.string(forKey: "userName")
                    quotesManager.setUserName(userName)
                    greetingManager.setUserName(userName)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize) // Always allow resizing
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
