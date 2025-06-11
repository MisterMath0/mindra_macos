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
                "The only way to do great work is to love what you do.",
                "Your time is limited, don't waste it living someone else's life.",
                "The future belongs to those who believe in the beauty of their dreams.",
                "Success is not final, failure is not fatal: it is the courage to continue that counts.",
                "The greatest glory in living lies not in never falling, but in rising every time we fall.",
                "Life is what happens when you're busy making other plans.",
                "The only person you are destined to become is the person you decide to be.",
                "Your life does not get better by chance, it gets better by change.",
                "The mind is everything. What you think you become.",
                "The best way to predict the future is to create it.",
                "Keep going, {name}. Your journey is unique and beautiful.",
                "Your potential is limitless, {name}. Believe in yourself.",
                "Every step forward is a victory, {name}. Keep moving.",
                "Your strength inspires others, {name}. Keep shining.",
                "The world needs your light, {name}. Keep glowing."
            ],
            QuoteCategory.focus.rawValue: [
                "Where focus goes, energy flows.",
                "The main thing is to keep the main thing the main thing.",
                "Concentration is the secret of strength.",
                "The successful warrior is the average man, with laser-like focus.",
                "Focus on being productive instead of busy.",
                "The key is not to prioritize what's on your schedule, but to schedule your priorities.",
                "Stay focused, go after your dreams and keep moving toward your goals.",
                "The difference between successful people and very successful people is that very successful people say 'no' to almost everything.",
                "Focus on the journey, not the destination.",
                "The art of being wise is the art of knowing what to overlook.",
                "Stay present, {name}. The power is in the now.",
                "Your focus determines your reality, {name}.",
                "One task at a time, {name}. That's how mountains are moved.",
                "Your attention is your most valuable asset, {name}.",
                "In the zone, {name}. That's where magic happens."
            ],
            QuoteCategory.productivity.rawValue: [
                "The way to get started is to quit talking and begin doing.",
                "Productivity is never an accident. It is always the result of a commitment to excellence, intelligent planning, and focused effort.",
                "The key is not to prioritize what's on your schedule, but to schedule your priorities.",
                "Don't count the days, make the days count.",
                "The only way to do great work is to love what you do.",
                "Success is the sum of small efforts, repeated day in and day out.",
                "The future depends on what you do today.",
                "The best time to plant a tree was 20 years ago. The second best time is now.",
                "Your work is going to fill a large part of your life, and the only way to be truly satisfied is to do what you believe is great work.",
                "The only limit to the height of your achievements is the reach of your dreams and your willingness to work for them.",
                "Your dedication inspires, {name}. Keep creating.",
                "Every task completed is a step toward your dreams, {name}.",
                "Your work ethic is your superpower, {name}.",
                "Small steps, big impact, {name}. Keep going.",
                "Your progress is remarkable, {name}. Stay the course."
            ],
            QuoteCategory.wellness.rawValue: [
                "The greatest wealth is health.",
                "Take care of your body. It's the only place you have to live.",
                "Health is a state of complete harmony of the body, mind and spirit.",
                "The first wealth is health.",
                "Your body hears everything your mind says.",
                "The mind and body are not separate. What affects one, affects the other.",
                "Wellness is the complete integration of body, mind, and spirit.",
                "Health is not just about what you're eating. It's also about what you're thinking and saying.",
                "The greatest healing therapy is friendship and love.",
                "The part can never be well unless the whole is well.",
                "Your well-being is your superpower, {name}.",
                "Take a moment to breathe, {name}. You deserve it.",
                "Your health is your wealth, {name}. Nurture it.",
                "Balance is key, {name}. Find your center.",
                "Your peace is your power, {name}. Protect it."
            ],
            QuoteCategory.success.rawValue: [
                "Success is not the key to happiness. Happiness is the key to success.",
                "Success is walking from failure to failure with no loss of enthusiasm.",
                "Success is not final, failure is not fatal: it is the courage to continue that counts.",
                "The road to success and the road to failure are almost exactly the same.",
                "Success is not in what you have, but who you are.",
                "Success is the sum of small efforts, repeated day in and day out.",
                "The only place where success comes before work is in the dictionary.",
                "Success is not about the destination, it's about the journey.",
                "The secret of success is to do the common things uncommonly well.",
                "Success is not measured by what you accomplish, but by the opposition you have encountered, and the courage with which you have maintained the struggle against overwhelming odds.",
                "Your success story is being written, {name}. Keep the pen moving.",
                "Success is your birthright, {name}. Claim it.",
                "Your potential is unlimited, {name}. Keep reaching.",
                "Every day is a new opportunity for success, {name}.",
                "Your determination is your destiny, {name}. Stay strong."
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