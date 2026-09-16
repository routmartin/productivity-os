import XCTest
@testable import ProductivityOS

final class MacAuthCoordinatorTests: XCTestCase {
    private var mockAPIClient: MockAPIClient!
    private var authSession: AuthSession!
    private var keychain: KeychainManager!
    private var coordinator: MacAuthCoordinator!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        keychain = KeychainManager(serviceName: "com.productivityos.test.mac")
        keychain.clearAll()
        authSession = AuthSession(keychain: keychain)
        coordinator = MacAuthCoordinator(apiClient: mockAPIClient, authSession: authSession)
    }

    override func tearDown() {
        keychain.clearAll()
        super.tearDown()
    }

    // MARK: - URL parsing

    func testParseValidURL() {
        XCTAssertEqual(
            MacAuthCoordinator.parseChallenge(from: "productivityos://auth?challenge=abc123"),
            "abc123"
        )
    }

    func testParseRejectsWrongScheme() {
        XCTAssertNil(MacAuthCoordinator.parseChallenge(from: "https://auth?challenge=abc"))
    }

    func testParseRejectsWrongHost() {
        XCTAssertNil(MacAuthCoordinator.parseChallenge(from: "productivityos://other?challenge=abc"))
    }

    func testParseRejectsMissingChallenge() {
        XCTAssertNil(MacAuthCoordinator.parseChallenge(from: "productivityos://auth?other=abc"))
    }

    func testParseRejectsEmptyChallenge() {
        XCTAssertNil(MacAuthCoordinator.parseChallenge(from: "productivityos://auth?challenge="))
    }

    func testParseAcceptsExtraQueryItems() {
        XCTAssertEqual(
            MacAuthCoordinator.parseChallenge(from: "productivityos://auth?source=web&challenge=xyz&foo=bar"),
            "xyz"
        )
    }

    // MARK: - Handle (full flow)

    func testHandleInvalidURLReturnsInvalidURL() async {
        let result = await coordinator.handle(urlString: "https://example.com/foo")
        XCTAssertEqual(result, .invalidURL)
        XCTAssertTrue(mockAPIClient.recordedRequests.isEmpty)
        XCTAssertFalse(authSession.isAuthenticated)
    }

    func testHandleSuccessAuthenticatesAndUpdatesSession() async {
        let responseJSON = """
        {
            "accessToken": "mac-mock-jwt",
            "user": {
                "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
                "email": "user@example.com",
                "displayName": null
            }
        }
        """
        mockAPIClient.defaultResponse = .success((Data(responseJSON.utf8), 200))

        let result = await coordinator.handle(urlString: "productivityos://auth?challenge=good")

        XCTAssertEqual(result, .authenticated(email: "user@example.com"))
        XCTAssertTrue(authSession.isAuthenticated)
        XCTAssertEqual(authSession.accessToken, "mac-mock-jwt")
        XCTAssertEqual(authSession.currentUser?.email, "user@example.com")
        XCTAssertEqual(mockAPIClient.recordedRequests.count, 1)
        XCTAssertEqual(mockAPIClient.recordedRequests.first?.path, "/api/v1/auth/qr/exchange")
    }

    func testHandleExpiredChallengeSurfacesFriendlyError() async {
        mockAPIClient.defaultResponse = .failure(
            APIError.unauthorized(code: "challenge_expired", message: "expired")
        )
        let result = await coordinator.handle(urlString: "productivityos://auth?challenge=old")
        XCTAssertEqual(result, .challengeExpired)
        XCTAssertFalse(authSession.isAuthenticated)
    }

    func testHandleReusedChallengeSurfacesFriendlyError() async {
        mockAPIClient.defaultResponse = .failure(
            APIError.unauthorized(code: "challenge_already_used", message: nil)
        )
        let result = await coordinator.handle(urlString: "productivityos://auth?challenge=used")
        XCTAssertEqual(result, .challengeAlreadyUsed)
    }

    func testHandleInvalidChallengeSurfacesFriendlyError() async {
        mockAPIClient.defaultResponse = .failure(
            APIError.unauthorized(code: "invalid_challenge", message: nil)
        )
        let result = await coordinator.handle(urlString: "productivityos://auth?challenge=bogus")
        XCTAssertEqual(result, .invalidChallenge)
    }

    func testHandleNetworkErrorSurfacesNetworkKind() async {
        mockAPIClient.defaultResponse = .failure(APIError.networkError("offline"))
        let result = await coordinator.handle(urlString: "productivityos://auth?challenge=any")
        if case .network(let detail) = result {
            XCTAssertEqual(detail, "offline")
        } else {
            XCTFail("Expected .network, got \(result)")
        }
    }

    func testHandleServerErrorSurfacesUnknown() async {
        mockAPIClient.defaultResponse = .failure(APIError.serverError(statusCode: 500, code: nil, message: "boom"))
        let result = await coordinator.handle(urlString: "productivityos://auth?challenge=any")
        if case .unknown = result {
            // OK
        } else {
            XCTFail("Expected .unknown, got \(result)")
        }
    }
}
