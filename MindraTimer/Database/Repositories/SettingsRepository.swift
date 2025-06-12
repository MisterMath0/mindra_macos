import Foundation
import SQLite3

class SettingsRepository: BaseRepository<AppSettings>, Repository {
    init(connection: DatabaseConnection) {
        super.init(connection: connection, tableName: "settings")
    }
    
    override func mapRow(_ row: [String: Any]) throws -> AppSettings {
        guard let valueData = row["value"] as? Data else {
            throw DatabaseError.invalidData("Missing value data for settings")
        }
        
        return try JSONDecoder().decode(AppSettings.self, from: valueData)
    }
    
    func create(_ settings: AppSettings) throws {
        let data = try JSONEncoder().encode(settings)
        let query = "INSERT INTO settings (key, value) VALUES (?, ?)"
        try executeUpdate(query, params: ["app_settings", data])
    }
    
    func read(id: String) throws -> AppSettings {
        let query = "SELECT * FROM settings WHERE key = ?"
        let results = try executeQuery(query, params: [id])
        
        guard let row = results.first else {
            throw DatabaseError.notFound("Settings not found with key: \(id)")
        }
        
        return try mapRow(row)
    }
    
    func update(_ settings: AppSettings) throws {
        let data = try JSONEncoder().encode(settings)
        let query = "UPDATE settings SET value = ? WHERE key = ?"
        try executeUpdate(query, params: [data, "app_settings"])
    }
    
    func delete(id: String) throws {
        let query = "DELETE FROM settings WHERE key = ?"
        try executeUpdate(query, params: [id])
    }
    
    func getValue<T: Codable>(for key: String, type: T.Type) throws -> T? {
        let query = "SELECT value FROM settings WHERE key = ?"
        let results = try executeQuery(query, params: [key])
        
        guard let row = results.first,
              let valueData = row["value"] as? Data else {
            return nil
        }
        
        return try JSONDecoder().decode(T.self, from: valueData)
    }
    
    func setValue<T: Codable>(_ value: T, for key: String) throws {
        let data = try JSONEncoder().encode(value)
        let query = "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)"
        try executeUpdate(query, params: [key, data])
    }
    
    func getAllSettings() throws -> [AppSettings] {
        let query = "SELECT * FROM settings"
        let results = try executeQuery(query)
        return try results.map { try mapRow($0) }
    }
    
    func deleteSetting(for key: String) throws {
        let query = "DELETE FROM settings WHERE key = ?"
        try executeUpdate(query, params: [key])
    }
    
    func clearAllSettings() throws {
        let query = "DELETE FROM settings"
        try executeUpdate(query)
    }
} 