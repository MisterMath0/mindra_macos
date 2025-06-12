//
//  DatabaseTester.swift
//  MindraTimer
//
//  Created by Guy Mathieu Foko on 12.06.25.
//

import Foundation

class DatabaseTester {
    static func runComprehensiveTest() {
        print("🧪 Starting Comprehensive Database Test")
        print("=" * 50)
        
        let manager = DatabaseManager.shared
        
        // Test 1: Basic Info
        print("\n📊 Database Debug Info:")
        print(manager.getDebugInfo())
        
        // Test 2: Basic Operations
        print("\n🔧 Basic Operations Test:")
        print(manager.testDatabase())
        
        // Test 3: Real World Scenario
        print("\n🌍 Real World Scenario Test:")
        testRealWorldScenario(manager)
        
        // Test 4: Settings Test
        print("\n⚙️ Settings Test:")
        testSettings(manager)
        
        // Test 5: Achievement Test
        print("\n🏆 Achievement Test:")
        testAchievements(manager)
        
        print("\n✅ Comprehensive Database Test Completed!")
        print("=" * 50)
    }
    
    private static func testRealWorldScenario(_ manager: DatabaseManager) {
        // Create a realistic focus session
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-1800), // 30 minutes ago
            endedAt: Date(),
            duration: 1500, // 25 minutes
            completed: true,
            mode: .focus,
            notes: "Worked on iOS app database refactoring"
        )
        
        // Test saving
        let saved = manager.addSession(session)
        print("Session save: \(saved ? "✅" : "❌")")
        
        // Test retrieval
        let sessions = manager.getSessions(for: .day)
        print("Sessions retrieved: \(sessions.count)")
        
        // Test stats calculation
        let summary = manager.calculateSummary(for: sessions)
        print("Stats calculated - Total focus time: \(summary.formattedTotalFocusTime)")
        
        // Test chart data
        let chartData = manager.generateChartData(for: sessions, period: .week)
        print("Chart data generated: \(chartData.count) data points")
        
        // Clean up test data
        if let testSession = sessions.first(where: { $0.notes?.contains("database refactoring") == true }) {
            // Note: We'll keep this for demonstration
            print("Test session ID: \(testSession.id)")
        }
    }
    
    private static func testSettings(_ manager: DatabaseManager) {
        // Test setting a simple value
        manager.setSetting(key: "test_setting", value: "test_value")
        let retrievedValue = manager.getSetting(key: "test_setting", type: String.self, defaultValue: "default")
        print("String setting test: \(retrievedValue == "test_value" ? "✅" : "❌")")
        
        // Test setting a complex object
        let testConfig = SessionConfiguration.default
        manager.setSetting(key: "test_config", value: testConfig)
        let retrievedConfig = manager.getSetting(key: "test_config", type: SessionConfiguration.self, defaultValue: SessionConfiguration.default)
        print("Complex object setting test: \(retrievedConfig.focusDuration == testConfig.focusDuration ? "✅" : "❌")")
        
        // Test default values
        let missingValue = manager.getSetting(key: "nonexistent_key", type: String.self, defaultValue: "default_value")
        print("Default value test: \(missingValue == "default_value" ? "✅" : "❌")")
    }
    
    private static func testAchievements(_ manager: DatabaseManager) {
        // Create test achievement
        let achievement = Achievement(
            title: "Database Tester",
            description: "Successfully tested the database system",
            icon: "🧪",
            type: .totalFocusTime,
            progress: 50,
            target: 100
        )
        
        // Test saving achievement
        let saved = manager.addAchievement(achievement)
        print("Achievement save: \(saved ? "✅" : "❌")")
        
        // Test retrieving achievements
        let achievements = manager.getAchievements()
        print("Achievements retrieved: \(achievements.count)")
        
        // Test updating achievement
        var updatedAchievement = achievement
        updatedAchievement.progress = 100
        updatedAchievement.unlocked = true
        updatedAchievement.unlockedDate = Date()
        
        let updated = manager.updateAchievement(updatedAchievement)
        print("Achievement update: \(updated ? "✅" : "❌")")
        
        // Verify update
        let finalAchievements = manager.getAchievements()
        if let testAchievement = finalAchievements.first(where: { $0.title == "Database Tester" }) {
            print("Achievement progress updated: \(testAchievement.progress == 100 ? "✅" : "❌")")
            print("Achievement unlocked: \(testAchievement.unlocked ? "✅" : "❌")")
        }
    }
}

// Extension to make string repetition easier
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}
