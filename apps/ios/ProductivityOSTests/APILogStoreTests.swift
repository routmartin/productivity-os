import XCTest
@testable import ProductivityOS

final class APILogStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("APILogStoreTests_\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        super.tearDown()
    }

    // MARK: - 1. Recording Requests and Responses

    @MainActor
    func testRecordRequestAndCompleteWithResponse() {
        let store = APILogStore(storageDirectory: tempDirectory)
        let requestURL = URL(string: "https://api.productivityos.com/api/v1/tasks?active=true")!
        let requestHeaders = ["Accept": "application/json", "User-Agent": "ProductivityOS/1.0"]
        let requestBody = APILogStore.BodyValue.json("{\"title\":\"Finish widget\"}")

        let id = store.recordRequest(
            method: "POST",
            url: requestURL,
            headers: requestHeaders,
            body: requestBody
        )

        XCTAssertEqual(store.logEntries.count, 1)
        guard let pendingEntry = store.logEntries.first(where: { $0.id == id }) else {
            XCTFail("Pending entry not found")
            return
        }

        XCTAssertEqual(pendingEntry.method, "POST")
        XCTAssertEqual(pendingEntry.path, "/api/v1/tasks")
        XCTAssertEqual(pendingEntry.host, "api.productivityos.com")
        XCTAssertEqual(pendingEntry.query, "active=true")
        XCTAssertEqual(pendingEntry.requestHeaders["Accept"], "application/json")
        XCTAssertEqual(pendingEntry.requestBody?.displayString, "{\"title\":\"Finish widget\"}")
        XCTAssertEqual(pendingEntry.phase, .pending)
        XCTAssertNil(pendingEntry.statusCode)
        XCTAssertNil(pendingEntry.endedAt)
        XCTAssertNil(pendingEntry.durationMs)

        // Complete request with 200 OK
        let responseHeaders = ["Content-Type": "application/json"]
        let responseBody = APILogStore.BodyValue.json("{\"id\":\"abc-123\",\"title\":\"Finish widget\"}")
        store.completeRequest(
            id: id,
            statusCode: 200,
            headers: responseHeaders,
            body: responseBody
        )

        guard let completedEntry = store.logEntries.first(where: { $0.id == id }) else {
            XCTFail("Completed entry not found")
            return
        }

        XCTAssertEqual(completedEntry.phase, .success)
        XCTAssertEqual(completedEntry.statusCode, 200)
        XCTAssertEqual(completedEntry.responseHeaders?["Content-Type"], "application/json")
        XCTAssertEqual(completedEntry.responseBody?.displayString, "{\"id\":\"abc-123\",\"title\":\"Finish widget\"}")
        XCTAssertNotNil(completedEntry.endedAt)
        XCTAssertNotNil(completedEntry.durationMs)
        XCTAssertNil(completedEntry.errorDescription)
    }

    @MainActor
    func testRecordRequestAndCompleteWithError() {
        let store = APILogStore(storageDirectory: tempDirectory)
        let requestURL = URL(string: "https://api.productivityos.com/api/v1/goals")!

        let id = store.recordRequest(
            method: "GET",
            url: requestURL,
            headers: [:],
            body: nil
        )

        store.completeRequestWithError(id: id, description: "The Internet connection appears to be offline.")

        guard let entry = store.logEntries.first(where: { $0.id == id }) else {
            XCTFail("Entry not found")
            return
        }

        XCTAssertEqual(entry.phase, .failure)
        XCTAssertNil(entry.statusCode)
        XCTAssertNil(entry.responseHeaders)
        XCTAssertNil(entry.responseBody)
        XCTAssertEqual(entry.errorDescription, "The Internet connection appears to be offline.")
        XCTAssertNotNil(entry.durationMs)
    }

    // MARK: - 2. Sensitive Credential Scrubbing in NetworkLogger

    func testNetworkLoggerHeaderScrubbing() {
        let inputHeaders: [String: String] = [
            "Authorization": "Bearer super-secret-jwt-token",
            "authorization": "Bearer lower-case-token",
            "Cookie": "session_id=abcdef123456",
            "Set-Cookie": "auth_cookie=secret",
            "X-API-KEY": "prod-api-key-999",
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": "ProductivityOS/1.0"
        ]

        let sanitized = NetworkLogger.sanitize(headers: inputHeaders)

        XCTAssertEqual(sanitized["Authorization"], "[REDACTED]")
        XCTAssertEqual(sanitized["authorization"], "[REDACTED]")
        XCTAssertEqual(sanitized["Cookie"], "[REDACTED]")
        XCTAssertEqual(sanitized["Set-Cookie"], "[REDACTED]")
        XCTAssertEqual(sanitized["X-API-KEY"], "[REDACTED]")

        // Non-sensitive headers must remain untouched
        XCTAssertEqual(sanitized["Accept"], "application/json")
        XCTAssertEqual(sanitized["Content-Type"], "application/json")
        XCTAssertEqual(sanitized["User-Agent"], "ProductivityOS/1.0")
    }

    func testNetworkLoggerBodyScrubbing() {
        let sensitiveJSON = """
        {
          "email": "user@example.com",
          "password": "myVerySecretPassword123!",
          "refreshToken": "rt_secure_refresh_token_xyz",
          "accessToken": "at_secure_access_token_abc",
          "challenge": "challenge_token_000",
          "other": "normal-value"
        }
        """

        let scrubbed = NetworkLogger.sanitize(body: sensitiveJSON)

        XCTAssertFalse(scrubbed.contains("myVerySecretPassword123!"))
        XCTAssertFalse(scrubbed.contains("rt_secure_refresh_token_xyz"))
        XCTAssertFalse(scrubbed.contains("at_secure_access_token_abc"))
        XCTAssertFalse(scrubbed.contains("challenge_token_000"))

        XCTAssertTrue(scrubbed.contains("\"password\": \"[REDACTED]\""))
        XCTAssertTrue(scrubbed.contains("\"refreshToken\": \"[REDACTED]\""))
        XCTAssertTrue(scrubbed.contains("\"accessToken\": \"[REDACTED]\""))
        XCTAssertTrue(scrubbed.contains("\"challenge\": \"[REDACTED]\""))
        XCTAssertTrue(scrubbed.contains("\"email\": \"user@example.com\""))
        XCTAssertTrue(scrubbed.contains("\"other\": \"normal-value\""))
    }

    @MainActor
    func testNetworkLoggerEndToEndRequestScrubbing() {
        var request = URLRequest(url: URL(string: "https://api.productivityos.com/api/v1/auth/login")!)
        request.httpMethod = "POST"
        request.setValue("Bearer header-bearer-token", forHTTPHeaderField: "Authorization")
        request.setValue("secret-key", forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let bodyJSON = """
        {"email":"user@example.com","password":"secretPassword","refreshToken":"refresh123"}
        """
        request.httpBody = Data(bodyJSON.utf8)

        let loggedId = NetworkLogger.log(request: request)

        guard let entry = APILogStore.shared.logEntries.first(where: { $0.id == loggedId }) else {
            XCTFail("Logged entry not found in shared APILogStore")
            return
        }

        XCTAssertEqual(entry.requestHeaders["Authorization"], "[REDACTED]")
        XCTAssertEqual(entry.requestHeaders["x-api-key"], "[REDACTED]")
        XCTAssertEqual(entry.requestHeaders["Content-Type"], "application/json")

        let bodyDisplay = entry.requestBody?.displayString ?? ""
        XCTAssertFalse(bodyDisplay.contains("secretPassword"))
        XCTAssertFalse(bodyDisplay.contains("refresh123"))
        XCTAssertTrue(bodyDisplay.contains("\"password\": \"[REDACTED]\"") || bodyDisplay.contains("\"password\" : \"[REDACTED]\""))
        XCTAssertTrue(bodyDisplay.contains("\"refreshToken\": \"[REDACTED]\"") || bodyDisplay.contains("\"refreshToken\" : \"[REDACTED]\""))
        XCTAssertTrue(bodyDisplay.contains("user@example.com"))
    }

    // MARK: - 3. Status Family Filtering (2xx, 4xx, 5xx, errors)

    @MainActor
    func testStatusFamilyFilteringAndCounts() {
        let store = APILogStore(storageDirectory: tempDirectory)

        func addCall(method: String, path: String, status: Int?, error: String? = nil) {
            let id = store.recordRequest(
                method: method,
                url: URL(string: "https://api.productivityos.com\(path)")!,
                headers: [:],
                body: nil
            )
            if let status {
                store.completeRequest(id: id, statusCode: status, headers: [:], body: nil)
            } else if let error {
                store.completeRequestWithError(id: id, description: error)
            }
        }

        // 2xx Success (2 calls)
        addCall(method: "GET", path: "/api/v1/tasks", status: 200)
        addCall(method: "POST", path: "/api/v1/tasks", status: 201)

        // 4xx Client Error (2 calls)
        addCall(method: "GET", path: "/api/v1/tasks/missing", status: 404)
        addCall(method: "POST", path: "/api/v1/auth/login", status: 401)

        // 5xx Server Error (1 call)
        addCall(method: "GET", path: "/api/v1/analytics", status: 500)

        // Network Error (1 call)
        addCall(method: "GET", path: "/api/v1/offline", status: nil, error: "Network timed out")

        // Assert counts
        XCTAssertEqual(store.count(for: .all), 6)
        XCTAssertEqual(store.count(for: .success), 2)
        XCTAssertEqual(store.count(for: .client), 2)
        XCTAssertEqual(store.count(for: .server), 1)
        XCTAssertEqual(store.count(for: .error), 1)

        // Assert filtered results
        let successEntries = store.filtered(family: .success, query: "")
        XCTAssertEqual(successEntries.count, 2)
        XCTAssertTrue(successEntries.allSatisfy { (200...299).contains($0.statusCode ?? 0) })

        let clientEntries = store.filtered(family: .client, query: "")
        XCTAssertEqual(clientEntries.count, 2)
        XCTAssertTrue(clientEntries.allSatisfy { (400...499).contains($0.statusCode ?? 0) })

        let serverEntries = store.filtered(family: .server, query: "")
        XCTAssertEqual(serverEntries.count, 1)
        XCTAssertEqual(serverEntries.first?.statusCode, 500)

        let errorEntries = store.filtered(family: .error, query: "")
        XCTAssertEqual(errorEntries.count, 1)
        XCTAssertNil(errorEntries.first?.statusCode)
        XCTAssertEqual(errorEntries.first?.errorDescription, "Network timed out")

        // Query search within family
        let searchedTasks = store.filtered(family: .all, query: "tasks")
        XCTAssertEqual(searchedTasks.count, 3)

        let searchedMissing = store.filtered(family: .client, query: "missing")
        XCTAssertEqual(searchedMissing.count, 1)
        XCTAssertEqual(searchedMissing.first?.statusCode, 404)
    }

    // MARK: - 4. Transcript Formatting for Clipboard Copying

    func testTranscriptFormatting() {
        var entry = APILogStore.Entry(
            id: UUID(),
            startedAt: Date(timeIntervalSince1970: 1700000000),
            method: "POST",
            path: "/api/v1/tasks",
            host: "api.productivityos.com",
            query: "source=widget",
            absoluteURL: "https://api.productivityos.com/api/v1/tasks?source=widget",
            requestHeaders: ["Content-Type": "application/json"],
            requestBody: .json("{\n  \"title\": \"Ship widget\"\n}")
        )
        entry.statusCode = 201
        entry.durationMs = 145
        entry.responseBody = .json("{\n  \"id\": \"1234\",\n  \"status\": \"pending\"\n}")

        let transcript = entry.transcript

        XCTAssertTrue(transcript.contains("POST https://api.productivityos.com/api/v1/tasks?source=widget"))
        XCTAssertTrue(transcript.contains("HTTP 201"))
        XCTAssertTrue(transcript.contains("Duration: 145 ms"))
        XCTAssertTrue(transcript.contains("── Request body ──"))
        XCTAssertTrue(transcript.contains("\"title\": \"Ship widget\""))
        XCTAssertTrue(transcript.contains("── Response body ──"))
        XCTAssertTrue(transcript.contains("\"id\": \"1234\""))
        XCTAssertFalse(transcript.contains("Error:"))
    }

    func testTranscriptFormattingWithError() {
        var entry = APILogStore.Entry(
            id: UUID(),
            startedAt: Date(timeIntervalSince1970: 1700000000),
            method: "GET",
            path: "/api/v1/goals",
            host: "api.productivityos.com",
            query: nil,
            absoluteURL: "https://api.productivityos.com/api/v1/goals",
            requestHeaders: [:],
            requestBody: nil
        )
        entry.phase = .failure
        entry.durationMs = 2300
        entry.errorDescription = "Could not connect to the server."

        let transcript = entry.transcript

        XCTAssertTrue(transcript.contains("GET https://api.productivityos.com/api/v1/goals"))
        XCTAssertTrue(transcript.contains("Duration: 2300 ms"))
        XCTAssertTrue(transcript.contains("Error: Could not connect to the server."))
        XCTAssertFalse(transcript.contains("HTTP"))
        XCTAssertFalse(transcript.contains("── Request body ──"))
        XCTAssertFalse(transcript.contains("── Response body ──"))
    }
}
