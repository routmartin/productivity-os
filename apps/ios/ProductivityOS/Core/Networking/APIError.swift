import Foundation

/// Strongly typed API Error following the backend structured error model
/// (`code`, `message`, `details`, `traceId` — ADR-005).
public enum APIError: Error, LocalizedError, Sendable {
    case invalidURL
    case networkError(String)
    /// 401 after a failed refresh attempt
    case unauthorized(code: String?, message: String?)
    case forbidden // 403
    case notFound // 404
    case serverError(statusCode: Int, code: String?, message: String?)
    case decodingError(String)
    case unknown

    public init(statusCode: Int, data: Data?) {
        let structured = Self.structuredBody(from: data)
        switch statusCode {
        case 401:
            self = .unauthorized(
                code: structured?.code,
                message: structured?.message ?? "Session expired. Please log in again."
            )
        case 403:
            self = .forbidden
        case 404:
            self = .notFound
        default:
            self = .serverError(
                statusCode: statusCode,
                code: structured?.code,
                message: structured?.message
            )
        }
    }

    private static func structuredBody(from data: Data?) -> (code: String, message: String?, details: String?)? {
        guard let data, !data.isEmpty else { return nil }
        guard let body = try? JSONDecoder().decode(StructuredErrorBody.self, from: data) else { return nil }
        return (body.code ?? "UNKNOWN_ERROR", body.message, body.details)
    }

    private struct StructuredErrorBody: Decodable {
        let code: String?
        let message: String?
        let details: String?
    }
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .networkError:
            return "Could not reach the server. Check your connection and try again."
        case .unauthorized(_, let message):
            return message ?? "Session expired or unauthorized. Please log in again."
        case .forbidden:
            return "Access forbidden."
        case .notFound:
            return "Resource not found."
        case .serverError(let statusCode, _, let message):
            return message ?? "Server returned an error (\(statusCode)). Please try again."
        case .decodingError(let message):
            return "Failed to parse server response: \(message)"
        case .unknown:
            return "An unexpected error occurred."
        }
    }
}
