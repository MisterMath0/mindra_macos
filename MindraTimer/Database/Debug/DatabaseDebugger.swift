//
//  DatabaseDebugger.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 12.06.25.
//

import Foundation
import SQLite3

class DatabaseDebugger {
    private let connection: DatabaseConnection
    
    init(connection: DatabaseConnection) {
        self.connection = connection
    }
    
    func getDebugInfo() -> String {
        var info = "📊 Database Debug Information:\n\n"
        
        // Database file info
        if connection.getDatabasePointer() != nil {
            info += "✅ Database Connection: Active\n"
        } else {
            info += "❌ Database Connection: Inactive\n"
        }
        
        // Table info
        info += getTableInfo()
        
        // Data counts
        info += getDataCounts()
        
        // Recent activities
        info += getRecentActivities()
        
        return info
    }
    
    private func getTableInfo() -> String {
        var info = "\n🗄️ Tables:\n"
        
        let tables = ["focus_sessions", "achievements", "settings"]
        
        for table in tables {
            if tableExists(table) {
                info += "✅ \(table)\n"
                info += getTableSchema(table)
            } else {
                info += "❌ \(table) (missing)\n"
            }
        }
        
        return info
    }
    
    private func tableExists(_ tableName: String) -> Bool {
        guard let db = connection.getDatabasePointer() else {
            print("No database pointer available for table check")
            return false
        }
        
        var statement: OpaquePointer?
        let query = "SELECT name FROM sqlite_master WHERE type='table' AND name=?;"
        
        var exists = false
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, tableName, -1, nil)
            if sqlite3_step(statement) == SQLITE_ROW {
                exists = true
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error checking table existence for \(tableName): \(errorMessage)")
        }
        
