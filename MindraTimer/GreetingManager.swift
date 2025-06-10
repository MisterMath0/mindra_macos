import Foundation

class GreetingManager: ObservableObject {
    @Published var currentGreeting: String = ""
    @Published var currentFocusPrompt: String = ""
    
    private var userName: String?
    
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
    
    // Focus prompts for pomodoro mode
    private let focusPrompts = [
        "What do you want to focus on?",
        "What's your priority today?",
        "What task needs your attention?",
        "Ready to make progress on something?",
        "What will you accomplish today?",
        "What's the most important thing right now?",
        "Time to dive deep into what matters",
        "What deserves your full attention?",
        "Which goal are you working toward?",
        "What would make today feel successful?"
    ]
    
    init(userName: String? = nil) {
        self.userName = userName
        updateGreetings()
    }
    
    func setUserName(_ name: String?) {
        self.userName = name
        updateGreetings()
    }
    
    func getGreeting() -> String {
        // Check if greetings are enabled in settings
        let showGreetings = UserDefaults.standard.object(forKey: "showGreetings") as? Bool ?? true
        
        if !showGreetings {
            return ""
        }
        
        let hour = Calendar.current.component(.hour, from: Date())
        let name = getUserDisplayName()
        
        var baseGreeting: String
        
        // Get time-appropriate greeting
        switch hour {
        case 0..<12:
            baseGreeting = morningGreetings.randomElement() ?? "Good morning"
        case 12..<17:
            baseGreeting = afternoonGreetings.randomElement() ?? "Good afternoon"
        default:
            baseGreeting = eveningGreetings.randomElement() ?? "Good evening"
        }
        
        // Add personalization if name is available
        if !name.isEmpty {
            return "\(baseGreeting), \(name)"
        } else {
            return baseGreeting
        }
    }
    
    func getFocusPrompt() -> String {
        let name = getUserDisplayName()
        let basePrompt = focusPrompts.randomElement() ?? "What do you want to focus on?"
        
        // Occasionally personalize the prompt if user has a name
        if !name.isEmpty && Bool.random() {
            return "\(name), \(basePrompt.lowercased())"
        }
        
        return basePrompt
    }
    
    private func updateGreetings() {
        currentGreeting = getGreeting()
        currentFocusPrompt = getFocusPrompt()
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
        
        return """
        Greeting Manager Debug:
        - Current Hour: \(hour)
        - User Name: \(userName ?? "none")
        - Show Greetings: \(showGreetings)
        - Current Greeting: "\(currentGreeting)"
        - Current Prompt: "\(currentFocusPrompt)"
        """
    }
}