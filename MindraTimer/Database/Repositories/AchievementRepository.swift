import Foundation
import SQLite3

class AchievementRepository: BaseRepository<Achievement> {
    static let tableName = "achievements"
    
    init(connection: DatabaseConnection) {
        super.init(connection: connection, tableName: Self.tableName)
    }
    
    // MARK: - Repository Protocol
    
    func create(_ achievement: Achievement) throws {
        let query = """
            INSERT OR REPLACE INTO \(tableName) 
            (id, title, description, icon, type, progress, target, unlocked, unlocked_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let params: [Any] = [
            achievement.id.uuidString,
            achievement.title,
            achievement.description,
            achievement.icon,
            achievement.type.rawValue,
            achievement.progress,
            achievement.target,
            achievement.unlocked,
            achievement.unlockedDate as Any
        ]
        
        try executeUpdate(query, params: params)
    }
    
    func read(id: String) throws -> Achievement {
        let query = "SELECT * FROM \(tableName) WHERE id = ?"
        let rows = try executeQuery(query, params: [id])
        
        guard let row = rows.first else {
            throw DatabaseError.notFound("Achievement not found with id: \(id)")
        }
        
        return try mapRow(row)
    }
    
    func update(_ achievement: Achievement) throws {
        try create(achievement) // Use create for upsert functionality
    }
    
    func delete(id: String) throws {
        let query = "DELETE FROM \(tableName) WHERE id = ?"
        try executeUpdate(query, params: [id])
    }
    
    // MARK: - Additional Methods
    
    func getAllAchievements() throws -> [Achievement] {
        let query = "SELECT * FROM \(tableName) ORDER BY title"
        let rows = try executeQuery(query)
        return try rows.map { try mapRow($0) }
    }
    
    func getUnlockedAchievements() throws -> [Achievement] {
        let query = "SELECT * FROM \(tableName) WHERE unlocked = 1 ORDER BY unlocked_date DESC"
        let rows = try executeQuery(query)
        return try rows.map { try mapRow($0) }
    }
    
    func getAchievementsByType(_ type: Achievement.AchievementType) throws -> [Achievement] {
        let query = "SELECT * FROM \(tableName) WHERE type = ? ORDER BY title"
        let rows = try executeQuery(query, params: [type.rawValue])
        return try rows.map { try mapRow($0) }
    }
    
    func updateProgress(id: String, progress: Double) throws {
        let query = """
            UPDATE \(tableName)
            SET progress = ?, 
                unlocked = CASE WHEN progress >= target THEN 1 ELSE 0 END,
                unlocked_date = CASE WHEN progress >= target AND unlocked = 0 THEN CURRENT_TIMESTAMP ELSE unlocked_date END
            WHERE id = ?
        """
        try executeUpdate(query, params: [progress, id])
    }
    
    // MARK: - Row Mapping
    
    override func mapRow(_ row: [String: Any]) throws -> Achievement {
        guard let idString = row["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = row["title"] as? String,
              let description = row["description"] as? String,
              let icon = row["icon"] as? String,
              let typeString = row["type"] as? String,
              let type = Achievement.AchievementType(rawValue: typeString),
              let progress = row["progress"] as? Double,
              let target = row["target"] as? Double,
              let unlockedInt = row["unlocked"] as? Int64 else {
            throw DatabaseError.invalidData("Missing required fields in achievement data")
        }
        
        let unlocked = unlockedInt == 1
        
        var unlockedDate: Date?
        if let unlockedTimestamp = row["unlocked_date"] as? Int64 {
            unlockedDate = Date(timeIntervalSince1970: TimeInterval(unlockedTimestamp))
        }
        
        return Achievement(
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
    }
} 