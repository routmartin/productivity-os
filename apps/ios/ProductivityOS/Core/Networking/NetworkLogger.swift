import Foundation
import OSLog

/// Secure logger for networking events.
///
/// Three responsibilities:
/// 1. Pretty-print request/response events to `OSLog` for console debugging.
/// 2. Hand the same data to `APILogStore` as a single coordinated entry per
///    request lifecycle, so the DevTools network tab can show one row per
///    HTTP call instead of two.
/// 3. Redact sensitive headers and JSON fields (Authorization, cookies,
///    password, tokens) before either destination sees them.
public enum NetworkLogger {

    private static let log = Logger(subsystem: "com.productivityos.app", category: "Networking")

    /// Reserve a slot for the outgoing request. Returns the slot id so the
    /// matching response or error can be correlated by `completeWithResponse`
    /// or `completeWithError`.
    @MainActor
    @discardableResult
    public static func log(request: URLRequest) -> UUID {
        let url = request.url
        let method = request.httpMethod ?? "GET"
        let headers = sanitize(headers: request.allHTTPHeaderFields ?? [:])
        let body = bodyValue(from: request.httpBody)

        if let url {
            log.debug("📡 [OUT] \(method, privacy: .public) \(url.absoluteString, privacy: .public)")
        } else {
            log.debug("📡 [OUT] \(method, privacy: .public) <unknown>")
        }

        return APILogStore.shared.recordRequest(
            method: method,
            url: url ?? URL(string: "about:blank")!,
            headers: headers,
            body: body
        )
    }

    /// Correlate a successful response with the previously recorded request.
    public static func completeWithResponse(id: UUID, response: HTTPURLResponse, data: Data) {
        let status = response.statusCode
        let headers = sanitize(headers: response.allHeaderFields.dictionaryString)
        let body = bodyValue(from: data)

        log.debug("✅ [IN] \(status, privacy: .public) \(response.url?.absoluteString ?? "", privacy: .public)")

        Task { @MainActor in
            APILogStore.shared.completeRequest(
                id: id,
                statusCode: status,
                headers: headers,
                body: body
            )
        }
    }

    /// Correlate a transport or decoding failure with the previously
    /// recorded request.
    public static func completeWithError(id: UUID, error: Error, url: URL?) {
        let description = error.localizedDescription
        log.error("❌ [ERROR] \(url?.absoluteString ?? "unknown", privacy: .public): \(description, privacy: .public)")
        Task { @MainActor in
            APILogStore.shared.completeRequestWithError(id: id, description: description)
        }
    }

    // MARK: - Sanitization

    /// Header keys whose values are redacted before logging/persistence.
    private static let sensitiveHeaders: Set<String> = [
        "authorization", "set-cookie", "cookie", "x-api-key",
    ]

    /// JSON field names whose string values are redacted inside bodies.
    private static let sensitiveFields: [String] = [
        "password", "accessToken", "refreshToken", "challenge",
    ]

    private static func sanitize(headers: [String: String]) -> [String: String] {
        headers.reduce(into: [:]) { acc, pair in
            if sensitiveHeaders.contains(pair.key.lowercased()) {
                acc[pair.key] = "[REDACTED]"
            } else {
                acc[pair.key] = pair.value
            }
        }
    }

    private static func bodyValue(from data: Data?) -> APILogStore.BodyValue? {
        guard let data, !data.isEmpty else { return nil }
        let raw = String(data: data, encoding: .utf8) ?? ""
        let scrubbed = sanitize(body: raw)
        if let pretty = prettyJSON(scrubbed) {
            return .json(pretty)
        }
        return .text(scrubbed)
    }

    /// Best-effort JSON pretty-printer. Falls back to `nil` if the body is
    /// not valid JSON (caller keeps the raw string).
    private static func prettyJSON(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else { return nil }
        guard let object = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed),
              let pretty = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]
              ),
              let out = String(data: pretty, encoding: .utf8) else {
            return nil
        }
        return out
    }

    /// Replace `"key": "value"` JSON string values with `"key": "[REDACTED]"`
    /// for any sensitive field. Non-string values for these keys are
    /// untouched (e.g. boolean flags are not credentials).
    private static func sanitize(body: String) -> String {
        var scrubbed = body
        for key in sensitiveFields {
            let pattern = "\"\(NSRegularExpression.escapedPattern(for: key))\"\\s*:\\s*\"[^\"]*\""
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            scrubbed = regex.stringByReplacingMatches(
                in: scrubbed,
                options: [],
                range: NSRange(location: 0, length: scrubbed.utf16.count),
                withTemplate: "\"\(key)\": \"[REDACTED]\""
            )
        }
        return scrubbed
    }
}

private extension Dictionary where Key == AnyHashable, Value == Any {
    /// `HTTPURLResponse.allHeaderFields` returns `[AnyHashable: Any]`; cast
    /// to `[String: String]` for the dev log, preserving only string values.
    var dictionaryString: [String: String] {
        reduce(into: [:]) { acc, pair in
            guard let key = pair.key as? String, let value = pair.value as? String else { return }
            acc[key] = value
        }
    }
}