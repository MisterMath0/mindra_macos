//
//  DatabaseManager.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 09.06.25.
//

import Foundation
import SQLite3

class DatabaseManager: ObservableObject {
    static let shared = DatabaseManager()
    
    let dbPath: String
    private let connection: DatabaseConnection
    private let sessionRepository: SessionRepository
    private let achievementRepository: AchievementRepository
    private let settingsRepository: SettingsRepository

    init() {
        // Preferred: Application Support directory
        let fm = FileManager.default
        let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appDir = appSupport?.appendingPathComponent("MindraTimer", isDirectory: true)
        if let appDir = appDir {
            if !fm.fileExists(atPath: appDir.path) {
                try? fm.createDirectory(at: appDir, withIntermediateDirectories: true)
            }
            dbPath = appDir.appendingPathComponent("mindra_timer.sqlite").path
        } else {
            // Fallback to Documents if Application Support cannot be resolved
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            dbPath = "\(documentsPath)/mindra_timer.sqlite"
        }
        
        connection = DatabaseConnection(dbPath: dbPath)
        
        do {
            try connection.connect()
            print("✅ Database connected successfully at: \(dbPath)")
        } catch {
            print("❌ Failed to connect to database: \(error.localizedDescription)")
        }
        
        sessionRepository = SessionRepository(connection: connection)
        achievementRepository = AchievementRepository(connection: connection)
        settingsRepository = SettingsRepository(connection: connection)
        
        createTables()
        
    }
    
