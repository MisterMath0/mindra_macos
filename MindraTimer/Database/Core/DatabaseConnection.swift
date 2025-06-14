import Foundation
import SQLite3

class DatabaseConnection {
    private var db: OpaquePointer?
    private let dbPath: String
    private var isInTransaction = false
    
    // THREAD SAFETY FIX: Serial queue for all database operations
    private let databaseQueue = DispatchQueue(label: "com.mindratimer.database", qos: .userInitiated)
    
    init(dbPath: String) {
        self.dbPath = dbPath
    }
    
    func connect() throws {
        try performDatabaseOperation {
            if sqlite3_open(dbPath, &db) != SQLITE_OK {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.connectionFailed(errorMessage)
            }
            
            // Enable foreign keys and WAL mode
            try execute("PRAGMA foreign_keys = ON;")
            try execute("PRAGMA journal_mode = WAL;")
            
            // Enable better concurrency settings
            try execute("PRAGMA synchronous = NORMAL;")
            try execute("PRAGMA cache_size = 10000;")
            try execute("PRAGMA temp_store = MEMORY;")
        }
    }
    
    func disconnect() {
        databaseQueue.sync {
            if let db = db {
                sqlite3_close(db)
                self.db = nil
            }
        }
    }
    
    func execute(_ query: String) throws {
        try performDatabaseOperation {
            var errorMessage: UnsafeMutablePointer<CChar>?
            
            if sqlite3_exec(db, query, nil, nil, &errorMessage) != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
                sqlite3_free(errorMessage)
                throw DatabaseError.queryFailed(error)
            }
        }
    }
    
    func beginTransaction() throws {
        try performDatabaseOperation {
            guard !isInTransaction else { return }
            try execute("BEGIN TRANSACTION;")
            isInTransaction = true
        }
    }
    
    func commitTransaction() throws {
        try performDatabaseOperation {
            guard isInTransaction else { return }
            try execute("COMMIT;")
            isInTransaction = false
        }
    }
    
    func rollbackTransaction() throws {
        try performDatabaseOperation {
            guard isInTransaction else { return }
            try execute("ROLLBACK;")
            isInTransaction = false
        }
    }
    
    func prepareStatement(_ query: String) throws -> OpaquePointer? {
        return try performDatabaseOperation {
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.queryFailed(errorMessage)
            }
            
            return statement
        }
    }
    
    func finalizeStatement(_ statement: OpaquePointer?) {
        databaseQueue.sync {
            if let statement = statement {
                sqlite3_finalize(statement)
            }
        }
    }
    
    func getDatabasePointer() -> OpaquePointer? {
        return databaseQueue.sync {
            return db
        }
    }
    
    // THREAD SAFETY: All database operations must go through this method
    private func performDatabaseOperation<T>(_ operation: () throws -> T) throws -> T {
        return try databaseQueue.sync {
            guard db != nil else {
                throw DatabaseError.connectionFailed("Database not connected")
            }
            return try operation()
        }
    }
    
    // Public method for executing operations on the database queue
    func performSync<T>(_ operation: () throws -> T) throws -> T {
        return try performDatabaseOperation(operation)
    }
    
    // Async version for non-throwing operations
    func performAsync(_ operation: @escaping () -> Void) {
        databaseQueue.async {
            operation()
        }
    }
    
    deinit {
        disconnect()
    }
}
