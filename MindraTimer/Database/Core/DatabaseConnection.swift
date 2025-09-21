import Foundation
import SQLite3

class DatabaseConnection {
    private var db: OpaquePointer?
    private let dbPath: String
    private var isInTransaction = false
    private var isConnected = false
    
    // Serial queue for all database operations
    private let databaseQueue = DispatchQueue(label: "com.mindratimer.database", qos: .userInitiated)
    
    init(dbPath: String) {
        self.dbPath = dbPath
    }
    
    func connect() throws {
        try performSync {
            if sqlite3_open(dbPath, &db) != SQLITE_OK {
                let errorMessage = db != nil ? String(cString: sqlite3_errmsg(db)) : "Failed to open database"
                throw DatabaseError.connectionFailed(errorMessage)
            }
            
            isConnected = true
            
            var errorMessage: UnsafeMutablePointer<CChar>?
            
            if sqlite3_exec(db, "PRAGMA foreign_keys = ON;", nil, nil, &errorMessage) != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Failed to enable foreign keys"
                sqlite3_free(errorMessage)
                throw DatabaseError.connectionFailed(error)
            }
            
            if sqlite3_exec(db, "PRAGMA journal_mode = WAL;", nil, nil, &errorMessage) != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Failed to enable WAL mode"
                sqlite3_free(errorMessage)
                throw DatabaseError.connectionFailed(error)
            }
            
            if sqlite3_exec(db, "PRAGMA synchronous = NORMAL;", nil, nil, &errorMessage) != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Failed to set synchronous mode"
                sqlite3_free(errorMessage)
                throw DatabaseError.connectionFailed(error)
            }
            
            if sqlite3_exec(db, "PRAGMA cache_size = 10000;", nil, nil, &errorMessage) != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Failed to set cache size"
                sqlite3_free(errorMessage)
                throw DatabaseError.connectionFailed(error)
            }
            
            if sqlite3_exec(db, "PRAGMA temp_store = MEMORY;", nil, nil, &errorMessage) != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Failed to set temp store"
                sqlite3_free(errorMessage)
                throw DatabaseError.connectionFailed(error)
            }
        }
    }
    
    func disconnect() {
        databaseQueue.sync {
            if let db = db {
                sqlite3_close(db)
                self.db = nil
                self.isConnected = false
                self.isInTransaction = false
            }
        }
    }
    
    func execute(_ query: String) throws {
        try performSync {
            var errorMessage: UnsafeMutablePointer<CChar>?
            guard isConnected && db != nil else {
                throw DatabaseError.connectionFailed("Database not connected")
            }
            if sqlite3_exec(db, query, nil, nil, &errorMessage) != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
                let code = sqlite3_errcode(db)
                if let msg = errorMessage { sqlite3_free(msg) }
                throw DatabaseError.queryFailed("SQLite error \(code): \(error) - Query: \(query)")
            }
        }
    }
    
    func beginTransaction() throws {
        try performSync {
            guard isConnected && db != nil else {
                throw DatabaseError.connectionFailed("Database not connected")
            }
            guard !isInTransaction else { return }
            var errorMessage: UnsafeMutablePointer<CChar>?
            if sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, &errorMessage) != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
                let code = sqlite3_errcode(db)
                if let msg = errorMessage { sqlite3_free(msg) }
                throw DatabaseError.transactionFailed("SQLite error \(code): \(error)")
            }
            isInTransaction = true
        }
    }
    
    func commitTransaction() throws {
        try performSync {
            guard isConnected && db != nil else {
                throw DatabaseError.connectionFailed("Database not connected")
            }
            guard isInTransaction else { return }
            var errorMessage: UnsafeMutablePointer<CChar>?
            if sqlite3_exec(db, "COMMIT;", nil, nil, &errorMessage) != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
                let code = sqlite3_errcode(db)
                if let msg = errorMessage { sqlite3_free(msg) }
                throw DatabaseError.transactionFailed("SQLite error \(code): \(error)")
            }
            isInTransaction = false
        }
    }
    
    func rollbackTransaction() throws {
        try performSync {
            guard isConnected && db != nil else {
                throw DatabaseError.connectionFailed("Database not connected")
            }
            guard isInTransaction else { return }
            var errorMessage: UnsafeMutablePointer<CChar>?
            if sqlite3_exec(db, "ROLLBACK;", nil, nil, &errorMessage) != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
                let code = sqlite3_errcode(db)
                if let msg = errorMessage { sqlite3_free(msg) }
                throw DatabaseError.transactionFailed("SQLite error \(code): \(error)")
            }
            isInTransaction = false
        }
    }
    
    // IMPORTANT: These helpers must be called only from within performSync blocks.
    // They do NOT call performSync themselves to avoid deadlocks.
    func prepareStatement(_ query: String) throws -> OpaquePointer? {
        guard isConnected && db != nil else {
            throw DatabaseError.connectionFailed("Database not connected")
        }
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            let code = sqlite3_errcode(db)
            throw DatabaseError.queryFailed("SQLite error \(code): \(errorMessage) - Query: \(query)")
        }
        return statement
    }
    
    func finalizeStatement(_ statement: OpaquePointer?) {
        if let statement = statement {
            sqlite3_finalize(statement)
        }
    }
    
    func getDatabasePointer() -> OpaquePointer? {
        // Exposed for debugging, but do not use directly; always go through the queue.
        return db
    }
    
    // Public method for executing operations on the database queue
    func performSync<T>(_ operation: () throws -> T) throws -> T {
        var result: Result<T, Error>!
        databaseQueue.sync {
            do {
                let value = try operation()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
        }
        switch result! {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    func performAsync(_ operation: @escaping () -> Void) {
        databaseQueue.async {
            guard self.isConnected else { return }
            operation()
        }
    }
    
    deinit {
        disconnect()
    }
}
