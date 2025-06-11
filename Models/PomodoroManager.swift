import Foundation
import Combine

class PomodoroManager: ObservableObject {
    static let shared = PomodoroManager()
    
    // Published properties for UI updates
    @Published private(set) var currentSession: PomodoroSession?
    @Published private(set) var timeRemaining: TimeInterval = 0
    @Published private(set) var isRunning = false
    @Published private(set) var isPaused = false
    @Published private(set) var currentSessionType: PomodoroSession.SessionType = .focus
    @Published private(set) var completedSessionsInCurrentCycle = 0
    @Published private(set) var progress: Double = 0
    
    // Timer and state management
    private var timer: Timer?
    private let databaseManager = DatabaseManager.shared
    private let statsManager = StatsManager()
    private var settings: Settings { databaseManager.loadSettings() }
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe settings changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.handleSettingsChange()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func startSession() {
        guard !isRunning else { return }
        
        let sessionType: PomodoroSession.SessionType
        let duration: TimeInterval
        
        if currentSession == nil {
            sessionType = .focus
            duration = settings.focusDuration
        } else {
            switch currentSessionType {
            case .focus:
                if completedSessionsInCurrentCycle >= settings.sessionsUntilLongBreak - 1 {
                    sessionType = .longBreak
                    duration = settings.longBreakDuration
                } else {
                    sessionType = .shortBreak
                    duration = settings.shortBreakDuration
                }
            case .shortBreak, .longBreak:
                sessionType = .focus
                duration = settings.focusDuration
            }
        }
        
        let session = PomodoroSession(
            duration: duration,
            type: sessionType
        )
        
        currentSession = session
        currentSessionType = sessionType
        timeRemaining = duration
        isRunning = true
        isPaused = false
        progress = 0
        
        if databaseManager.addSession(session) {
            if settings.preventScreenSleep && sessionType == .focus {
                // TODO: Implement screen sleep prevention
            }
            startTimer()
        }
    }
    
    func pauseSession() {
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    func resumeSession() {
        guard let session = currentSession, !isRunning else { return }
        isRunning = true
        isPaused = false
        startTimer()
    }
    
    func skipSession() {
        endCurrentSession(completed: false)
    }
    
    func resetSession() {
        guard let session = currentSession else { return }
        timeRemaining = session.duration
        progress = 0
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        guard timeRemaining > 0 else {
            endCurrentSession(completed: true)
            return
        }
        
        timeRemaining -= 1
        updateProgress()
    }
    
    private func updateProgress() {
        guard let session = currentSession else { return }
        progress = 1 - (timeRemaining / session.duration)
    }
    
    private func endCurrentSession(completed: Bool) {
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        session.completed = completed
        
        if databaseManager.updateSession(session) {
            if completed {
                statsManager.completeSession(
                    sessionId: session.id.uuidString,
                    mode: session.type == .focus ? .focus : .break,
                    duration: Int(session.duration),
                    completed: completed
                )
                sendNotification(for: session)
            }
            
            if session.type == .focus && completed {
                completedSessionsInCurrentCycle += 1
            } else if session.type == .longBreak {
                completedSessionsInCurrentCycle = 0
            }
            
            currentSession = nil
            isRunning = false
            isPaused = false
            timer?.invalidate()
            timer = nil
            
            if settings.autoStartBreaks && session.type == .focus {
                startSession()
            } else if settings.autoStartPomodoros && (session.type == .shortBreak || session.type == .longBreak) {
                startSession()
            }
        }
    }
    
    private func sendNotification(for session: PomodoroSession) {
        guard settings.notificationsEnabled else { return }
        
        // TODO: Implement notification sending
    }
    
    private func handleSettingsChange() {
        // Handle settings changes
        if let session = currentSession {
            switch session.type {
            case .focus:
                timeRemaining = settings.focusDuration
            case .shortBreak:
                timeRemaining = settings.shortBreakDuration
            case .longBreak:
                timeRemaining = settings.longBreakDuration
            }
        }
    }
} 