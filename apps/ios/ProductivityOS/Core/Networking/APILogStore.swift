import Foundation
import SwiftUI

/// In-memory + on-disk ring buffer for developer API request logs.
///
/// Each `Entry` is the full lifecycle of one HTTP call (request → response or
/// error). The store is the single source of truth for the DevTools network
/// tab; `NetworkLogger` is its only writer in production code.
///
/// Persistence: the store writes to a JSON file under
/// `Library/Caches/devtools/api-log.json` so logs survive relaunches. The
/// file is intentionally capped (oldest entries trimmed on save) and cleared
/// with the user-facing Clear button. Sensitive payloads (Authorization
/// header, password, access/refresh tokens) are redacted at insert time by
/// `NetworkLogger`, so the on-disk file does not contain credentials.
public final class APILogStore: ObservableObject {
    public static let shared = APILogStore()

    // MARK: - Public types

    public enum Phase: String, Codable, Sendable {
        case pending
        case success
        case failure
    }

    public struct Entry: Identifiable, Codable, Sendable, Equatable {
        public let id: UUID
        public let startedAt: Date
        public let method: String
        public let path: String
        public let host: String
        public let query: String?
        public let requestHeaders: [String: String]
        public let requestBody: BodyValue?
        public var endedAt: Date?
        public var durationMs: Int?
        public var phase: Phase
        public var statusCode: Int?
        public var responseHeaders: [String: String]?
        public var responseBody: BodyValue?
        public var errorDescription: String?

        public init(
            id: UUID = UUID(),
            startedAt: Date,
            method: String,
            path: String,
            host: String,
            query: String?,
            requestHeaders: [String: String],
            requestBody: BodyValue?
        ) {
            self.id = id
            self.startedAt = startedAt
            self.method = method
            self.path = path
            self.host = host
            self.query = query
            self.requestHeaders = requestHeaders
            self.requestBody = requestBody
            self.phase = .pending
        }
    }

    /// Raw or parsed body for request and response payloads. Empty bodies are
    /// represented as `nil` to keep the UI compact; everything else is
    /// captured either as UTF-8 text or as a pretty-printed JSON fragment
    /// (the UI shows whichever is appropriate).
    public enum BodyValue: Codable, Sendable, Equatable {
        case text(String)
        case json(String)

        public var displayString: String {
            switch self {
            case .text(let s), .json(let s): return s
            }
        }

        public var isJSON: Bool {
            if case .json = self { return true }
            return false
        }
    }

