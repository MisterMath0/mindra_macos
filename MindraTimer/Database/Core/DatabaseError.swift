import Foundation

enum DatabaseError: Error {
    case connectionFailed(String)
    case queryFailed(String)
    case invalidData(String)
    case notFound(String)
    case constraintViolation(String)
    case transactionFailed(String)
    case invalidParameter(String)
    
    var localizedDescription: String {
        switch self {
        case .connectionFailed(let message):
            return "Database connection failed: \(message)"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .constraintViolation(let message):
            return "Constraint violation: \(message)"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        case .invalidParameter(let message):
            return "Invalid parameter: \(message)"
        }
    }
} 