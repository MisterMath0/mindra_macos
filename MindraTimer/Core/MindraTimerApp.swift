//
//  MindraTimerApp.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 09.06.25.
//

import SwiftUI
import AppKit

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
    @StateObject private var notificationService = NotificationService()
    
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
                .environmentObject(notificationService)
                .background(WindowAccessor(windowManager: windowManager))
                .onAppear {
                    // Connect timer manager with stats manager
                    timerManager.setStatsManager(statsManager)
                    
                    // Connect timer manager with audio service
                    timerManager.setAudioService(audioService)
                    
                    // Connect notification service with managers
                    notificationService.setStatsManager(statsManager)
                    notificationService.setTimerManager(timerManager)
                    
                    // Connect timer manager with notification service
                    timerManager.setNotificationService(notificationService)
                    
                    // Set up user name synchronization for all services
                    let userName = UserDefaults.standard.string(forKey: "userName")
                    notificationService.setUserName(userName)
                    quotesManager.setUserName(userName)
                    greetingManager.setUserName(userName)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}

// Helper to access the underlying NSWindow
#if os(macOS)
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
#endif
