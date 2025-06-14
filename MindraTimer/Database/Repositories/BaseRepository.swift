import Foundation
import SQLite3

// SQLite constants
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

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
        return try connection.performSync {
            var statement: OpaquePointer?
            var results: [[String: Any]] = []
        
        do {
            statement = try connection.prepareStatement(query)
            defer { connection.finalizeStatement(statement) }
            
            // Bind parameters with better optional handling
            for (index, param) in params.enumerated() {
                let paramIndex = Int32(index + 1)
                
                // Handle wrapped optionals
                let unwrappedParam: Any
                if let optionalParam = param as? Any? {
                    if let value = optionalParam {
                        unwrappedParam = value
                    } else {
                        sqlite3_bind_null(statement, paramIndex)
                        continue
                    }
                } else {
                    unwrappedParam = param
                }
                
                switch unwrappedParam {
                case let string as String:
                    sqlite3_bind_text(statement, paramIndex, string, -1, SQLITE_TRANSIENT)
                case let int as Int:
                    sqlite3_bind_int64(statement, paramIndex, Int64(int))
                case let int64 as Int64:
                    sqlite3_bind_int64(statement, paramIndex, int64)
                case let double as Double:
                    sqlite3_bind_double(statement, paramIndex, double)
                case let bool as Bool:
                    sqlite3_bind_int(statement, paramIndex, bool ? 1 : 0)
                case let date as Date:
                    let timestamp = Int64(date.timeIntervalSince1970)
                    sqlite3_bind_int64(statement, paramIndex, timestamp)
                case is NSNull:
                    sqlite3_bind_null(statement, paramIndex)
                case nil:
                    sqlite3_bind_null(statement, paramIndex)
                default:
                    // Try to convert to string as last resort
                    if let stringValue = String(describing: unwrappedParam) as String? {
                        sqlite3_bind_text(statement, paramIndex, stringValue, -1, SQLITE_TRANSIENT)
                    } else {
                        throw DatabaseError.invalidParameter("Unsupported parameter type: \(type(of: unwrappedParam))")
                    }
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
    }
    
    func executeUpdate(_ query: String, params: [Any] = []) throws {
        try connection.performSync {
            var statement: OpaquePointer?
        
        do {
            statement = try connection.prepareStatement(query)
            defer { connection.finalizeStatement(statement) }
            
            // Bind parameters with better optional handling
            for (index, param) in params.enumerated() {
                let paramIndex = Int32(index + 1)
                
                // Handle wrapped optionals
                let unwrappedParam: Any
                if let optionalParam = param as? Any? {
                    if let value = optionalParam {
                        unwrappedParam = value
                    } else {
                        sqlite3_bind_null(statement, paramIndex)
                        continue
                    }
                } else {
                    unwrappedParam = param
                }
                
                switch unwrappedParam {
                case let string as String:
                    sqlite3_bind_text(statement, paramIndex, string, -1, SQLITE_TRANSIENT)
                case let int as Int:
                    sqlite3_bind_int64(statement, paramIndex, Int64(int))
                case let int64 as Int64:
                    sqlite3_bind_int64(statement, paramIndex, int64)
                case let double as Double:
                    sqlite3_bind_double(statement, paramIndex, double)
                case let bool as Bool:
                    sqlite3_bind_int(statement, paramIndex, bool ? 1 : 0)
                case let date as Date:
                    let timestamp = Int64(date.timeIntervalSince1970)
                    sqlite3_bind_int64(statement, paramIndex, timestamp)
                case is NSNull:
                    sqlite3_bind_null(statement, paramIndex)
                case nil:
                    sqlite3_bind_null(statement, paramIndex)
                default:
                    // Try to convert to string as last resort
                    if let stringValue = String(describing: unwrappedParam) as String? {
                        sqlite3_bind_text(statement, paramIndex, stringValue, -1, SQLITE_TRANSIENT)
                    } else {
                        throw DatabaseError.invalidParameter("Unsupported parameter type: \(type(of: unwrappedParam))")
                    }
                }
            }
            
            let result = sqlite3_step(statement)
            if result != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(connection.getDatabasePointer()))
                let errorCode = sqlite3_errcode(connection.getDatabasePointer())
                throw DatabaseError.queryFailed("SQLite error \(errorCode): \(errorMessage) - Query: \(query)")
            }
        } catch {
            if let dbError = error as? DatabaseError {
                throw dbError
            } else {
                throw DatabaseError.queryFailed("Failed to execute update: \(error.localizedDescription)")
            }
        }
        }
    }
    
    func mapRow(_ row: [String: Any]) throws -> T {
        fatalError("mapRow must be implemented by subclasses")
    }
}
