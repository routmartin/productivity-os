import Foundation

/// User model matching backend API response
public struct User: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let email: String
    public let name: String?
    public let avatarUrl: String?
    public let createdAt: Date?
    
    public init(
        id: UUID = UUID(),
        email: String,
        name: String? = nil,
        avatarUrl: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarUrl = avatarUrl
        self.createdAt = createdAt
    }
    
    public var displayName: String {
        name?.isEmpty == false ? name! : (email.components(separatedBy: "@").first ?? "User")
    }
}