        sqlite3_finalize(statement)
        return exists
    }
    
    private func getTableSchema(_ tableName: String) -> String {
        guard let db = connection.getDatabasePointer() else {
            return "   Error: No database connection\n"
        }
        
        let query = "PRAGMA table_info(\(tableName));"
        var statement: OpaquePointer?
        var schema = ""
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let namePtr = sqlite3_column_text(statement, 1),
                   let typePtr = sqlite3_column_text(statement, 2) {
                    let name = String(cString: namePtr)
                    let type = String(cString: typePtr)
                    let notNull = sqlite3_column_int(statement, 3) == 1 ? " NOT NULL" : ""
                    let pk = sqlite3_column_int(statement, 5) > 0 ? " PRIMARY KEY" : ""
                    schema += "   • \(name) (\(type)\(notNull)\(pk))\n"
                } else {
                    schema += "   • [Error reading column info]\n"
                }
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            schema = "   Error getting schema: \(errorMessage)\n"
        }
        
        sqlite3_finalize(statement)
        return schema.isEmpty ? "   No columns found\n" : schema
    }
    
    private func getDataCounts() -> String {
        var info = "\n📈 Data Counts:\n"
        
        let tables = [
            "focus_sessions": "Sessions",
            "achievements": "Achievements", 
            "settings": "Settings"
        ]
        
        for (table, displayName) in tables {
            let count = getTableCount(table)
            info += "• \(displayName): \(count)\n"
        }
        
        return info
    }
    
    private func getTableCount(_ tableName: String) -> Int {
        let query = "SELECT COUNT(*) as count FROM \(tableName)"
        
        guard let db = connection.getDatabasePointer() else {
            print("No database pointer available for count query")
            return 0
        }
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let count = sqlite3_column_int64(statement, 0)
                sqlite3_finalize(statement)
                return Int(count)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error getting count for \(tableName): \(errorMessage)")
        }
        
        sqlite3_finalize(statement)
        return 0
    }
    
    private func getRecentActivities() -> String {
        var info = "\n🕒 Recent Activities:\n"
        
        // Recent sessions
        info += "Recent Sessions:\n"
        let sessionQuery = "SELECT id, mode, duration, completed FROM focus_sessions ORDER BY started_at DESC LIMIT 3"
        
        do {
            let sessions = try executeQuery(sessionQuery)
            if sessions.isEmpty {
                info += "   No sessions found\n"
            } else {
                for session in sessions {
                    if let id = session["id"] as? String,
                       let mode = session["mode"] as? String,
                       let duration = session["duration"] as? Int64,
                       let completed = session["completed"] as? Int64 {
                        let completedStr = completed == 1 ? "✅" : "❌"
                        info += "   • \(id.prefix(8)): \(mode) (\(duration/60)m) \(completedStr)\n"
                    }
                }
            }
        } catch {
            info += "   Error loading sessions: \(error)\n"
        }
        
        // Recent achievements
        info += "\nRecent Achievements:\n"
        let achievementQuery = "SELECT title, unlocked FROM achievements ORDER BY created_at DESC LIMIT 3"
        
        do {
            let achievements = try executeQuery(achievementQuery)
            if achievements.isEmpty {
                info += "   No achievements found\n"
            } else {
                for achievement in achievements {
                    if let title = achievement["title"] as? String,
                       let unlocked = achievement["unlocked"] as? Int64 {
                        let unlockedStr = unlocked == 1 ? "🏆" : "⏳"
                        info += "   • \(title) \(unlockedStr)\n"
                    }
                }
            }
        } catch {
            info += "   Error loading achievements: \(error)\n"
        }
        
        return info
    }
    
    func testBasicOperations() -> String {
        var results = "🧪 Database Test Results:\n\n"
        
        // Test 1: Insert a test session
        results += "Test 1: Insert Session\n"
        let testSession = FocusSession(
            id: "test-session-\(UUID().uuidString)",
            startedAt: Date(),
            endedAt: nil,
            duration: 1500, // 25 minutes
            completed: false,
            mode: .focus
        )
        
        do {
            let sessionRepo = SessionRepository(connection: connection)
            try sessionRepo.create(testSession)
            results += "✅ Session inserted successfully\n"
            
            // Test 2: Read the session back
            let retrievedSession = try sessionRepo.read(id: testSession.id)
            results += "✅ Session retrieved successfully\n"
            results += "   ID: \(retrievedSession.id)\n"
            results += "   Duration: \(retrievedSession.duration)s\n"
            results += "   Mode: \(retrievedSession.mode.rawValue)\n"
            
            // Test 3: Update the session
            try sessionRepo.updateSessionCompletion(id: testSession.id, completed: true)
            let updatedSession = try sessionRepo.read(id: testSession.id)
            results += "✅ Session updated successfully\n"
            results += "   Completed: \(updatedSession.completed)\n"
            
            // Test 4: Delete the session
            try sessionRepo.delete(id: testSession.id)
            results += "✅ Session deleted successfully\n"
            
        } catch {
            results += "❌ Session test failed: \(error.localizedDescription)\n"
        }
        
        // Test 5: Insert a test achievement
        results += "\nTest 5: Insert Achievement\n"
        let testAchievement = Achievement(
            title: "Test Achievement",
            description: "A test achievement",
            icon: "🏆",
            type: .totalFocusTime,
            progress: 0,
            target: 100
        )
        
        do {
            let achievementRepo = AchievementRepository(connection: connection)
            try achievementRepo.create(testAchievement)
            results += "✅ Achievement inserted successfully\n"
            
            let retrievedAchievement = try achievementRepo.read(id: testAchievement.id.uuidString)
            results += "✅ Achievement retrieved successfully\n"
            results += "   Title: \(retrievedAchievement.title)\n"
            
            // Clean up
            try achievementRepo.delete(id: testAchievement.id.uuidString)
            results += "✅ Achievement deleted successfully\n"
            
        } catch {
            results += "❌ Achievement test failed: \(error.localizedDescription)\n"
        }
        
        return results
    }
    
    private func executeQuery(_ query: String, params: [Any] = []) throws -> [[String: Any]] {
        var statement: OpaquePointer?
        var results: [[String: Any]] = []
        
        guard let db = connection.getDatabasePointer() else {
            throw DatabaseError.connectionFailed("No database connection")
        }
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(errorMessage)
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind parameters
        for (index, param) in params.enumerated() {
            let paramIndex = Int32(index + 1)
            switch param {
            case let string as String:
                sqlite3_bind_text(statement, paramIndex, string, -1, nil)
            case let int as Int:
                sqlite3_bind_int64(statement, paramIndex, Int64(int))
            case let double as Double:
                sqlite3_bind_double(statement, paramIndex, double)
            default:
                break
            }
        }
        
        // Execute and collect results
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columnCount = sqlite3_column_count(statement)
            
            for i in 0..<columnCount {
                let columnName = String(cString: sqlite3_column_name(statement, i))
                let columnType = sqlite3_column_type(statement, i)
                
                switch columnType {
                case SQLITE_INTEGER:
                    row[columnName] = sqlite3_column_int64(statement, i)
                case SQLITE_FLOAT:
                    row[columnName] = sqlite3_column_double(statement, i)
                case SQLITE_TEXT:
                    if let text = sqlite3_column_text(statement, i) {
                        row[columnName] = String(cString: text)
                    }
                case SQLITE_NULL:
                    row[columnName] = NSNull()
                default:
                    break
                }
            }
            
            results.append(row)
        }
        
        return results
    }
    
    func clearTestData() {
        let queries = [
            "DELETE FROM focus_sessions WHERE id LIKE 'test-%'",
            "DELETE FROM achievements WHERE title LIKE '%Test%'"
        ]
        
        for query in queries {
            do {
                try connection.execute(query)
            } catch {
                print("Error clearing test data: \(error)")
            }
        }
    }
}
