import Foundation

/// Focus session state enum matching the specification
public enum FocusState: String, Codable, Sendable {
    case preparing
    case running
    case paused
    case completed
    case cancelled
}

/// Timestamp-based resilient focus session domain state
public struct FocusSessionState: Codable, Sendable {
    public var state: FocusState
    public var selectedTask: TaskItem?
    public var configuredDuration: FocusDuration
    
    /// Wall-clock timestamp when the session was started
    public var startTime: Date?
    
    /// Wall-clock timestamp when current pause began (if currently paused)
    public var pauseStartTime: Date?
    
    /// Total duration spent paused prior to the current pause
    public var totalPausedSeconds: TimeInterval
    
    /// Wall-clock timestamp when the session ended (completed or cancelled)
    public var endTime: Date?
    
    public init(
        state: FocusState = .preparing,
        selectedTask: TaskItem? = nil,
        configuredDuration: FocusDuration = .unlimited,
        startTime: Date? = nil,
        pauseStartTime: Date? = nil,
        totalPausedSeconds: TimeInterval = 0,
        endTime: Date? = nil
    ) {
        self.state = state
        self.selectedTask = selectedTask
        self.configuredDuration = configuredDuration
        self.startTime = startTime
        self.pauseStartTime = pauseStartTime
        self.totalPausedSeconds = totalPausedSeconds
        self.endTime = endTime
    }
    
    // MARK: - State Transitions
    
    public mutating func start(task: TaskItem?, duration: FocusDuration, at date: Date = Date()) {
        self.state = .running
        self.selectedTask = task
        self.configuredDuration = duration
        self.startTime = date
        self.pauseStartTime = nil
        self.totalPausedSeconds = 0
        self.endTime = nil
    }
    
    public mutating func pause(at date: Date = Date()) {
        guard state == .running else { return }
        self.state = .paused
        self.pauseStartTime = date
    }
    
    public mutating func resume(at date: Date = Date()) {
        guard state == .paused, let pauseStart = pauseStartTime else { return }
        self.totalPausedSeconds += date.timeIntervalSince(pauseStart)
        self.pauseStartTime = nil
        self.state = .running
    }
    
    public mutating func complete(at date: Date = Date()) {
        if state == .paused, let pauseStart = pauseStartTime {
            self.totalPausedSeconds += date.timeIntervalSince(pauseStart)
            self.pauseStartTime = nil
        }
        self.endTime = date
        self.state = .completed
    }
    
    public mutating func cancel(at date: Date = Date()) {
        if state == .paused, let pauseStart = pauseStartTime {
            self.totalPausedSeconds += date.timeIntervalSince(pauseStart)
            self.pauseStartTime = nil
        }
        self.endTime = date
        self.state = .cancelled
    }
    
    public mutating func reset() {
        self.state = .preparing
        self.startTime = nil
        self.pauseStartTime = nil
        self.totalPausedSeconds = 0
        self.endTime = nil
    }
    
    // MARK: - Deterministic Timestamp Calculations
    
    /// Returns total active focus time in seconds at the given reference date
    public func elapsedSeconds(at referenceDate: Date = Date()) -> TimeInterval {
        guard let start = startTime else { return 0 }
        
        let targetEnd: Date
        if let endTime {
            targetEnd = endTime
        } else if state == .paused, let pauseStart = pauseStartTime {
            targetEnd = pauseStart
        } else {
            targetEnd = referenceDate
        }
        
        let totalElapsed = targetEnd.timeIntervalSince(start)
        let activeSeconds = max(0, totalElapsed - totalPausedSeconds)
        return activeSeconds
    }
    
    /// Returns remaining seconds for fixed duration sessions, or nil for unlimited
    public func remainingSeconds(at referenceDate: Date = Date()) -> TimeInterval? {
        guard !configuredDuration.isUnlimited, let totalSeconds = configuredDuration.totalSeconds else { return nil }
        let total = TimeInterval(totalSeconds)
        let elapsed = elapsedSeconds(at: referenceDate)
        return max(0, total - elapsed)
    }

    /// Progress ratio from 0.0 to 1.0
    public func progress(at referenceDate: Date = Date()) -> Double {
        if configuredDuration.isUnlimited {
            // For unlimited, loop every 60 minutes for visual rhythm
            let elapsed = elapsedSeconds(at: referenceDate)
            let hourCycle = elapsed.truncatingRemainder(dividingBy: 3600)
            return hourCycle / 3600.0
        }
        guard let totalSeconds = configuredDuration.totalSeconds else { return 0.0 }
        let total = Double(totalSeconds)
        guard total > 0 else { return 0.0 }
        let elapsed = Double(elapsedSeconds(at: referenceDate))
        return min(1.0, max(0.0, elapsed / total))
    }
    
    /// Formatted timer string (e.g. "42:18" or "01:23:45")
    public func formattedTimer(at referenceDate: Date = Date()) -> String {
        let displaySeconds: Int
        if configuredDuration.isUnlimited {
            displaySeconds = Int(elapsedSeconds(at: referenceDate))
        } else {
            displaySeconds = Int(remainingSeconds(at: referenceDate) ?? 0)
        }
        
        let hours = displaySeconds / 3600
        let minutes = (displaySeconds % 3600) / 60
        let seconds = displaySeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
