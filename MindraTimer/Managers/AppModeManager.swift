//
//  AppModeManager.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 09.06.25.
//

import SwiftUI
import Foundation

// AppMode is now defined in TimerModels.swift

class AppModeManager: ObservableObject {
    @Published var currentMode: AppMode {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: "appMode")
        }
    }
    
    init() {
        let savedMode = UserDefaults.standard.string(forKey: "appMode") ?? AppMode.pomodoro.rawValue
        self.currentMode = AppMode(rawValue: savedMode) ?? .pomodoro
    }
    
    func toggleMode() {
        currentMode = currentMode == .clock ? .pomodoro : .clock
    }
    
    func setMode(_ mode: AppMode) {
        currentMode = mode
    }
}
