import Foundation
import WidgetKit
#if canImport(FocusWidgetShared)
@_exported import FocusWidgetShared
#endif

/// Bridges the app's fetched tasks into the shared widget snapshot.
///
/// The Home Screen widget cannot read the app's authentication, caches, or
/// Keychain. This is the single place that decides what it sees and when it
/// refreshes, so the widget stays a pure reader of `FocusWidgetSnapshot`.
public enum FocusWidgetPublisher {
    /// Maps and filters tasks for the widget:
    /// - excludes completed, cancelled, or deleted tasks
    /// - sorts newest first
    /// - caps to `FocusWidgetSnapshot.maxTasks`
    public static func mapAndFilter(_ tasks: [TaskItem]) -> [FocusWidgetTask] {
        tasks
            .filter { !$0.isCompleted && $0.status != .cancelled && $0.deletedAt == nil }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            .prefix(FocusWidgetSnapshot.maxTasks)
            .map {
                FocusWidgetTask(
                    id: $0.id,
                    title: $0.title,
                    projectName: $0.projectName,
                    priority: $0.priority?.rawValue,
                    isCompleted: $0.isCompleted
                )
            }
    }

    /// Persists the latest active tasks (newest first) and asks WidgetKit to
    /// refresh the Home Screen widget.
    public static func publish(_ tasks: [TaskItem]) {
        let latest = mapAndFilter(tasks)
        FocusWidgetSnapshot(tasks: Array(latest)).save()
        WidgetCenter.shared.reloadTimelines(ofKind: FocusWidgetShared.kind)
    }

    /// Clears the snapshot (logout) so the widget never shows a previous
    /// user's tasks.
    public static func clear() {
        FocusWidgetSnapshot.clear()
        WidgetCenter.shared.reloadTimelines(ofKind: FocusWidgetShared.kind)
    }
}
