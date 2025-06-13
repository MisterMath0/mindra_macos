import Foundation
import SQLite3

class SessionRepository: BaseRepository<FocusSession>, Repository {
    init(connection: DatabaseConnection) {
        super.init(connection: connection, tableName: "focus_sessions")
    }
    
    override func mapRow(_ row: [String: Any]) throws -> FocusSession {
        guard let id = row["id"] as? String,
              let startedAtTimestamp = row["started_at"] as? Int64,
              let duration = row["duration"] as? Int64,
              let modeString = row["mode"] as? String,
              let mode = TimerMode(rawValue: modeString),
              let completedInt = row["completed"] as? Int64 else {
            throw DatabaseError.invalidData("Missing required fields for FocusSession")
        }
        
        let startedAt = Date(timeIntervalSince1970: TimeInterval(startedAtTimestamp))
        let completed = completedInt == 1
        
        var endedAt: Date?
        if let endedAtTimestamp = row["ended_at"] as? Int64 {
            endedAt = Date(timeIntervalSince1970: TimeInterval(endedAtTimestamp))
        }
        
        let notes = row["notes"] as? String
        
        return FocusSession(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            duration: Int(duration),
            completed: completed,
            mode: mode,
            notes: notes
        )
    }
    
    func create(_ session: FocusSession) throws {
        let query = """
            INSERT INTO focus_sessions (id, started_at, ended_at, duration, completed, mode, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """
        
        // Convert dates to timestamps and handle optionals properly
        let startedAtTimestamp = Int64(session.startedAt.timeIntervalSince1970)
        let endedAtTimestamp: Int64? = session.endedAt != nil ? Int64(session.endedAt!.timeIntervalSince1970) : nil
        let completedInt = session.completed ? 1 : 0
        
        var params: [Any] = [
            session.id,
            startedAtTimestamp,
            endedAtTimestamp ?? NSNull(),
            Int64(session.duration),
            completedInt,
            session.mode.rawValue,
            session.notes ?? NSNull()
        ]
        
        try executeUpdate(query, params: params)
    }
    
    func read(id: String) throws -> FocusSession {
        let query = "SELECT * FROM focus_sessions WHERE id = ?"
        let results = try executeQuery(query, params: [id])
        guard let row = results.first else {
            throw DatabaseError.notFound("Session not found with id: \(id)")
        }
        return try mapRow(row)
    }
    
    func update(_ session: FocusSession) throws {
        let query = """
            UPDATE focus_sessions 
            SET started_at = ?,
                ended_at = ?,
                duration = ?,
                completed = ?,
                mode = ?,
                notes = ?
            WHERE id = ?
        """
        
        // Convert dates to timestamps and handle optionals properly
        let startedAtTimestamp = Int64(session.startedAt.timeIntervalSince1970)
        let endedAtTimestamp: Int64? = session.endedAt != nil ? Int64(session.endedAt!.timeIntervalSince1970) : nil
        let completedInt = session.completed ? 1 : 0
        
        var params: [Any] = [
            startedAtTimestamp,
            endedAtTimestamp ?? NSNull(),
            Int64(session.duration),
            completedInt,
            session.mode.rawValue,
            session.notes ?? NSNull(),
            session.id
        ]
        
        try executeUpdate(query, params: params)
    }
    
    func delete(id: String) throws {
        let query = "DELETE FROM focus_sessions WHERE id = ?"
        try executeUpdate(query, params: [id])
    }
    
    func getSessions(for period: StatsPeriod) throws -> [FocusSession] {
        let dateRange = period.dateRange
        let query = """
            SELECT * FROM focus_sessions 
            WHERE started_at BETWEEN ? AND ? 
            ORDER BY started_at DESC
        """
        
        // Convert dates to timestamps for SQLite
        let startTimestamp = Int64(dateRange.start.timeIntervalSince1970)
        let endTimestamp = Int64(dateRange.end.timeIntervalSince1970)
        
        let results = try executeQuery(query, params: [startTimestamp, endTimestamp])
        return try results.map { try mapRow($0) }
    }
    
    func getTotalFocusTime(for period: StatsPeriod) throws -> Int {
        let dateRange = period.dateRange
        let query = """
            SELECT SUM(duration) as total 
            FROM focus_sessions 
            WHERE started_at BETWEEN ? AND ? 
            AND mode = 'focus'
        """
        
        // Convert dates to timestamps for SQLite
        let startTimestamp = Int64(dateRange.start.timeIntervalSince1970)
        let endTimestamp = Int64(dateRange.end.timeIntervalSince1970)
        
        let results = try executeQuery(query, params: [startTimestamp, endTimestamp])
        if let totalInt64 = results.first?["total"] as? Int64 {
            return Int(totalInt64)
        }
        return 0
    }
    
    func getCompletedSessionsCount(for period: StatsPeriod) throws -> Int {
        let dateRange = period.dateRange
        let query = """
            SELECT COUNT(*) as count 
            FROM focus_sessions 
            WHERE started_at BETWEEN ? AND ? 
            AND completed = 1
        """
        
        // Convert dates to timestamps for SQLite
        let startTimestamp = Int64(dateRange.start.timeIntervalSince1970)
        let endTimestamp = Int64(dateRange.end.timeIntervalSince1970)
        
        let results = try executeQuery(query, params: [startTimestamp, endTimestamp])
        if let countInt64 = results.first?["count"] as? Int64 {
            return Int(countInt64)
        }
        return 0
    }
    
    func updateSessionCompletion(id: String, completed: Bool) throws {
        let endedAt = completed ? Date() : nil
        let query = """
            UPDATE focus_sessions 
            SET completed = ?, ended_at = ?
            WHERE id = ?
        """
        
        // Convert completion status and date properly
        let completedInt = completed ? 1 : 0
        let endedAtTimestamp: Int64? = endedAt != nil ? Int64(endedAt!.timeIntervalSince1970) : nil
        
        var params: [Any] = [
            completedInt,
            endedAtTimestamp ?? NSNull(),
            id
        ]
        
        try executeUpdate(query, params: params)
    }
    
    // MARK: - Stats Calculations
    
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
        let dateRange = period.dateRange
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        var chartData: [ChartData] = []
        var currentDate = dateRange.start
        
        // Create array of all dates in range
        while currentDate <= dateRange.end {
            let dayString = dateFormatter.string(from: currentDate)
            chartData.append(ChartData(day: dayString, focusMinutes: 0, sessions: 0, date: currentDate))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Populate with session data
        for session in sessions {
            let sessionDay = dateFormatter.string(from: session.startedAt)
            
            if let index = chartData.firstIndex(where: { $0.day == sessionDay }) {
                let focusMinutes = session.mode == .focus ? session.duration / 60 : 0
                let existingData = chartData[index]
                chartData[index] = ChartData(
                    day: existingData.day,
                    focusMinutes: existingData.focusMinutes + focusMinutes,
                    sessions: existingData.sessions + 1,
                    date: existingData.date
                )
            }
        }
        
        return chartData
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
} 