    public enum StatusFamily: String, CaseIterable, Identifiable, Sendable {
        case all
//        case info   // 1xx
        case success // 2xx
//        case redirect // 3xx
        case client // 4xx
        case server // 5xx
        case error  // network/transport failures

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .all: return "All"
//            case .info: return "1xx"
            case .success: return "2xx"
//            case .redirect: return "3xx"
            case .client: return "4xx"
            case .server: return "5xx"
            case .error: return "Errors"
            }
        }
    }

    // MARK: - Store

    private static let maxEntries = 200
    private static let storageFilename = "api-log.json"

    private let storageURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let ioQueue = DispatchQueue(label: "com.productivityos.devtools.apilogstore.io")

    @Published private var entries: [Entry] = []

    public var logEntries: [Entry] { entries }

    public init(storageDirectory: URL? = nil) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let directory = storageDirectory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("devtools", isDirectory: true)
        self.storageURL = directory.appendingPathComponent(Self.storageFilename)

        self.entries = Self.load(from: storageURL, decoder: decoder)
    }

    // MARK: - Mutation

    /// Reserves a new entry for an outgoing request and returns its id so
    /// the caller can correlate the eventual response/error.
    @MainActor
    @discardableResult
    public func recordRequest(
        method: String,
        url: URL,
        headers: [String: String],
        body: BodyValue?
    ) -> UUID {
        let entry = Entry(
            startedAt: Date(),
            method: method.uppercased(),
            path: url.path,
            host: url.host ?? "",
            query: url.query,
            requestHeaders: headers,
            requestBody: body
        )
        entries.append(entry)
        trimIfNeeded()
        persist()
        return entry.id
    }

    /// Completes the entry for `id` with a successful response. If `id`
    /// has been evicted (cap was lowered, store cleared), the call is a
    /// no-op.
    @MainActor
    public func completeRequest(
        id: UUID,
        statusCode: Int,
        headers: [String: String],
        body: BodyValue?
    ) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let started = entries[index].startedAt
        let ended = Date()
        let duration = Int((ended.timeIntervalSince(started) * 1000).rounded())
        let phase: Phase = (200...299).contains(statusCode) ? .success : .failure
        entries[index].endedAt = ended
        entries[index].durationMs = duration
        entries[index].phase = phase
        entries[index].statusCode = statusCode
        entries[index].responseHeaders = headers
        entries[index].responseBody = body
        entries[index].errorDescription = nil
        persist()
    }

    /// Completes the entry for `id` with a transport / decoding failure.
    @MainActor
    public func completeRequestWithError(id: UUID, description: String) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let started = entries[index].startedAt
        let ended = Date()
        let duration = Int((ended.timeIntervalSince(started) * 1000).rounded())
        entries[index].endedAt = ended
        entries[index].durationMs = duration
        entries[index].phase = .failure
        entries[index].statusCode = nil
        entries[index].responseHeaders = nil
        entries[index].responseBody = nil
        entries[index].errorDescription = description
        persist()
    }

    /// Drops every entry. Cheap and synchronous from the UI's perspective:
    /// the actual file deletion is offloaded to the I/O queue.
    @MainActor
    public func clear() {
        entries.removeAll()
        persist()
    }

    // MARK: - Derived views

    /// Filter and search the entries in one pass. Search matches against the
    /// path, query, status text and the request body preview.
    public func filtered(family: StatusFamily, query: String) -> [Entry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return entries.reversed().filter { entry in
            guard matches(family: family, entry: entry) else { return false }
            guard !trimmed.isEmpty else { return true }
            if entry.path.lowercased().contains(trimmed) { return true }
            if let q = entry.query, q.lowercased().contains(trimmed) { return true }
            if let status = entry.statusCode, String(status).contains(trimmed) { return true }
            if let body = entry.requestBody?.displayString.lowercased(),
               body.contains(trimmed) { return true }
            if let body = entry.responseBody?.displayString.lowercased(),
               body.contains(trimmed) { return true }
            if let error = entry.errorDescription?.lowercased(), error.contains(trimmed) { return true }
            return false
        }
    }

    public func count(for family: StatusFamily) -> Int {
        entries.filter { matches(family: family, entry: $0) }.count
    }

    private func matches(family: StatusFamily, entry: Entry) -> Bool {
        switch family {
        case .all:
            return true
        case .error:
            return entry.phase == .failure && entry.statusCode == nil
        default:
            guard let code = entry.statusCode else { return false }
            switch family {
//            case .info: return (100...199).contains(code)
            case .success: return (200...299).contains(code)
//            case .redirect: return (300...399).contains(code)
            case .client: return (400...499).contains(code)
            case .server: return (500...599).contains(code)
            default: return false
            }
        }
    }

    // MARK: - Storage

    private func trimIfNeeded() {
        if entries.count > Self.maxEntries {
            entries.removeFirst(entries.count - Self.maxEntries)
        }
    }

    private func persist() {
        let snapshot = entries
        let url = storageURL
        let encoder = self.encoder
        ioQueue.async {
            do {
                let data = try encoder.encode(snapshot)
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try data.write(to: url, options: .atomic)
            } catch {
                // Persistence is best-effort; the in-memory store still works.
            }
        }
    }

    private static func load(from url: URL, decoder: JSONDecoder) -> [Entry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? decoder.decode([Entry].self, from: data)) ?? []
    }
}
