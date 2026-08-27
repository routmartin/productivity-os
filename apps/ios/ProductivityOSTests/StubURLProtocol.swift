import Foundation
import XCTest
@testable import ProductivityOS

/// URLProtocol stub so the real APIClient (refresh/retry logic) can be tested
/// without a live backend.
final class StubURLProtocol: URLProtocol {
    struct Response {
        let status: Int
        let data: Data
        let headers: [String: String]
        let delay: TimeInterval
    }

    struct RecordedRequest {
        let path: String
        let method: String
        let authorizationHeader: String?
    }

    private static let lock = NSLock()
    /// Path → queued responses; the last one repeats.
    nonisolated(unsafe) static var responders: [String: [Response]] = [:]
    nonisolated(unsafe) static var recordedRequests: [RecordedRequest] = []

    static func reset() {
        lock.withLock {
            responders = [:]
            recordedRequests = []
        }
    }

    static func enqueue(
        path: String,
        status: Int,
        data: Data = Data(),
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        lock.withLock {
            responders[path, default: []].append(
                Response(status: status, data: data, headers: headers, delay: delay)
            )
        }
    }

    static func recorded(pathContains: String) -> [RecordedRequest] {
        lock.withLock {
            recordedRequests.filter { $0.path.contains(pathContains) }
        }
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path = request.url?.path ?? ""
        let method = request.httpMethod ?? "GET"
        Self.lock.withLock {
            Self.recordedRequests.append(
                RecordedRequest(
                    path: path,
                    method: method,
                    authorizationHeader: request.value(forHTTPHeaderField: "Authorization")
                )
            )
        }

        let response = Self.lock.withLock { () -> Response? in
            guard var queue = Self.responders[path], !queue.isEmpty else { return nil }
            let first = queue.removeFirst()
            if queue.isEmpty {
                Self.responders[path] = [first]
            } else {
                Self.responders[path] = queue
            }
            return first
        }

        guard let response else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }

        if response.delay > 0 {
            Thread.sleep(forTimeInterval: response.delay)
        }

        let http = HTTPURLResponse(
            url: request.url!,
            statusCode: response.status,
            httpVersion: "HTTP/1.1",
            headerFields: response.headers
        )!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: response.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
