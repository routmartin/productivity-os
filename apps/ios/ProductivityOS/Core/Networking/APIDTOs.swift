import Foundation

// MARK: - Auth wire contracts (backend: AuthController / auth/dto)

public struct LoginRequestBody: Codable, Sendable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct RegisterRequestBody: Codable, Sendable {
    public let email: String
    public let password: String
    public let timezone: String?

    public init(email: String, password: String, timezone: String? = nil) {
        self.email = email
        self.password = password
        self.timezone = timezone
    }
}

/// Backend `UserResponse` — {id, email, timezone}. No name/avatar fields.
public struct UserDTO: Codable, Sendable {
    public let id: UUID
    public let email: String
    public let timezone: String?
}

/// Backend `LoginResponse` — used by login and refresh.
/// Refresh returns `user: null` (AuthController); the cached profile is kept.
public struct AuthResponse: Decodable, Sendable {
    public let accessToken: String
    public let user: UserDTO?

    public init(accessToken: String, user: UserDTO?) {
        self.accessToken = accessToken
        self.user = user
    }

    public var domainUser: User? {
        guard let dto = user else { return nil }
        return User(id: dto.id, email: dto.email, name: nil, avatarUrl: nil, createdAt: nil)
    }
}

// MARK: - Focus wire contracts (backend: focus/dto)

/// Backend `StartFocusRequest`.
public struct StartFocusRequestBody: Codable, Sendable {
    public let taskId: UUID
    /// `nil` for unlimited sessions (backend field is nullable).
    public let configuredDurationSeconds: Int?
    public let note: String?

    public init(taskId: UUID, configuredDurationSeconds: Int?, note: String? = nil) {
        self.taskId = taskId
        self.configuredDurationSeconds = configuredDurationSeconds
        self.note = note
    }
}

// MARK: - Tasks wire contracts (backend: task/dto)

/// Backend `UpdateTaskRequest` (PUT /api/v1/tasks/{id}). All fields are
/// optional; explicit `nil` clears a nullable field. The backend requires
/// a non-blank `title` when the field is present, but accepts it absent
/// (the iOS edit sheet always sends the current title, so the rule is
/// trivially satisfied).
public struct UpdateTaskRequestBody: Codable, Sendable {
    public let title: String?
    public let description: String?
    public let dueDate: String?
    public let priority: String?
    public let energy: String?
    public let estimatedDurationMinutes: Int?

    public init(
        title: String? = nil,
        description: String? = nil,
        dueDate: String? = nil,
        priority: String? = nil,
        energy: String? = nil,
        estimatedDurationMinutes: Int? = nil
    ) {
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.energy = energy
        self.estimatedDurationMinutes = estimatedDurationMinutes
    }
}
