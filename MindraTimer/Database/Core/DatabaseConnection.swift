import Foundation
import SQLite3

class DatabaseConnection {
    private var db: OpaquePointer?
    private let dbPath: String
    private var isInTransaction = false
    
    init(dbPath: String) {
        self.dbPath = dbPath
    }
    
    func connect() throws {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.connectionFailed(errorMessage)
        }
        
        // Enable foreign keys and WAL mode
        try execute("PRAGMA foreign_keys = ON;")
        try execute("PRAGMA journal_mode = WAL;")
    }
    
    func disconnect() {
        if let db = db {
            sqlite3_close(db)
            self.db = nil
        }
    }
    
    func execute(_ query: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        
        if sqlite3_exec(db, query, nil, nil, &errorMessage) != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMessage)
            throw DatabaseError.queryFailed(error)
        }
    }
    
    func beginTransaction() throws {
        guard !isInTransaction else { return }
        try execute("BEGIN TRANSACTION;")
        isInTransaction = true
    }
    
    func commitTransaction() throws {
        guard isInTransaction else { return }
        try execute("COMMIT;")
        isInTransaction = false
    }
    
    func rollbackTransaction() throws {
        guard isInTransaction else { return }
        try execute("ROLLBACK;")
        isInTransaction = false
    }
    
    func prepareStatement(_ query: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(errorMessage)
        }
        
        return statement
    }
    
    func finalizeStatement(_ statement: OpaquePointer?) {
        if let statement = statement {
            sqlite3_finalize(statement)
        }
    }
    
    func getDatabasePointer() -> OpaquePointer? {
        return db
    }
    
    deinit {
        disconnect()
    }
} 