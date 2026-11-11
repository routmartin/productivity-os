import Foundation

/// Shared contract between the host app and the Focus widget extension.
///
/// A widget extension runs in its own process and cannot read the app's
/// `AuthSession`, Keychain, or caches. The app writes a small, display-ready
/// snapshot into the App Group container after each fetch and asks WidgetKit
/// to reload; the widget only ever reads. No credentials reach the extension.
public enum FocusWidgetShared {
    /// Must match the App Group capability enabled for both targets.
    public static let appGroupID = "group.com.productivityos.app"

    /// `UserDefaults` key holding the encoded `FocusWidgetSnapshot`.
    public static let snapshotKey = "focusWidget.tasksSnapshot"

    /// `WidgetConfiguration.kind` for the Home Screen widget. Shared so the app
    /// can target `WidgetCenter.reloadTimelines(ofKind:)` at it.
    public static let kind = "FocusHomeWidget"
}

/// One display-ready task row for the Home Screen widget. Deliberately flat and
/// free of app types so both targets can compile this file unchanged.
public struct FocusWidgetTask: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let projectName: String?
    public let priority: String?
    public let isCompleted: Bool

    public init(
        id: UUID,
        title: String,
        projectName: String? = nil,
        priority: String? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.projectName = projectName
        self.priority = priority
        self.isCompleted = isCompleted
    }

    /// Static content for the widget gallery / placeholder so the widget looks
    /// alive before the app has synced anything.
    public static let placeholders: [FocusWidgetTask] = [
        FocusWidgetTask(id: UUID(), title: "Finish authentication", projectName: "Productivity OS", priority: "HIGH"),
        FocusWidgetTask(id: UUID(), title: "Review API implementation", projectName: "Productivity OS", priority: "MEDIUM"),
        FocusWidgetTask(id: UUID(), title: "Build task dashboard", projectName: "Productivity OS", priority: "LOW"),
    ]
}

/// The payload the app writes and the widget reads. Versioned implicitly by
/// `updatedAt`; a decode failure is treated as "no data" by the widget.
public struct FocusWidgetSnapshot: Codable, Sendable, Equatable {
    public let tasks: [FocusWidgetTask]
    public let updatedAt: Date

    public static let maxTasks = 3

    public init(tasks: [FocusWidgetTask], updatedAt: Date = Date()) {
        self.tasks = tasks
        self.updatedAt = updatedAt
    }

    // MARK: - Shared storage

    public static var defaults: UserDefaults? {
        get {
            customDefaults ?? UserDefaults(suiteName: FocusWidgetShared.appGroupID)
        }
        set {
            customDefaults = newValue
        }
    }
    private static var customDefaults: UserDefaults?

    /// Reads the latest snapshot, or `nil` when the app has never synced.
    public static func load() -> FocusWidgetSnapshot? {
        guard let data = defaults?.data(forKey: FocusWidgetShared.snapshotKey) else { return nil }
        return try? JSONDecoder().decode(FocusWidgetSnapshot.self, from: data)
    }

    /// Persists the snapshot for the widget to read.
    public func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.defaults?.set(data, forKey: FocusWidgetShared.snapshotKey)
    }

    /// Removes the snapshot (e.g. on logout) so the widget stops showing a
    /// previous user's tasks.
    public static func clear() {
        defaults?.removeObject(forKey: FocusWidgetShared.snapshotKey)
    }
}
