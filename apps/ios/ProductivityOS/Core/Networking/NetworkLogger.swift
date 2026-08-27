import Foundation
import OSLog

/// Secure logger for networking events.
/// Redacts sensitive information like Authorization headers and passwords.
public final class NetworkLogger: Sendable {
    private static let log = Logger(subsystem: "com.productivityos.app", category: "Networking")
    
    public static func log(request: URLRequest) {
        let url = request.url?.absoluteString ?? "Unknown URL"
        let method = request.httpMethod ?? "GET"
        
        var headerString = ""
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                let sanitizedValue = shouldRedact(header: key) ? "[REDACTED]" : value
                headerString += "\n  \(key): \(sanitizedValue)"
            }
        }
        
        var bodyString = ""
        if let body = request.httpBody, let string = String(data: body, encoding: .utf8) {
            bodyString = "\nBody: \(sanitize(body: string))"
        }
        
        log.debug("📡 [OUT] \(method) \(url)\(headerString)\(bodyString)")
    }
    
    public static func log(response: HTTPURLResponse, data: Data) {
        let url = response.url?.absoluteString ?? "Unknown URL"
        let status = response.statusCode
        
        var bodyString = ""
        if let string = String(data: data, encoding: .utf8) {
            bodyString = "\nBody: \(sanitize(body: string))"
        }
        
        log.debug("✅ [IN] \(status) \(url)\(bodyString)")
    }
    
    public static func log(error: Error, url: URL?) {
        let urlString = url?.absoluteString ?? "Unknown URL"
        log.error("❌ [ERROR] \(urlString): \(error.localizedDescription)")
    }
    
    // MARK: - Privacy
    
    private static func shouldRedact(header: String) -> Bool {
        let sensitive = ["authorization", "set-cookie", "cookie", "x-api-key"]
        return sensitive.contains(header.lowercased())
    }
    
    private static func sanitize(body: String) -> String {
        // Simple redaction for common sensitive keys in JSON
        var sanitized = body
        let sensitiveKeys = ["password", "accessToken", "refreshToken", "challenge"]
        
        for key in sensitiveKeys {
            // Regex to find "key": "value" and replace value
            let pattern = "\"\(key)\"\\s*:\\s*\"[^\"]+\""
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                sanitized = regex.stringByReplacingMatches(
                    in: sanitized,
                    options: [],
                    range: NSRange(location: 0, length: sanitized.utf16.count),
                    withTemplate: "\"\(key)\": \"[REDACTED]\""
                )
            }
        }
        return sanitized
    }
}
