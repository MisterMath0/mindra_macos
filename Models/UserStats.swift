import Foundation

struct UserStats: Codable {
    var totalFocusTime: TimeInterval
    var totalSessions: Int
    var completedSessions: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastSessionDate: Date?
    var achievements: [Achievement]
    var chartData: [ChartDataPoint]
    var settings: StatsSettings
    
    struct ChartDataPoint: Codable {
        let date: Date
        let focusMinutes: Double
        let sessions: Int
    }
    
    struct StatsSettings: Codable {
        var displayPeriod: DisplayPeriod
        var showStreak: Bool
        var showAchievements: Bool
        var showTotalTime: Bool
        var showCompletionRate: Bool
        var showAverageSessionLength: Bool
        var enableNotificationsForAchievements: Bool
        var visualizationType: VisualizationType
        
        enum DisplayPeriod: String, Codable {
            case day
            case week
            case month
            case all
        }
        
        enum VisualizationType: String, Codable {
            case bar
            case line
            case area
        }
        
        static let `default` = StatsSettings(
            displayPeriod: .week,
            showStreak: true,
            showAchievements: true,
            showTotalTime: true,
            showCompletionRate: true,
            showAverageSessionLength: true,
            enableNotificationsForAchievements: true,
            visualizationType: .bar
        )
    }
    
    init(totalFocusTime: TimeInterval = 0,
         totalSessions: Int = 0,
         completedSessions: Int = 0,
         currentStreak: Int = 0,
         longestStreak: Int = 0,
         lastSessionDate: Date? = nil,
         achievements: [Achievement] = [],
         chartData: [ChartDataPoint] = [],
         settings: StatsSettings = .default) {
        self.totalFocusTime = totalFocusTime
        self.totalSessions = totalSessions
        self.completedSessions = completedSessions
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastSessionDate = lastSessionDate
        self.achievements = achievements
        self.chartData = chartData
        self.settings = settings
    }
    
    var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions) * 100
    }
    
    var averageSessionLength: TimeInterval {
        guard completedSessions > 0 else { return 0 }
        return totalFocusTime / Double(completedSessions)
    }
}

struct Achievement: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let type: AchievementType
    let progress: Double
    let target: Double
    let unlocked: Bool
    let unlockedDate: Date?
    
    enum AchievementType: String, Codable {
        case totalFocusTime
        case streak
        case sessionsCompleted
        case perfectWeek
        case perfectMonth
        case earlyBird
        case nightOwl
        case weekendWarrior
    }
    
    init(id: UUID = UUID(),
         title: String,
         description: String,
         icon: String,
         type: AchievementType,
         progress: Double = 0,
         target: Double,
         unlocked: Bool = false,
         unlockedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.type = type
        self.progress = progress
        self.target = target
        self.unlocked = unlocked
        self.unlockedDate = unlockedDate
    }
    
    var progressPercentage: Double {
        return (progress / target) * 100
    }
} 