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
    @StateObject private var statsManager = StatsManager()
    @StateObject private var timerManager = TimerManager()
    @StateObject private var appModeManager = AppModeManager()
    @StateObject private var quotesManager = QuotesManager()
    @StateObject private var greetingManager = GreetingManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(windowManager)
                .environmentObject(statsManager)
                .environmentObject(timerManager)
                .environmentObject(appModeManager)
                .environmentObject(quotesManager)
                .environmentObject(greetingManager)
                .frame(
                    minWidth: windowManager.isCompact ? 260 : 800,
                    maxWidth: windowManager.isCompact ? 260 : .infinity,
                    minHeight: windowManager.isCompact ? 140 : 600,
                    maxHeight: windowManager.isCompact ? 140 : .infinity
                )
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
        .windowStyle(.automatic)
        .windowResizability(windowManager.isCompact ? .contentSize : .contentMinSize)
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
        if let window = nsView.window {
            windowManager.setWindow(window)
        }
    }
}
