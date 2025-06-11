import Foundation

struct PomodoroSession: Codable, Identifiable {
    let id: UUID
    let userId: String?
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval
    let type: SessionType
    let completed: Bool
    let notes: String?
    
    enum SessionType: String, Codable {
        case focus
        case shortBreak
        case longBreak
    }
    
    init(id: UUID = UUID(),
         userId: String? = nil,
         startTime: Date = Date(),
         endTime: Date? = nil,
         duration: TimeInterval,
         type: SessionType,
         completed: Bool = false,
         notes: String? = nil) {
        self.id = id
        self.userId = userId
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.type = type
        self.completed = completed
        self.notes = notes
    }
    
    var isCompleted: Bool {
        return completed && endTime != nil
    }
    
    var actualDuration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        }
        return duration
    }
} 