//
//  DatabaseManager.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 09.06.25.
//

import Foundation
import SQLite3

// MARK: - Data Models (matching your Next.js structure)

struct FocusSession {
    let id: String
    let startedAt: Date
    let endedAt: Date?
    let duration: Int // in seconds
    let completed: Bool
    let mode: TimerMode
    
    init(id: String = UUID().uuidString, startedAt: Date, endedAt: Date? = nil, duration: Int, completed: Bool, mode: TimerMode) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
        self.completed = completed
        self.mode = mode
    }
}

struct StatsSummary {
    let totalSessions: Int
    let totalFocusTime: Int // in minutes
    let completedSessions: Int
    let completionRate: Double // percentage
    let averageSessionLength: Int // in minutes
    let currentStreak: Int
    let bestStreak: Int
    let totalTasksCompleted: Int
}

struct ChartData {
    let day: String
    let focusMinutes: Int
    let sessions: Int
}

enum StatsPeriod: String, CaseIterable {
    case day = "day"
    case week = "week"
    case month = "month"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .all: return "All Time"
        }
    }
}

// MARK: - Database Manager

class DatabaseManager: ObservableObject {
    private var db: OpaquePointer?
    let dbPath: String  // Made public for debugging
    
    init() {
        // Create database in Documents directory
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        dbPath = "\(documentsPath)/mindra_timer.sqlite"
        
        openDatabase()
        createTables()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Database Operations
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Unable to open database at \(dbPath): \(errorMessage)")
        } else {
            print("✅ Database opened successfully at: \(dbPath)")
            // Enable foreign keys and other pragmas for better data integrity
            sqlite3_exec(db, "PRAGMA foreign_keys = ON;", nil, nil, nil)
            sqlite3_exec(db, "PRAGMA journal_mode = WAL;", nil, nil, nil)
        }
    }
    
    private func closeDatabase() {
        if sqlite3_close(db) != SQLITE_OK {
            print("Unable to close database")
        }
    }
    
    private func createTables() {
        // Focus sessions table (matching your Supabase schema)
        let createSessionsTable = """
            CREATE TABLE IF NOT EXISTS focus_sessions (
                id TEXT PRIMARY KEY,
                started_at TEXT NOT NULL,
                ended_at TEXT,
                duration INTEGER NOT NULL,
                completed INTEGER NOT NULL,
                mode TEXT NOT NULL,
                notes TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            );
        """
        
        // Settings table
        let createSettingsTable = """
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            );
        """

        // Achievements table
        let createAchievementsTable = """
            CREATE TABLE IF NOT EXISTS achievements (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT NOT NULL,
                icon TEXT NOT NULL,
                type TEXT NOT NULL,
                progress REAL NOT NULL,
                target REAL NOT NULL,
                unlocked INTEGER NOT NULL,
                unlocked_date TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            );
        """
        
        // Execute table creation with better error handling
        var errorMessage: UnsafeMutablePointer<CChar>?
        
        if sqlite3_exec(db, createSessionsTable, nil, nil, &errorMessage) != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            print("❌ Error creating sessions table: \(error)")
            sqlite3_free(errorMessage)
        } else {
            print("✅ Sessions table created successfully")
        }
        
        if sqlite3_exec(db, createSettingsTable, nil, nil, &errorMessage) != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            print("❌ Error creating settings table: \(error)")
            sqlite3_free(errorMessage)
        } else {
            print("✅ Settings table created successfully")
        }

        if sqlite3_exec(db, createAchievementsTable, nil, nil, &errorMessage) != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            print("❌ Error creating achievements table: \(error)")
            sqlite3_free(errorMessage)
        } else {
            print("✅ Achievements table created successfully")
        }
        
        // Create indexes for better performance
        let createIndexes = """
            CREATE INDEX IF NOT EXISTS idx_sessions_started_at ON focus_sessions(started_at);
            CREATE INDEX IF NOT EXISTS idx_sessions_mode ON focus_sessions(mode);
            CREATE INDEX IF NOT EXISTS idx_sessions_completed ON focus_sessions(completed);
            CREATE INDEX IF NOT EXISTS idx_achievements_type ON achievements(type);
            CREATE INDEX IF NOT EXISTS idx_achievements_unlocked ON achievements(unlocked);
        """
        
        if sqlite3_exec(db, createIndexes, nil, nil, nil) != SQLITE_OK {
            print("Error creating indexes")
        }
    }
    
    // MARK: - Session Management
    
    func addSession(_ session: FocusSession) -> Bool {
        // Use INSERT OR REPLACE to handle conflicts (UPSERT)
        let insertSQL = """
            INSERT OR REPLACE INTO focus_sessions (id, started_at, ended_at, duration, completed, mode)
            VALUES (?, ?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, session.id, -1, nil)
            sqlite3_bind_text(statement, 2, ISO8601DateFormatter().string(from: session.startedAt), -1, nil)
            
            if let endedAt = session.endedAt {
                sqlite3_bind_text(statement, 3, ISO8601DateFormatter().string(from: endedAt), -1, nil)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            
            sqlite3_bind_int(statement, 4, Int32(session.duration))
            sqlite3_bind_int(statement, 5, session.completed ? 1 : 0)
            sqlite3_bind_text(statement, 6, session.mode.rawValue, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                print("✅ Session saved to database: \(session.id)")
                return true
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("❌ Failed to save session: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to prepare session insert: \(errorMessage)")
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func updateSessionCompletion(sessionId: String, completed: Bool) -> Bool {
        let updateSQL = "UPDATE focus_sessions SET completed = ?, ended_at = ? WHERE id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, completed ? 1 : 0)
            sqlite3_bind_text(statement, 2, ISO8601DateFormatter().string(from: Date()), -1, nil)
            sqlite3_bind_text(statement, 3, sessionId, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    // MARK: - Data Retrieval
    
    func getSessions(for period: StatsPeriod) -> [FocusSession] {
        let dateRange = getDateRange(for: period)
        let dateFormatter = ISO8601DateFormatter()
        
        let querySQL = """
            SELECT id, started_at, ended_at, duration, completed, mode
            FROM focus_sessions
            WHERE started_at >= ?
            ORDER BY started_at DESC
        """
        
        var statement: OpaquePointer?
        var sessions: [FocusSession] = []
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, dateFormatter.string(from: dateRange.start), -1, nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let startedAtString = String(cString: sqlite3_column_text(statement, 1))
                let endedAtPointer = sqlite3_column_text(statement, 2)
                let duration = Int(sqlite3_column_int(statement, 3))
                let completed = sqlite3_column_int(statement, 4) == 1
                let modeString = String(cString: sqlite3_column_text(statement, 5))
                
                if let startedAt = dateFormatter.date(from: startedAtString),
                   let mode = TimerMode(rawValue: modeString) {
                    
                    var endedAt: Date?
                    if let endedAtPointer = endedAtPointer {
                        let endedAtString = String(cString: endedAtPointer)
                        endedAt = dateFormatter.date(from: endedAtString)
                    }
                    
                    let session = FocusSession(
                        id: id,
                        startedAt: startedAt,
                        endedAt: endedAt,
                        duration: duration,
                        completed: completed,
                        mode: mode
                    )
                    sessions.append(session)
                }
            }
        }
        
        sqlite3_finalize(statement)
        return sessions
    }
    
    func calculateSummary(for sessions: [FocusSession]) -> StatsSummary {
        let totalSessions = sessions.count
        let completedSessions = sessions.filter { $0.completed }.count
        let totalFocusTime = sessions
            .filter { $0.mode == .focus }
            .reduce(0) { $0 + $1.duration } / 60 // convert to minutes
        
        let completionRate = totalSessions > 0 ? (Double(completedSessions) / Double(totalSessions)) * 100 : 0.0
        let averageSessionLength = totalSessions > 0 ? sessions.reduce(0) { $0 + $1.duration } / totalSessions / 60 : 0
        
        // Calculate streaks
        let streaks = calculateStreaks(from: sessions)
        
        return StatsSummary(
            totalSessions: totalSessions,
            totalFocusTime: totalFocusTime,
            completedSessions: completedSessions,
            completionRate: completionRate,
            averageSessionLength: averageSessionLength,
            currentStreak: streaks.current,
            bestStreak: streaks.best,
            totalTasksCompleted: 0 // TODO: Implement when adding task management
        )
    }
    
    func generateChartData(for sessions: [FocusSession], period: StatsPeriod) -> [ChartData] {
        let dateRange = getDateRange(for: period)
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        var chartData: [ChartData] = []
        var currentDate = dateRange.start
        
        // Create array of all dates in range
        while currentDate <= dateRange.end {
            let dayString = dateFormatter.string(from: currentDate)
            chartData.append(ChartData(day: dayString, focusMinutes: 0, sessions: 0))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Populate with session data
        for session in sessions {
            let sessionDay = dateFormatter.string(from: session.startedAt)
            
            if let index = chartData.firstIndex(where: { $0.day == sessionDay }) {
                let focusMinutes = session.mode == .focus ? session.duration / 60 : 0
                chartData[index] = ChartData(
                    day: chartData[index].day,
                    focusMinutes: chartData[index].focusMinutes + focusMinutes,
                    sessions: chartData[index].sessions + 1
                )
            }
        }
        
        return chartData
    }
    
    // MARK: - Helper Methods
    
    private func getDateRange(for period: StatsPeriod) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .day:
            let startOfDay = calendar.startOfDay(for: now)
            return (start: startOfDay, end: now)
            
        case .week:
            let startOfWeek = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return (start: startOfWeek, end: now)
            
        case .month:
            let startOfMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return (start: startOfMonth, end: now)
            
        case .all:
            // Start from a reasonable date in the past
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let startDate = formatter.date(from: "2025-01-01") ?? now
            return (start: startDate, end: now)
        }
    }
    
    private func calculateStreaks(from sessions: [FocusSession]) -> (current: Int, best: Int) {
        // Group sessions by date
        let calendar = Calendar.current
        let sessionsByDate = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startedAt)
        }
        
        let activeDates = Array(sessionsByDate.keys).sorted()
        
        guard !activeDates.isEmpty else {
            return (current: 0, best: 0)
        }
        
        var currentStreak = 0
        var bestStreak = 0
        var tempStreak = 1
        
        // Check if user was active today
        let today = calendar.startOfDay(for: Date())
        if activeDates.contains(today) {
            currentStreak = 1
            
            // Count backwards from yesterday
            var checkDate = calendar.date(byAdding: .day, value: -1, to: today)!
            
            while activeDates.contains(checkDate) {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            }
        }
        
        // Calculate best streak
        for i in 1..<activeDates.count {
            let currentDate = activeDates[i]
            let previousDate = activeDates[i-1]
            
            let daysDifference = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
            
            if daysDifference == 1 {
                tempStreak += 1
            } else {
                bestStreak = max(bestStreak, tempStreak)
                tempStreak = 1
            }
        }
        
        bestStreak = max(bestStreak, tempStreak)
        
        return (current: currentStreak, best: bestStreak)
    }
    
    // MARK: - Settings Management
    
    func setSetting<T: Codable>(key: String, value: T) {
        guard let data = try? JSONEncoder().encode(value),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }
        
        let upsertSQL = """
            INSERT OR REPLACE INTO settings (key, value, updated_at)
            VALUES (?, ?, CURRENT_TIMESTAMP)
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, upsertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, key, -1, nil)
            sqlite3_bind_text(statement, 2, jsonString, -1, nil)
            sqlite3_step(statement)
        }
        
        sqlite3_finalize(statement)
    }
    
    func getSetting<T: Codable>(key: String, type: T.Type, defaultValue: T) -> T {
        let querySQL = "SELECT value FROM settings WHERE key = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, key, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let valueString = String(cString: sqlite3_column_text(statement, 0))
                
                if let data = valueString.data(using: .utf8),
                   let value = try? JSONDecoder().decode(type, from: data) {
                    sqlite3_finalize(statement)
                    return value
                }
            }
        }
        
        sqlite3_finalize(statement)
        return defaultValue
    }

    // MARK: - Achievement Management
    
    func addAchievement(_ achievement: Achievement) -> Bool {
        // Use INSERT OR REPLACE to handle conflicts (UPSERT)
        let insertSQL = """
            INSERT OR REPLACE INTO achievements (id, title, description, icon, type, progress, target, unlocked, unlocked_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, achievement.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, achievement.title, -1, nil)
            sqlite3_bind_text(statement, 3, achievement.description, -1, nil)
            sqlite3_bind_text(statement, 4, achievement.icon, -1, nil)
            sqlite3_bind_text(statement, 5, achievement.type.rawValue, -1, nil)
            sqlite3_bind_double(statement, 6, achievement.progress)
            sqlite3_bind_double(statement, 7, achievement.target)
            sqlite3_bind_int(statement, 8, achievement.unlocked ? 1 : 0)
            
            if let unlockedDate = achievement.unlockedDate {
                sqlite3_bind_text(statement, 9, ISO8601DateFormatter().string(from: unlockedDate), -1, nil)
            } else {
                sqlite3_bind_null(statement, 9)
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                print("✅ Achievement saved to database: \(achievement.title)")
                return true
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("❌ Failed to save achievement: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to prepare achievement insert: \(errorMessage)")
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func updateAchievement(_ achievement: Achievement) -> Bool {
        let updateSQL = """
            UPDATE achievements
            SET title = ?, description = ?, icon = ?, type = ?, progress = ?, target = ?, unlocked = ?, unlocked_date = ?
            WHERE id = ?
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, achievement.title, -1, nil)
            sqlite3_bind_text(statement, 2, achievement.description, -1, nil)
            sqlite3_bind_text(statement, 3, achievement.icon, -1, nil)
            sqlite3_bind_text(statement, 4, achievement.type.rawValue, -1, nil)
            sqlite3_bind_double(statement, 5, achievement.progress)
            sqlite3_bind_double(statement, 6, achievement.target)
            sqlite3_bind_int(statement, 7, achievement.unlocked ? 1 : 0)
            
            if let unlockedDate = achievement.unlockedDate {
                sqlite3_bind_text(statement, 8, ISO8601DateFormatter().string(from: unlockedDate), -1, nil)
            } else {
                sqlite3_bind_null(statement, 8)
            }
            
            sqlite3_bind_text(statement, 9, achievement.id.uuidString, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func getAchievements() -> [Achievement] {
        let querySQL = "SELECT id, title, description, icon, type, progress, target, unlocked, unlocked_date FROM achievements"
        var statement: OpaquePointer?
        var achievements: [Achievement] = []
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let idString = String(cString: sqlite3_column_text(statement, 0))
                let title = String(cString: sqlite3_column_text(statement, 1))
                let description = String(cString: sqlite3_column_text(statement, 2))
                let icon = String(cString: sqlite3_column_text(statement, 3))
                let typeString = String(cString: sqlite3_column_text(statement, 4))
                let progress = sqlite3_column_double(statement, 5)
                let target = sqlite3_column_double(statement, 6)
                let unlocked = sqlite3_column_int(statement, 7) == 1
                
                var unlockedDate: Date?
                if let unlockedDatePointer = sqlite3_column_text(statement, 8) {
                    let unlockedDateString = String(cString: unlockedDatePointer)
                    unlockedDate = ISO8601DateFormatter().date(from: unlockedDateString)
                }
                
                if let id = UUID(uuidString: idString),
                   let type = Achievement.AchievementType(rawValue: typeString) {
                    let achievement = Achievement(
                        id: id,
                        title: title,
                        description: description,
                        icon: icon,
                        type: type,
                        progress: progress,
                        target: target,
                        unlocked: unlocked,
                        unlockedDate: unlockedDate
                    )
                    achievements.append(achievement)
                }
            }
        }
        
        sqlite3_finalize(statement)
        return achievements
    }
    
    // MARK: - Debug and Maintenance Methods
    
    func getDebugInfo() -> String {
        let fileManager = FileManager.default
        var dbSize: Int64 = 0
        
        if let attributes = try? fileManager.attributesOfItem(atPath: dbPath) {
            dbSize = attributes[.size] as? Int64 ?? 0
        }
        
        // Test database connectivity
        let isConnected = (db != nil)
        
        // Count records in each table
        var sessionCount = 0
        var achievementCount = 0
        var settingCount = 0
        
        var statement: OpaquePointer?
        
        // Count sessions
        if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM focus_sessions", -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                sessionCount = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)
        
        // Count achievements  
        if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM achievements", -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                achievementCount = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)
        
        // Count settings
        if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM settings", -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                settingCount = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)
        
        return """
        📊 Database Debug Info:
        • Path: \(dbPath)
        • Size: \(ByteCountFormatter.string(fromByteCount: dbSize, countStyle: .file))
        • Connected: \(isConnected ? "✅" : "❌")
        • Sessions: \(sessionCount)
        • Achievements: \(achievementCount) 
        • Settings: \(settingCount)
        """
    }
    
    func clearAllData() {
        var errorMessage: UnsafeMutablePointer<CChar>?
        
        if sqlite3_exec(db, "DELETE FROM focus_sessions;", nil, nil, &errorMessage) != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            print("❌ Failed to clear sessions: \(error)")
            sqlite3_free(errorMessage)
        }
        
        if sqlite3_exec(db, "DELETE FROM achievements;", nil, nil, &errorMessage) != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            print("❌ Failed to clear achievements: \(error)")
            sqlite3_free(errorMessage)
        }
        
        if sqlite3_exec(db, "DELETE FROM settings;", nil, nil, &errorMessage) != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            print("❌ Failed to clear settings: \(error)")
            sqlite3_free(errorMessage)
        }
        
        print("🗑️ Database cleared")
    }
}
