import Foundation
import SwiftUI

/// In-memory capture for developer API request log UI
public final class APILogStore: ObservableObject {
    public static let shared = APILogStore()

    public struct Entry: Identifiable, Sendable {
        public let id = UUID()
        public let timestamp: Date
        public let method: String
        public let url: String
        public let status: Int?
        public let bodyPreview: String
    }

    private init() {}

    @Published private var entries: [Entry] = []

    public var logEntries: [Entry] {
        entries
    }

    @MainActor
    public func append(requestMethod: String, url: String, responseStatus: Int?, bodyPreview: String) {
        let entry = Entry(
            timestamp: Date(),
            method: requestMethod,
            url: url,
            status: responseStatus,
            bodyPreview: bodyPreview
        )
        entries.append(entry)
        if entries.count > 50 {
            entries.removeFirst(entries.count - 50)
        }
    }

    @MainActor
    public func clear() {
        entries.removeAll()
    }
}
