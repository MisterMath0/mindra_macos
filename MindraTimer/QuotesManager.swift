import Foundation
import Combine

class QuotesManager: ObservableObject {
    @Published var currentQuote: String = ""
    
    private var allQuotes: [String: [String]] = [:] // Category -> Quotes mapping
    private var timer: Timer?
    private var quoteInterval: TimeInterval = 30 * 60 // Default: 30 minutes
    private var userName: String? = nil
    private var usePersonalization: Bool = true
    private let quotesKey = "QuotesManager.currentQuoteIndex"
    private let lastUpdateKey = "QuotesManager.lastUpdateTime"
    private let categoryKey = "QuotesManager.currentCategory"
    private var currentIndex: Int = 0
    private var currentCategory: QuoteCategory = .motivation
    
    init() {
        loadQuotes()
        loadState()
        updateQuoteIfNeeded(force: true)
        startTimer()
    }
    
    // MARK: - Public Methods
    
    func setUserName(_ name: String?) {
        self.userName = name
        updateQuoteIfNeeded(force: true)
    }
    
    func setQuoteInterval(minutes: Int) {
        self.quoteInterval = TimeInterval(minutes * 60)
        startTimer()
    }
    
    func setPersonalization(_ enabled: Bool) {
        self.usePersonalization = enabled
        updateQuoteIfNeeded(force: true)
    }
    
    func setCategories(_ categories: [QuoteCategory]) {
        // Update quote display when categories change
        updateQuoteIfNeeded(force: true)
    }
    
    var currentQuoteInterval: Int {
        return Int(quoteInterval / 60)
    }
    
    // MARK: - Private Methods
    