    private func createTables() {
        let createSessionsTable = """
            CREATE TABLE IF NOT EXISTS focus_sessions (
                id TEXT PRIMARY KEY,
                started_at INTEGER NOT NULL,
                ended_at INTEGER,
                duration INTEGER NOT NULL,
                completed INTEGER NOT NULL,
                mode TEXT NOT NULL,
                notes TEXT,
                created_at INTEGER DEFAULT (strftime('%s', 'now'))
            );
        """
        
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
                unlocked_date INTEGER,
                created_at INTEGER DEFAULT (strftime('%s', 'now'))
            );
        """
        
        let createSettingsTable = """
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value BLOB NOT NULL,
                updated_at INTEGER DEFAULT (strftime('%s', 'now'))
            );
        """
        
        do {
            try connection.execute(createSessionsTable)
            print("✅ Sessions table created successfully")
        } catch {
            print("❌ Error creating sessions table: \(error.localizedDescription)")
        }
        
        do {
            try connection.execute(createAchievementsTable)
            print("✅ Achievements table created successfully")
        } catch {
            print("❌ Error creating achievements table: \(error.localizedDescription)")
        }
        
        do {
            try connection.execute(createSettingsTable)
            print("✅ Settings table created successfully")
        } catch {
            print("❌ Error creating settings table: \(error.localizedDescription)")
        }
        
        let createIndexes = """
            CREATE INDEX IF NOT EXISTS idx_sessions_started_at ON focus_sessions(started_at);
            CREATE INDEX IF NOT EXISTS idx_sessions_mode ON focus_sessions(mode);
            CREATE INDEX IF NOT EXISTS idx_sessions_completed ON focus_sessions(completed);
            CREATE INDEX IF NOT EXISTS idx_achievements_type ON achievements(type);
            CREATE INDEX IF NOT EXISTS idx_achievements_unlocked ON achievements(unlocked);
        """
        
        do {
            try connection.execute(createIndexes)
            print("✅ Database indexes created successfully")
        } catch {
            print("❌ Error creating indexes: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Session Management
    
    func addSession(_ session: FocusSession) -> Bool {
        do {
            try sessionRepository.create(session)
            print("✅ Session saved: \(session.id) (\(session.mode.rawValue), \(session.duration)s)")
            return true
        } catch {
            print("❌ Failed to save session: \(error.localizedDescription)")
            if let db = connection.getDatabasePointer() {
                let sqliteError = String(cString: sqlite3_errmsg(db))
                let code = sqlite3_errcode(db)
                print("🔍 SQLite Error \(code): \(sqliteError)")
            }
            return false
        }
    }
    
    func updateSessionCompletion(sessionId: String, completed: Bool) -> Bool {
        do {
            try sessionRepository.updateSessionCompletion(id: sessionId, completed: completed)
            print("✅ Session completion updated: \(sessionId) -> \(completed)")
            return true
        } catch {
            print("❌ Failed to update session completion: \(error.localizedDescription)")
            return false
        }
    }
    
    func getSessions(for period: StatsPeriod) -> [FocusSession] {
        do {
            let sessions = try sessionRepository.getSessions(for: period)
            print("✅ Retrieved \(sessions.count) sessions for period: \(period.rawValue)")
            return sessions
        } catch {
            print("❌ Failed to get sessions: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Stats Calculation Methods
    
    func calculateSummary(for sessions: [FocusSession]) -> StatsSummary {
        return sessionRepository.calculateSummary(for: sessions)
    }
    
    func generateChartData(for sessions: [FocusSession], period: StatsPeriod) -> [ChartData] {
        return sessionRepository.generateChartData(for: sessions, period: period)
    }
    
    // MARK: - Achievement Management
    
    func addAchievement(_ achievement: Achievement) -> Bool {
        do {
            try achievementRepository.create(achievement)
            return true
        } catch {
            print("❌ Failed to save achievement: \(error.localizedDescription)")
            return false
        }
    }
    
    func updateAchievement(_ achievement: Achievement) -> Bool {
        do {
            try achievementRepository.update(achievement)
            return true
        } catch {
            print("❌ Failed to update achievement: \(error.localizedDescription)")
            return false
        }
    }
    
    func getAchievements() -> [Achievement] {
        do {
            return try achievementRepository.getAllAchievements()
        } catch {
            print("❌ Failed to get achievements: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Settings Management
    
    func setSetting<T: Codable>(key: String, value: T) {
        do {
            try settingsRepository.setValue(value, for: key)
        } catch {
            print("❌ Failed to save setting: \(error.localizedDescription)")
        }
    }
    
    func getSetting<T: Codable>(key: String, type: T.Type, defaultValue: T) -> T {
        do {
            if let value = try settingsRepository.getValue(for: key, type: type) {
                return value
            }
            return defaultValue
        } catch {
            print("❌ Failed to get setting: \(error.localizedDescription)")
            return defaultValue
        }
    }

    
    // MARK: - IMMEDIATE FIX METHOD
    
    func fixDatabaseIssuesNow() {
        print("🚑 EMERGENCY DATABASE FIX STARTING...")
        print(String(repeating: "🔄", count: 20))
        
        print("\n1. PURGING USERDEFAULTS SESSION DATA:")
        purgeAllUserDefaultsSessionData()
        
        print("\n2. DIAGNOSING CURRENT ISSUES:")
        diagnoseDatabaseIssues()
        
        print("\n3. PERFORMING NUCLEAR RESET:")
        resetDatabaseForDevelopment()
        
        print("\n4. TESTING BASIC FUNCTIONALITY:")
        diagnoseDatabaseIssues()
        
        print("\n5. INITIALIZING DEFAULT DATA:")
        initializeDefaultData()
        
        print("\n6. FINAL VERIFICATION:")
        let isWorking = verifyDatabaseIntegrity()
        
        print(String(repeating: "🔄", count: 20))
        if isWorking {
            print("✅ DATABASE EMERGENCY FIX SUCCESSFUL!")
            print("🎉 Your database should now work properly")
            print("📊 All stats should come from database, not UserDefaults")
        } else {
            print("❌ DATABASE STILL HAS ISSUES")
            print("📞 Time to consider SwiftData or SQLite.swift migration")
        }
        print(String(repeating: "🔄", count: 20))
    }
    
    func verifyDatabaseIntegrity() -> Bool {
        do {
            guard connection.getDatabasePointer() != nil else {
                print("❌ Database connection is nil")
                return false
            }
            let sessions = try sessionRepository.getSessions(for: .day)
            print("✅ Database verification passed - found \(sessions.count) sessions today")
            return true
        } catch {
            print("❌ Database verification failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func diagnoseDatabaseIssues() {
        print("🔍 COMPREHENSIVE DATABASE DIAGNOSIS")
        print(String(repeating: "=", count: 50))
        
        guard let db = connection.getDatabasePointer() else {
            print("❌ CRITICAL: No database connection")
            return
        }
        
        let fileManager = FileManager.default
        print("📁 Database file exists: \(fileManager.fileExists(atPath: dbPath))")
        if let attributes = try? fileManager.attributesOfItem(atPath: dbPath) {
            let size = attributes[.size] as? Int64 ?? 0
            print("📁 Database file size: \(size) bytes")
        }
        
        print("🔍 CHECKING USERDEFAULTS:")
        let userDefaults = UserDefaults.standard
        let possibleKeys = [
            "focusSessions", "sessionsCompleted", "totalSessions",
            "pomodorosCycles", "pomodoroCycles", "cyclesCompleted",
            "totalFocusTime", "completedSessions", "streakCount"
        ]
        for key in possibleKeys {
            if let value = userDefaults.object(forKey: key) {
                print("✅ UserDefaults[\(key)] = \(value)")
            }
        }
        
        var statement: OpaquePointer?
        let testTableSQL = "CREATE TABLE IF NOT EXISTS test_table (id INTEGER PRIMARY KEY, name TEXT);"
        if sqlite3_exec(db, testTableSQL, nil, nil, nil) == SQLITE_OK {
            print("✅ Basic table creation: OK")
        } else {
            let error = String(cString: sqlite3_errmsg(db))
            print("❌ Basic table creation: FAILED - \(error)")
        }
        
        let insertSQL = "INSERT INTO test_table (name) VALUES (?);"
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, "test", -1, nil)
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Basic insert: OK")
            } else {
                let error = String(cString: sqlite3_errmsg(db))
                print("❌ Basic insert: FAILED - \(error)")
            }
            sqlite3_finalize(statement)
        } else {
            let error = String(cString: sqlite3_errmsg(db))
            print("❌ Basic insert prepare: FAILED - \(error)")
        }
        
        let selectSQL = "SELECT COUNT(*) FROM test_table;"
        if sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let count = sqlite3_column_int(statement, 0)
                print("✅ Basic select: OK - found \(count) rows")
            } else {
                let error = String(cString: sqlite3_errmsg(db))
                print("❌ Basic select: FAILED - \(error)")
            }
            sqlite3_finalize(statement)
        } else {
            let error = String(cString: sqlite3_errmsg(db))
            print("❌ Basic select prepare: FAILED - \(error)")
        }
        
        let tables = ["focus_sessions", "achievements", "settings"]
        for table in tables {
            let checkSQL = "SELECT COUNT(*) FROM \(table);"
            if sqlite3_prepare_v2(db, checkSQL, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    let count = sqlite3_column_int(statement, 0)
                    print("✅ Table \(table): \(count) rows")
                } else {
                    let error = String(cString: sqlite3_errmsg(db))
                    print("❌ Table \(table): FAILED - \(error)")
                }
                sqlite3_finalize(statement)
            } else {
                let error = String(cString: sqlite3_errmsg(db))
                print("❌ Table \(table) check: FAILED - \(error)")
            }
        }
        
        for table in tables {
            print("📁 Schema for \(table):")
            let schemaSQL = "PRAGMA table_info(\(table));"
            if sqlite3_prepare_v2(db, schemaSQL, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let name = String(cString: sqlite3_column_text(statement, 1))
                    let type = String(cString: sqlite3_column_text(statement, 2))
                    print("   \(name): \(type)")
                }
                sqlite3_finalize(statement)
            }
        }
        
        sqlite3_exec(db, "DROP TABLE IF EXISTS test_table;", nil, nil, nil)
        
        print(String(repeating: "=", count: 50))
        print("🔍 DIAGNOSIS COMPLETE")
        print("💡 THEORY: UI is showing UserDefaults data, not database data!")
    }
    
    func clearAllData() {
        do {
            let sessions = try sessionRepository.getSessions(for: .all)
            for session in sessions {
                try sessionRepository.delete(id: session.id)
            }
            let achievements = try achievementRepository.getAllAchievements()
            for achievement in achievements {
                try achievementRepository.delete(id: achievement.id.uuidString)
            }
            try settingsRepository.clearAllSettings()
            print("🗑️ Database cleared")
        } catch {
            print("❌ Failed to clear database: \(error.localizedDescription)")
        }
    }
    
    func resetDatabaseForDevelopment() {
        print("🔄 Resetting database for development...")
        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: dbPath) {
                try fileManager.removeItem(atPath: dbPath)
                print("💥 Database file deleted: \(dbPath)")
            }
            let walPath = dbPath + "-wal"
            let shmPath = dbPath + "-shm"
            if fileManager.fileExists(atPath: walPath) {
                try fileManager.removeItem(atPath: walPath)
                print("💥 WAL file deleted")
            }
            if fileManager.fileExists(atPath: shmPath) {
                try fileManager.removeItem(atPath: shmPath)
                print("💥 SHM file deleted")
            }
        } catch {
            print("❌ Failed to delete database files: \(error.localizedDescription)")
        }
        
        connection.disconnect()
        
        do {
            try connection.connect()
            print("✅ Fresh database connection established")
        } catch {
            print("❌ Failed to reconnect: \(error.localizedDescription)")
        }
        
        createTables()
        print("✅ Database completely reset - pristine state")
    }
    
    func purgeAllUserDefaultsSessionData() {
        print("🧽 PURGING ALL USERDEFAULTS SESSION DATA...")
        let userDefaults = UserDefaults.standard
        let sessionKeys = [
            "focusSessions", "sessionsCompleted", "totalSessions",
            "pomodorosCycles", "pomodoroCycles", "cyclesCompleted",
            "totalFocusTime", "completedSessions", "streakCount",
            "currentStreak", "bestStreak", "totalTasksCompleted",
            "completionRate", "averageSessionLength", "stats_migrated_v1",
            "lastSessionDate", "dailyGoal", "weeklyGoal", "monthlyGoal"
        ]
        for key in sessionKeys {
            if let oldValue = userDefaults.object(forKey: key) {
                print("🗑️ Removing UserDefaults[\(key)] = \(oldValue)")
                userDefaults.removeObject(forKey: key)
            }
        }
        userDefaults.synchronize()
        print("✅ All UserDefaults session data purged")
    }
    
    func initializeDefaultData() {
        print("🌱 Initializing default data for development...")
        let defaults = [
            Achievement(title: "First Focus", description: "Complete your first focus session", icon: "🎯", type: .sessionsCompleted, progress: 0, target: 1),
            Achievement(title: "Focus Master", description: "Complete 10 focus sessions", icon: "🏆", type: .sessionsCompleted, progress: 0, target: 10),
            Achievement(title: "Time Keeper", description: "Focus for 2 hours total", icon: "⏰", type: .totalFocusTime, progress: 0, target: 120),
            Achievement(title: "Streak Starter", description: "Maintain a 3-day focus streak", icon: "🔥", type: .streak, progress: 0, target: 3)
        ]
        for achievement in defaults {
            if addAchievement(achievement) {
                print("✅ Created default achievement: \(achievement.title)")
            } else {
                print("❌ Failed to create achievement: \(achievement.title)")
            }
        }
        print("✅ Default data initialization complete")
    }
    
    func getSessionRepository() -> SessionRepository { sessionRepository }
    func getAchievementRepository() -> AchievementRepository { achievementRepository }
    func getSettingsRepository() -> SettingsRepository { settingsRepository }
}
