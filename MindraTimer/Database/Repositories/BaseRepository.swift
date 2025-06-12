import Foundation
import SQLite3

protocol Repository {
    associatedtype T
    func create(_ item: T) throws
    func read(id: String) throws -> T
    func update(_ item: T) throws
    func delete(id: String) throws
}

class BaseRepository<T> {
    let connection: DatabaseConnection
    let tableName: String
    
    init(connection: DatabaseConnection, tableName: String) {
        self.connection = connection
        self.tableName = tableName
    }
    
    func executeQuery(_ query: String, params: [Any] = []) throws -> [[String: Any]] {
        var statement: OpaquePointer?
        var results: [[String: Any]] = []
        
        do {
            statement = try connection.prepareStatement(query)
            defer { connection.finalizeStatement(statement) }
            
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
                case let bool as Bool:
                    sqlite3_bind_int(statement, paramIndex, bool ? 1 : 0)
                case let date as Date:
                    let timestamp = Int64(date.timeIntervalSince1970)
                    sqlite3_bind_int64(statement, paramIndex, timestamp)
                case is NSNull:
                    sqlite3_bind_null(statement, paramIndex)
                default:
                    throw DatabaseError.invalidParameter("Unsupported parameter type: \(type(of: param))")
                }
            }
            
            // Execute query and process results
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
                    case SQLITE_BLOB:
                        if let blob = sqlite3_column_blob(statement, i) {
                            let size = sqlite3_column_bytes(statement, i)
                            row[columnName] = Data(bytes: blob, count: Int(size))
                        }
                    case SQLITE_NULL:
                        row[columnName] = NSNull()
                    default:
                        throw DatabaseError.invalidData("Unsupported column type: \(columnType)")
                    }
                }
                
                results.append(row)
            }
            
            return results
        } catch {
            throw DatabaseError.queryFailed("Failed to execute query: \(error.localizedDescription)")
        }
    }
    
    func executeUpdate(_ query: String, params: [Any] = []) throws {
        var statement: OpaquePointer?
        
        do {
            statement = try connection.prepareStatement(query)
            defer { connection.finalizeStatement(statement) }
            
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
                case let bool as Bool:
                    sqlite3_bind_int(statement, paramIndex, bool ? 1 : 0)
                case let date as Date:
                    let timestamp = Int64(date.timeIntervalSince1970)
                    sqlite3_bind_int64(statement, paramIndex, timestamp)
                case is NSNull:
                    sqlite3_bind_null(statement, paramIndex)
                default:
                    throw DatabaseError.invalidParameter("Unsupported parameter type: \(type(of: param))")
                }
            }
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(connection.getDatabasePointer()))
                throw DatabaseError.queryFailed(errorMessage)
            }
        } catch {
            throw DatabaseError.queryFailed("Failed to execute update: \(error.localizedDescription)")
        }
    }
    
    func mapRow(_ row: [String: Any]) throws -> T {
        fatalError("mapRow must be implemented by subclasses")
    }
} 