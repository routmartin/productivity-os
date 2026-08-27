import XCTest
@testable import ProductivityOS

final class QRAuthenticationServiceTests: XCTestCase {
    private var service: QRAuthenticationService!
    private var mockAPIClient: MockAPIClient!
    private var authSession: AuthSession!
    private var keychain: KeychainManager!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        keychain = KeychainManager(serviceName: "com.productivityos.test")
        keychain.clearAll()
        authSession = AuthSession(keychain: keychain)
        service = QRAuthenticationService(apiClient: mockAPIClient, authSession: authSession)
    }

    func testParseChallengeValidUrl() {
        let url = "productivityos://auth?challenge=test-challenge"
        let challenge = service.parseChallenge(from: url)
        XCTAssertEqual(challenge, "test-challenge")
    }

    func testParseChallengeInvalidUrl() {
        let urls = [
            "https://example.com/auth?challenge=test",
            "productivityos://other?challenge=test",
            "productivityos://auth?wrong=test",
            "malformed-url"
        ]
        
        for url in urls {
            XCTAssertNil(service.parseChallenge(from: url), "Should be nil for \(url)")
        }
    }

    func testAuthenticateSuccess() async throws {
        let challenge = "valid-challenge"
        let userJson = """
        {
            "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
            "email": "test@example.com",
            "displayName": "Test User",
            "createdAt": "2026-08-27T10:00:00Z"
        }
        """
        let responseJson = """
        {
            "accessToken": "mock-jwt",
            "user": \(userJson)
        }
        """
        let responseData = responseJson.data(using: .utf8)!
        mockAPIClient.defaultResponse = .success((responseData, 200))
        
        try await service.authenticate(challenge: challenge)
        
        XCTAssertTrue(authSession.isAuthenticated)
        XCTAssertEqual(authSession.accessToken, "mock-jwt")
        XCTAssertEqual(authSession.currentUser?.email, "test@example.com")
        XCTAssertEqual(mockAPIClient.recordedRequests.first?.path, "/api/v1/auth/qr/exchange")
    }

    func testAuthenticateFailure() async {
        let challenge = "invalid-challenge"
        mockAPIClient.defaultResponse = .failure(APIError.unauthorized(code: "invalid_challenge", message: "Invalid challenge"))
        
        do {
            try await service.authenticate(challenge: challenge)
            XCTFail("Should throw error")
        } catch {
            XCTAssertFalse(authSession.isAuthenticated)
        }
    }
}
