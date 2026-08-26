import Foundation
@testable import ProductivityOS

/// Mock transport for service-level tests. Records requests and returns
/// scripted results without touching the network.
public final class MockAPIClient: APIRequesting, @unchecked Sendable {
    public struct Recorded: Sendable {
        public let method: String
        public let path: String
        public let body: Data?
    }

    public private(set) var recordedRequests: [Recorded] = []
    /// Scripted responses consumed in order (one per request).
    public var scriptedResponses: [Result<(Data, Int), Error>] = []
    public var defaultResponse: Result<(Data, Int), Error> = .success((Data("[]".utf8), 200))

    public init() {}

    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let (data, _) = try await send(endpoint)
        do {
            return try APIClient.jsonDecoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    public func send(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        recordedRequests.append(
            Recorded(
                method: endpoint.method.rawValue,
                path: endpoint.path,
                body: endpoint.body
            )
        )

        let outcome: Result<(Data, Int), Error>
        if !scriptedResponses.isEmpty {
            outcome = scriptedResponses.removeFirst()
        } else {
            outcome = defaultResponse
        }

        switch outcome {
        case .success(let (data, status)):
            let response = HTTPURLResponse(
                url: URL(string: "https://test.local\(endpoint.path)")!,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (data, response)
        case .failure(let error):
            throw error
        }
    }
}
