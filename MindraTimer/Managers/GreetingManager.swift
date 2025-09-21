import Foundation
import Combine

class GreetingManager: ObservableObject {
    @Published var currentGreeting: String = ""
    @Published var currentFocusPrompt: String = ""
    
    private var userName: String?
    private var timer: Timer?
    private var lastPeriodKey: String?
    
    // Time-dependent greeting variations with human, engaging feel
    private let morningGreetings = [
        "Good morning",
        "Rise and shine",
        "Ready to conquer today",
        "Fresh start awaits",
        "Let's make magic happen",
        "Time to shine bright"
    ]
    
    private let afternoonGreetings = [
        "Good afternoon",
        "Hope you're crushing it",
        "Making waves today",
        "Afternoon energy boost",
        "Keep the momentum going",
        "You're on fire today"
    ]
    
    private let eveningGreetings = [
        "Good evening",
        "Time to unwind beautifully",
        "You've earned this moment",
        "Embrace the calm",
        "Well done today, truly",
        "Peace and reflection time"
    ]
    
    init(userName: String? = nil) {
        self.userName = userName
        // Initial compute
        updateGreetings(force: true)
        // Start a throttled update schedule
        startMinuteTimer()
        
    }
    
    deinit {
        stopMinuteTimer()
        NotificationCenter.default.removeObserver(self)
    }
    
    func setUserName(_ name: String?) {
        self.userName = name
        updateGreetings(force: true)
    }
    
    // Public API retained for compatibility, but avoid calling this from views.
    // Views should bind to currentGreeting instead.
    func getGreeting() -> String {
        return currentGreeting
    }
    
    // MARK: - Internal update logic
    
    private func startMinuteTimer() {
        stopMinuteTimer()
        
        // Schedule at next minute boundary, then every 60s
        let now = Date()
        let nextMinute = Calendar.current.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTimePreservingSmallerComponents) ?? now.addingTimeInterval(60)
        let initialDelay = nextMinute.timeIntervalSince(now)
        
        // First fire at next minute, then every 60 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) { [weak self] in
            self?.tick()
            self?.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.tick()
            }
            RunLoop.main.add(self!.timer!, forMode: .common)
        }
    }
    
    private func stopMinuteTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func appDidBecomeActive() {
        updateGreetings(force: true)
    }
    
    private func tick() {
        updateGreetings(force: false)
    }
    
    private func updateGreetings(force: Bool = false) {
        let showGreetings = UserDefaults.standard.object(forKey: "showGreetings") as? Bool ?? true
        let showDynamic = UserDefaults.standard.object(forKey: "showDynamicGreetings") as? Bool ?? true
        
        guard showGreetings else {
            if currentGreeting != "" {
                currentGreeting = ""
            }
            return
        }
        
        let periodKey = currentPeriodKey()
        
        // If dynamic greetings are disabled, only change when period changes or when forced
        if !showDynamic {
            if force || lastPeriodKey != periodKey || currentGreeting.isEmpty {
                currentGreeting = buildGreeting(for: periodKey)
                lastPeriodKey = periodKey
            }
            return
        }
        
        // Dynamic greetings enabled: refresh on each minute tick or when forced
        if force || currentGreeting.isEmpty || lastPeriodKey != periodKey {
            // If period changed, pick fresh; otherwise you can still rotate each minute
            currentGreeting = buildGreeting(for: periodKey)
            lastPeriodKey = periodKey
        } else {
            // Rotate within the same period each minute to add variety (optional).
            // Comment out the next line if you prefer to keep the same greeting within a period.
            currentGreeting = buildGreeting(for: periodKey)
        }
    }
    
    private func currentPeriodKey() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
    
    private func buildGreeting(for periodKey: String) -> String {
        let baseGreeting: String
        switch periodKey {
        case "morning":
            baseGreeting = morningGreetings.randomElement() ?? "Good morning"
        case "afternoon":
            baseGreeting = afternoonGreetings.randomElement() ?? "Good afternoon"
        default:
            baseGreeting = eveningGreetings.randomElement() ?? "Good evening"
        }
        
        let name = getUserDisplayName()
        if !name.isEmpty {
            return "\(baseGreeting), \(name)"
        } else {
            return baseGreeting
        }
    }
    
    private func getUserDisplayName() -> String {
        guard let name = userName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            return ""
        }
        return name
    }
    
    // MARK: - Debug Methods
    
    func getDebugInfo() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let showGreetings = UserDefaults.standard.object(forKey: "showGreetings") as? Bool ?? true
        let showDynamic = UserDefaults.standard.object(forKey: "showDynamicGreetings") as? Bool ?? true
        
        return """
        Greeting Manager Debug:
        - Current Hour: \(hour)
        - User Name: \(userName ?? "none")
        - Show Greetings: \(showGreetings)
        - Show Dynamic: \(showDynamic)
        - Last Period: \(lastPeriodKey ?? "none")
        - Current Greeting: "\(currentGreeting)"
        - Current Prompt: "\(currentFocusPrompt)"
        """
    }
}
