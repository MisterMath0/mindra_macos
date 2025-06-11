import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
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
            print("Unable to open database at \(dbPath)")
        }
    }
    
    private func closeDatabase() {
        if sqlite3_close(db) != SQLITE_OK {
            print("Unable to close database")
        }
    }
    
    private func createTables() {
        // Focus sessions table
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
                unlocked_at TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            );
        """
        
        // Execute table creation
        if sqlite3_exec(db, createSessionsTable, nil, nil, nil) != SQLITE_OK {
            print("Error creating sessions table")
        }
        
        if sqlite3_exec(db, createSettingsTable, nil, nil, nil) != SQLITE_OK {
            print("Error creating settings table")
        }
        
        if sqlite3_exec(db, createAchievementsTable, nil, nil, nil) != SQLITE_OK {
            print("Error creating achievements table")
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
    
    func addSession(_ session: PomodoroSession) -> Bool {
        let insertSQL = """
            INSERT INTO focus_sessions (id, started_at, ended_at, duration, completed, mode, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, session.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, ISO8601DateFormatter().string(from: session.startTime), -1, nil)
            
            if let endTime = session.endTime {
                sqlite3_bind_text(statement, 3, ISO8601DateFormatter().string(from: endTime), -1, nil)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            
            sqlite3_bind_int(statement, 4, Int32(session.duration))
            sqlite3_bind_int(statement, 5, session.completed ? 1 : 0)
            sqlite3_bind_text(statement, 6, session.type.rawValue, -1, nil)
            
            if let notes = session.notes {
                sqlite3_bind_text(statement, 7, notes, -1, nil)
            } else {
                sqlite3_bind_null(statement, 7)
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func updateSession(_ session: PomodoroSession) -> Bool {
        let updateSQL = """
            UPDATE focus_sessions 
            SET ended_at = ?, completed = ?, notes = ?
            WHERE id = ?
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateSQL, -1, &statement, nil) == SQLITE_OK {
            if let endTime = session.endTime {
                sqlite3_bind_text(statement, 1, ISO8601DateFormatter().string(from: endTime), -1, nil)
            } else {
                sqlite3_bind_null(statement, 1)
            }
            
            sqlite3_bind_int(statement, 2, session.completed ? 1 : 0)
            
            if let notes = session.notes {
                sqlite3_bind_text(statement, 3, notes, -1, nil)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            
            sqlite3_bind_text(statement, 4, session.id.uuidString, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func getSessions(for period: StatsPeriod) -> [PomodoroSession] {
        let dateRange = getDateRange(for: period)
        let dateFormatter = ISO8601DateFormatter()
        
        let querySQL = """
            SELECT id, started_at, ended_at, duration, completed, mode, notes
            FROM focus_sessions
            WHERE started_at >= ?
            ORDER BY started_at DESC
        """
        
        var statement: OpaquePointer?
        var sessions: [PomodoroSession] = []
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, dateFormatter.string(from: dateRange.start), -1, nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let idString = String(cString: sqlite3_column_text(statement, 0))
                let startedAtString = String(cString: sqlite3_column_text(statement, 1))
                let endedAtPointer = sqlite3_column_text(statement, 2)
                let duration = Int(sqlite3_column_int(statement, 3))
                let completed = sqlite3_column_int(statement, 4) == 1
                let modeString = String(cString: sqlite3_column_text(statement, 5))
                let notesPointer = sqlite3_column_text(statement, 6)
                
                if let id = UUID(uuidString: idString),
                   let startedAt = dateFormatter.date(from: startedAtString),
                   let type = PomodoroSession.SessionType(rawValue: modeString) {
                    
                    var endedAt: Date?
                    if let endedAtPointer = endedAtPointer {
                        let endedAtString = String(cString: endedAtPointer)
                        endedAt = dateFormatter.date(from: endedAtString)
                    }
                    
                    var notes: String?
                    if let notesPointer = notesPointer {
                        notes = String(cString: notesPointer)
                    }
                    
                    let session = PomodoroSession(
                        id: id,
                        startTime: startedAt,
                        endTime: endedAt,
                        duration: TimeInterval(duration),
                        type: type,
                        completed: completed,
                        notes: notes
                    )
                    sessions.append(session)
                }
            }
        }
        
        sqlite3_finalize(statement)
        return sessions
    }
    
    // MARK: - Settings Management
    
    func saveSettings(_ settings: Settings) {
        guard let data = try? JSONEncoder().encode(settings),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }
        
        let upsertSQL = """
            INSERT OR REPLACE INTO settings (key, value, updated_at)
            VALUES (?, ?, CURRENT_TIMESTAMP)
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, upsertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, "app_settings", -1, nil)
            sqlite3_bind_text(statement, 2, jsonString, -1, nil)
            sqlite3_step(statement)
        }
        
        sqlite3_finalize(statement)
    }
    
    func loadSettings() -> Settings {
        let querySQL = "SELECT value FROM settings WHERE key = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, "app_settings", -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let valueString = String(cString: sqlite3_column_text(statement, 0))
                
                if let data = valueString.data(using: .utf8),
                   let settings = try? JSONDecoder().decode(Settings.self, from: data) {
                    sqlite3_finalize(statement)
                    return settings
                }
            }
        }
        
        sqlite3_finalize(statement)
        return Settings.default
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
} 