import Foundation

/// Daily Top 3 service backed by `GET /api/v1/daily-top-three/{date}`.
/// The date bucket follows the device timezone (ADR-006 proxy for V1).
public struct TopThreeService: Sendable {
    private let apiClient: APIRequesting
    private let cache: APICache

    public init(apiClient: APIRequesting = APIClient.shared, cache: APICache = .shared) {
        self.apiClient = apiClient
        self.cache = cache
    }

    public func today(date: Date = Date(), calendar: Calendar = .current) async throws -> [TopThreeItem] {
        let endpoint = AppEndpoint.getDailyTopThree(date: Self.apiDateString(for: date, calendar: calendar))
        let key = CacheKey(endpoint: endpoint)
        if let (data, _) = await cache.get(key: key) {
            return try APIClient.jsonDecoder.decode([TopThreeItem].self, from: data)
        }
        let (data, response) = try await apiClient.send(endpoint)
        await cache.set(
            key: key,
            data: data,
            statusCode: response.statusCode,
            ttl: APICache.TTL.topThree
        )
        return try APIClient.jsonDecoder.decode([TopThreeItem].self, from: data)
    }

    static func apiDateString(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return "1970-01-01"
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
