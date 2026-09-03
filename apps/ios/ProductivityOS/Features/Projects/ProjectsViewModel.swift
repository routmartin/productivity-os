import Foundation
import Observation

/// Caches the user's projects and resolves a `TaskItem` to its real project
/// name. Priority: API-provided `projectName` -> lookup by `projectId` -> nil.
@Observable
public final class ProjectsViewModel {
    public enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    public private(set) var loadState: LoadState = .idle

    private(set) public var projectsById: [UUID: Project] = [:]

    private let projectService: ProjectService

    public init(projectService: ProjectService = ProjectService()) {
        self.projectService = projectService
    }

    public func loadProjects() async {
        loadState = .loading
        do {
            let projects = try await projectService.listProjects()
            projectsById = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    /// Bypasses the shared `APICache` for the projects list.
    public func refresh() async {
        await APICache.shared.evict(prefix: "/api/v1/projects")
        await loadProjects()
    }

    /// Resolves a task's project name. Returns nil if the task has no project
    /// or the project cannot be located.
    public func projectName(for task: TaskItem) -> String? {
        if let name = task.projectName, !name.isEmpty {
            return name
        }
        if let projectId = task.projectId {
            return projectsById[projectId]?.title
        }
        return nil
    }
}