    private func loadQuotes() {
        allQuotes = [
            QuoteCategory.motivation.rawValue: [
                "Your potential is endless.",
                "Great things never come from comfort zones.",
                "Dream big, start small, act now.",
                "You are stronger than you think.",
                "Push yourself, because no one else is going to do it for you.",
                "Believe you can and you're halfway there.",
                "You are capable of amazing things.",
                "Make today count.",
                "You've got this.",
                "Make it happen.",
                "Keep going, {name}!",
                "You're doing great, {name}!",
                "Stay strong, {name}.",
                "You've got this, {name}!",
                "Believe in yourself, {name}.",
                "You're unstoppable, {name}!",
                "Keep pushing, {name}.",
                "You're a champion, {name}!",
                "Keep shining, {name}.",
                "Never doubt yourself, {name}."
            ],
            QuoteCategory.focus.rawValue: [
                "Focus on progress, not perfection.",
                "Success is built one focused session at a time.",
                "Discipline is the bridge between goals and accomplishment.",
                "Don't watch the clock; do what it does. Keep going.",
                "The secret of getting ahead is getting started.",
                "The best way to get things done is to simply begin.",
                "Stay focused and never give up.",
                "Focus is your superpower.",
                "One step at a time.",
                "Turn your dreams into plans.",
                "Stay focused, {name}.",
                "One session at a time, {name}.",
                "Let's make today count, {name}.",
                "You're building your future, {name}.",
                "Every minute matters, {name}."
            ],
            QuoteCategory.productivity.rawValue: [
                "Small steps every day lead to big results.",
                "Don't stop when you're tired. Stop when you're done.",
                "Every accomplishment starts with the decision to try.",
                "It always seems impossible until it's done.",
                "Excellence is not a skill, it's an attitude.",
                "The future depends on what you do today.",
                "Progress, not perfection.",
                "Consistency beats perfection.",
                "Proud of you, {name}!",
                "You're making progress, {name}!",
                "Your hard work pays off, {name}.",
                "You inspire others, {name}."
            ],
            QuoteCategory.wellness.rawValue: [
                "Stay positive, work hard, make it happen.",
                "You don't have to be perfect to be amazing.",
                "Take care of your mind and body.",
                "Balance is key to everything.",
                "Rest when you need to, but don't quit.",
                "Your health is your wealth.",
                "Progress over perfection, always.",
                "Be kind to yourself today.",
                "Small wins add up to big victories.",
                "Take it one breath at a time."
            ],
            QuoteCategory.success.rawValue: [
                "Success is the sum of small efforts repeated daily.",
                "The only impossible journey is the one you never begin.",
                "Success starts with self-discipline.",
                "Champions are made when nobody's watching.",
                "Success is not final, failure is not fatal.",
                "The price of success is hard work and dedication.",
                "Success is walking from failure to failure with enthusiasm.",
                "Your success is determined by your daily habits.",
                "Great results require great preparation.",
                "Success is earned, not given."
            ]
        ]
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: quoteInterval, repeats: true) { [weak self] _ in
            self?.advanceQuote()
        }
    }
    
    private func loadState() {
        let savedIndex = UserDefaults.standard.integer(forKey: quotesKey)
        let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date ?? Date()
        let savedCategory = UserDefaults.standard.string(forKey: categoryKey) ?? QuoteCategory.motivation.rawValue
        
        self.currentIndex = savedIndex
        self.currentCategory = QuoteCategory(rawValue: savedCategory) ?? .motivation
        
        // If interval has passed, advance quote
        if Date().timeIntervalSince(lastUpdate) > quoteInterval {
            advanceQuote()
        }
    }
    
    private func saveState() {
        UserDefaults.standard.set(currentIndex, forKey: quotesKey)
        UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
        UserDefaults.standard.set(currentCategory.rawValue, forKey: categoryKey)
    }
    
    private func advanceQuote() {
        // Get selected categories from settings
        let selectedCategories = getSelectedCategories()
        
        if selectedCategories.isEmpty {
            // Fallback to motivation if no categories selected
            currentCategory = .motivation
        } else {
            // Randomly select from available categories
            currentCategory = selectedCategories.randomElement() ?? .motivation
        }
        
        // Get quotes for current category
        let categoryQuotes = allQuotes[currentCategory.rawValue] ?? allQuotes[QuoteCategory.motivation.rawValue]!
        
        // Advance index within category
        currentIndex = (currentIndex + 1) % categoryQuotes.count
        
        updateQuoteIfNeeded(force: true)
        saveState()
    }
    
    func updateQuoteIfNeeded(force: Bool = false) {
        let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date ?? Date()
        
        if force || Date().timeIntervalSince(lastUpdate) > quoteInterval {
            // Get selected categories
            let selectedCategories = getSelectedCategories()
            
            if selectedCategories.isEmpty {
                currentCategory = .motivation
            } else if force {
                // When forcing update, randomly select category
                currentCategory = selectedCategories.randomElement() ?? .motivation
            }
            
            // Get quotes for current category
            let categoryQuotes = allQuotes[currentCategory.rawValue] ?? allQuotes[QuoteCategory.motivation.rawValue]!
            
            // Ensure index is valid
            if currentIndex >= categoryQuotes.count {
                currentIndex = 0
            }
            
            let quote = categoryQuotes[currentIndex]
            
            // Apply personalization if enabled and user has a name
            if usePersonalization, let name = userName, !name.isEmpty, quote.contains("{name}") {
                currentQuote = quote.replacingOccurrences(of: "{name}", with: name)
            } else {
                // Remove {name} placeholder if personalization is disabled or no name
                currentQuote = quote.replacingOccurrences(of: "{name}", with: "friend")
            }
            
            saveState()
        }
    }
    
    private func getSelectedCategories() -> [QuoteCategory] {
        // Get from SettingsManager through UserDefaults
        let categoryStrings = UserDefaults.standard.stringArray(forKey: "selectedQuoteCategories") ?? ["motivation", "focus", "productivity"]
        return categoryStrings.compactMap { QuoteCategory(rawValue: $0) }
    }
    
    // MARK: - Debug Methods
    
    func getCurrentCategoryInfo() -> String {
        let selectedCategories = getSelectedCategories()
        return """
        Current Category: \(currentCategory.displayName)
        Selected Categories: \(selectedCategories.map { $0.displayName }.joined(separator: ", "))
        Quote Index: \(currentIndex)
        Personalization: \(usePersonalization ? "ON" : "OFF")
        User Name: \(userName ?? "none")
        Interval: \(Int(quoteInterval / 60)) minutes
        """
    }
    
    deinit {
        timer?.invalidate()
    }
}