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
    
    
    private func updateGreetings() {
        currentGreeting = getGreeting()
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
