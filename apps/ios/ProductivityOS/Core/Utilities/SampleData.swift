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

    // MARK: - Goals & Projects sample data (Goals feature previews)

    public static let mockGoals: [Goal] = {
        let now = Date()
        let calendar = Calendar.current
        let goal1Deadline = calendar.date(byAdding: .day, value: 60, to: now)
        let goal2Deadline = calendar.date(byAdding: .day, value: 200, to: now)
        let goal3Deadline = calendar.date(byAdding: .day, value: 14, to: now)
        return [
            Goal(
                id: UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!,
                userId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                title: "Build the best version of Productivity OS",
                description: "Create a world-class productivity app that helps people focus, plan, and achieve meaningful progress every day.",
                status: .active,
                deadline: goal1Deadline,
                completedAt: nil,
                createdAt: now,
                updatedAt: now
            ),
            Goal(
                id: UUID(uuidString: "A2222222-2222-2222-2222-222222222222")!,
                userId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                title: "Financial Freedom",
                description: "Build a sustainable income through focused, deep work on the things that compound.",
                status: .active,
                deadline: goal2Deadline,
                completedAt: nil,
                createdAt: now,
                updatedAt: now
            ),
            Goal(
                id: UUID(uuidString: "A3333333-3333-3333-3333-333333333333")!,
                userId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                title: "Health & Wellness",
                description: "Daily habits that compound into long-term energy and resilience.",
                status: .draft,
                deadline: goal3Deadline,
                completedAt: nil,
                createdAt: now,
                updatedAt: now
            ),
        ]
    }()

    public static let mockProjectsForGoals: [Project] = {
        let now = Date()
        let calendar = Calendar.current
        let goal1 = UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!
        let goal2 = UUID(uuidString: "A2222222-2222-2222-2222-222222222222")!
        let goal3 = UUID(uuidString: "A3333333-3333-3333-3333-333333333333")!
        return [
            Project(
                id: UUID(uuidString: "B1111111-1111-1111-1111-111111111111")!,
                userId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                title: "iOS App",
                description: "Ship the iOS read-only experience for Goals & Projects.",
                goalId: goal1,
                status: .active,
                deadline: calendar.date(byAdding: .day, value: 45, to: now),
                completedAt: nil,
                createdAt: now,
                updatedAt: now
            ),
            Project(
                id: UUID(uuidString: "B2222222-2222-2222-2222-222222222222")!,
                userId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                title: "Backend & API",
                description: "Spring Boot endpoints backing the iOS Goals & Projects surface.",
                goalId: goal1,
                status: .active,
                deadline: calendar.date(byAdding: .day, value: 60, to: now),
                completedAt: nil,
                createdAt: now,
                updatedAt: now
            ),
            Project(
                id: UUID(uuidString: "B3333333-3333-3333-3333-333333333333")!,
                userId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                title: "Marketing & Brand",
                description: "Brand voice, public presence, and launch materials.",
                goalId: goal1,
                status: .draft,
                deadline: calendar.date(byAdding: .day, value: 90, to: now),
                completedAt: nil,
                createdAt: now,
                updatedAt: now
            ),
            Project(
                id: UUID(uuidString: "B4444444-4444-4444-4444-444444444444")!,
                userId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                title: "Investment Pipeline",
                description: "Identify and nurture long-horizon investment opportunities.",
                goalId: goal2,
                status: .active,
                deadline: calendar.date(byAdding: .day, value: 180, to: now),
                completedAt: nil,
                createdAt: now,
                updatedAt: now
            ),
            Project(
                id: UUID(uuidString: "B5555555-5555-5555-5555-555555555555")!,
                userId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                title: "Daily Movement",
                description: "Establish a sustainable daily movement habit.",
                goalId: goal3,
                status: .draft,
                deadline: calendar.date(byAdding: .day, value: 14, to: now),
                completedAt: nil,
                createdAt: now,
                updatedAt: now
            ),
        ]
    }()

    /// Pre-built per-project task lists used to compute progress in previews.
    public static let mockProjectTasks: [UUID: [TaskItem]] = {
        let now = Date()
        func task(_ title: String, status: TaskStatus) -> TaskItem {
            TaskItem(
                id: UUID(),
                title: title,
                priority: .medium,
                status: status,
                projectId: nil,
                projectName: nil,
                createdAt: now,
                updatedAt: now
            )
        }
        return [
            UUID(uuidString: "B1111111-1111-1111-1111-111111111111")!: [
                task("Implement navigation", status: .completed),
                task("Polish progress ring", status: .completed),
                task("Wire up Goals tab", status: .inProgress),
                task("VoiceOver pass", status: .pending),
            ],
            UUID(uuidString: "B2222222-2222-2222-2222-222222222222")!: [
                task("Refactor /goals controller", status: .completed),
                task("Add /projects/{id}/tasks", status: .completed),
                task("Project task counts", status: .inProgress),
                task("Cache invalidation", status: .pending),
                task("Rate limit hardening", status: .pending),
            ],
            UUID(uuidString: "B3333333-3333-3333-3333-333333333333")!: [
                task("Brand voice doc", status: .pending),
            ],
            UUID(uuidString: "B4444444-4444-4444-4444-444444444444")!: [
                task("Pipeline intake form", status: .completed),
                task("Weekly review cadence", status: .inProgress),
            ],
            UUID(uuidString: "B5555555-5555-5555-5555-555555555555")!: [],
        ]
    }()
}
