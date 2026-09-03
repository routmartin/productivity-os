import Foundation

/// Task domain service backed by `GET /api/v1/tasks`.
/// V1 list endpoints return plain JSON arrays (no Page envelope).
public struct TaskService: Sendable {
    private let apiClient: APIRequesting
    private let cache: APICache

    public init(apiClient: APIRequesting = APIClient.shared, cache: APICache = .shared) {
        self.apiClient = apiClient
        self.cache = cache
    }

    /// Fetches the active task list.
    ///
    /// Tries `[TaskItem]` first; if the server payload is shaped like
    /// `[TopThreeItem]` (a known schema mismatch from a backend that
    /// returns slot records on `/tasks`), the response is coerced into
    /// `[TaskItem]` so the Today screen keeps working. Other decode errors
    /// propagate as `APIError.decodingError`.
    public func listActiveTasks(page: Int = 0, size: Int = 50) async throws -> [TaskItem] {
        let endpoint = AppEndpoint.listTasks(page: page, size: size)
        let key = CacheKey(endpoint: endpoint)
        if let (data, _) = await cache.get(key: key) {
            return try Self.decodeLoose(data: data)
        }
        let (data, response) = try await apiClient.send(endpoint)
        guard (200...299).contains(response.statusCode) else {
            throw APIError(statusCode: response.statusCode, data: data)
        }
        await cache.set(
            key: key,
            data: data,
            statusCode: response.statusCode,
            ttl: APICache.TTL.activeTasks
        )
        return try Self.decodeLoose(data: data)
    }

    /// PUT /api/v1/tasks/{id}. Mirrors the web Tasks edit flow so the
    /// duration (and other fields) stay in sync between web and iOS.
    public func updateTask(
        id: UUID,
        title: String?,
        description: String?,
        priority: TaskPriority?,
        energy: TaskEnergy?,
        estimatedDurationMinutes: Int?
    ) async throws -> TaskItem {
        let body = UpdateTaskRequestBody(
            title: title,
            description: description,
            priority: priority?.rawValue,
            energy: energy?.rawValue,
            estimatedDurationMinutes: estimatedDurationMinutes
        )
        let encoded = try APIClient.encodedBody(body)
        let endpoint = AppEndpoint.updateTask(id: id, body: encoded)
        let (data, _) = try await apiClient.send(endpoint)
        let updated = try APIClient.jsonDecoder.decode(TaskItem.self, from: data)

        // Mutations invalidate anything that depends on the task list.
        await cache.evict(prefix: "/api/v1/tasks")
        await cache.evict(prefix: "/api/v1/projects")
        await cache.evict(prefix: "/api/v1/daily-top-three")

        return updated
    }

    /// Tries `[TaskItem]` first, then falls back to `[TopThreeItem]`. Kept
    /// private so callers can't depend on the ambiguous shape.
    static func decodeLoose(data: Data) throws -> [TaskItem] {
        let decoder = APIClient.jsonDecoder
        if let items = try? decoder.decode([TaskItem].self, from: data) {
            return items
        }
        if let slots = try? decoder.decode([TopThreeItem].self, from: data) {
            return slots.map { Self.taskItem(from: $0) }
        }

        // Neither shape matched — surface the real `TaskItem` decode error
        // so the next person to hit this can fix the backend.
        throw APIError.decodingError(Self.describeDecodeFailure(of: data, as: [TaskItem].self))
    }

    /// Maps a TopThreeItem-shaped record into a TaskItem for the row UI.
    /// Mirrors `TodayViewModel.taskItem(from:in:)` but without depending
    /// on a parallel `TaskItem` lookup.
    static func taskItem(from slot: TopThreeItem) -> TaskItem {
        TaskItem(
            id: slot.taskId ?? slot.id,
            title: slot.taskTitle ?? "Task",
            priority: slot.priority,
            status: slot.isCompleted ? .completed : .pending,
            projectName: slot.projectName
        )
    }

    private static func describeDecodeFailure<T: Decodable>(of data: Data, as type: T.Type) -> String {
        let decoder = APIClient.jsonDecoder
        do {
            _ = try decoder.decode(T.self, from: data)
            return "Decode failed for an unknown reason"
        } catch let error as DecodingError {
            return Self.describe(error)
        } catch {
            return error.localizedDescription
        }
    }

    private static func describe(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let context):
            let path = Self.path(of: context.codingPath)
            return "Missing key '\(key.stringValue)' at \(path)"
        case .typeMismatch(let type, let context):
            let path = Self.path(of: context.codingPath)
            return "Type mismatch for \(type) at \(path)"
        case .valueNotFound(let type, let context):
            let path = Self.path(of: context.codingPath)
            return "Null \(type) at \(path)"
        case .dataCorrupted(let context):
            return "Corrupted payload: \(context.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }

    private static func path(of codingPath: [CodingKey]) -> String {
        if codingPath.isEmpty { return "<root>" }
        return codingPath.map { $0.intValue.map { "[\($0)]" } ?? ".\($0.stringValue)" }.joined()
    }
}