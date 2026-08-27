import Foundation

/// Comprehensive sample and preview data matching visual references
public enum SampleData {
    public static let mockUser = User(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        email: "rout@productivityos.com",
        name: "Rout",
        avatarUrl: nil,
        createdAt: Date()
    )
    
    public static let taskAuth = TaskItem(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        title: "Finish authentication",
        description: "Implement JWT refresh flow and keychain token storage",
        priority: .high,
        energy: .high,
        estimatedDurationMinutes: 90,
        status: .inProgress,
        projectName: "Productivity OS"
    )
    
    public static let taskApi = TaskItem(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        title: "Review API implementation",
        description: "Audit FocusController and TaskController endpoints",
        priority: .medium,
        energy: .medium,
        estimatedDurationMinutes: 45,
        status: .pending,
        projectName: "Productivity OS"
    )
    
    public static let taskDashboard = TaskItem(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        title: "Build task dashboard",
        description: "Create summary cards and daily completion metrics",
        priority: .low,
        energy: .low,
        estimatedDurationMinutes: 60,
        status: .pending,
        projectName: "Productivity OS"
    )
    
    public static let mockTasks: [TaskItem] = [
        taskAuth,
        taskApi,
        taskDashboard,
        TaskItem(
            id: UUID(),
            title: "Write documentation for iOS foundation",
            description: "Explain architecture, models, and design system",
            priority: .medium,
            energy: .medium,
            estimatedDurationMinutes: 30,
            status: .pending,
            projectName: "Docs"
        )
    ]
    
    public static let mockTopThree: [TopThreeItem] = [
        TopThreeItem(
            id: UUID(),
            taskId: taskAuth.id,
            taskTitle: taskAuth.title,
            position: 1,
            projectName: "Productivity OS",
            priority: .high
        ),
        TopThreeItem(
            id: UUID(),
            taskId: taskApi.id,
            taskTitle: taskApi.title,
            position: 2,
            projectName: "Productivity OS",
            priority: .medium
        ),
        TopThreeItem(
            id: UUID(),
            taskId: taskDashboard.id,
            taskTitle: taskDashboard.title,
            position: 3,
            projectName: "Productivity OS",
            priority: .low
        )
    ]
    
    public static func makeRunningFocusState() -> FocusSessionState {
        var state = FocusSessionState()
        // Started 17 minutes and 42 seconds ago with unlimited mode => 42:18 remaining in Pomodoro or 42:18 elapsed
        state.start(
            task: taskAuth,
            duration: .unlimited,
            at: Date().addingTimeInterval(-2538) // 42 min 18 sec ago
        )
        return state
    }
    
    public static func makePausedFocusState() -> FocusSessionState {
        var state = FocusSessionState()
        state.start(
            task: taskAuth,
            duration: .unlimited,
            at: Date().addingTimeInterval(-2538)
        )
        state.pause(at: Date())
        return state
    }
}
