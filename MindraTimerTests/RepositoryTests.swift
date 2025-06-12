import XCTest
@testable import MindraTimer

final class RepositoryTests: XCTestCase {
    var connection: DatabaseConnection!
    var sessionRepository: SessionRepository!
    var achievementRepository: AchievementRepository!
    var settingsRepository: SettingsRepository!
    
    override func setUp() {
        super.setUp()
        // Create an in-memory database for testing
        connection = try! DatabaseConnection(path: ":memory:")
        sessionRepository = SessionRepository(connection: connection)
        achievementRepository = AchievementRepository(connection: connection)
        settingsRepository = SettingsRepository(connection: connection)
        
        // Create tables
        try! connection.executeUpdate("""
            CREATE TABLE IF NOT EXISTS focus_sessions (
                id TEXT PRIMARY KEY,
                started_at INTEGER NOT NULL,
                ended_at INTEGER,
                duration INTEGER NOT NULL,
                completed INTEGER NOT NULL,
                mode TEXT NOT NULL,
                notes TEXT
            )
        """)
        
        try! connection.executeUpdate("""
            CREATE TABLE IF NOT EXISTS achievements (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT NOT NULL,
                icon TEXT NOT NULL,
                type TEXT NOT NULL,
                progress REAL NOT NULL,
                target REAL NOT NULL,
                unlocked INTEGER NOT NULL,
                unlocked_date INTEGER
            )
        """)
        
        try! connection.executeUpdate("""
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value BLOB NOT NULL
            )
        """)
    }
    
    override func tearDown() {
        connection = nil
        sessionRepository = nil
        achievementRepository = nil
        settingsRepository = nil
        super.tearDown()
    }
    
    func testSessionRepository() throws {
        // Create a test session
        let session = FocusSession(
            startedAt: Date(),
            duration: 3600,
            completed: false,
            mode: .focus
        )
        
        // Test saving session
        try sessionRepository.create(session)
        
        // Test retrieving sessions
        let sessions = try sessionRepository.getSessions(for: .all)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].id, session.id)
        XCTAssertEqual(sessions[0].mode, .focus)
        
        // Test updating session completion
        try sessionRepository.updateSessionCompletion(session.id, completed: true)
        let updatedSessions = try sessionRepository.getSessions(for: .all)
        XCTAssertTrue(updatedSessions[0].completed)
    }
    
    func testAchievementRepository() throws {
        // Create a test achievement
        let achievement = Achievement(
            title: "Test Achievement",
            description: "Test Description",
            icon: "star.fill",
            type: .sessionsCompleted,
            progress: 1,
            target: 10
        )
        
        // Test saving achievement
        try achievementRepository.create(achievement)
        
        // Test retrieving achievements
        let achievements = try achievementRepository.getAllAchievements()
        XCTAssertEqual(achievements.count, 1)
        XCTAssertEqual(achievements[0].title, achievement.title)
        XCTAssertEqual(achievements[0].type, .sessionsCompleted)
    }
    
    func testSettingsRepository() throws {
        // Create test settings
        let settings = AppSettings.default
        
        // Test saving settings
        try settingsRepository.setValue(settings, for: "app_settings")
        
        // Test retrieving settings
        let retrievedSettings: AppSettings? = try settingsRepository.getValue(for: "app_settings", type: AppSettings.self)
        XCTAssertNotNil(retrievedSettings)
        XCTAssertEqual(retrievedSettings?.theme, settings.theme)
        XCTAssertEqual(retrievedSettings?.soundEnabled, settings.soundEnabled)
    }
} 