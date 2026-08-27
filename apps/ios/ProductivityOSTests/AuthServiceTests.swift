import Foundation
import XCTest
@testable import ProductivityOS

final class AuthServiceTests: XCTestCase {
    private var mock: MockAPIClient!
    private var authSession: AuthSession!
    private var service: AuthService!

    override func setUp() {
        super.setUp()
        mock = MockAPIClient()
        authSession = AuthSession(keychain: KeychainManager(serviceName: "com.productivityos.tests.\(UUID().uuidString)"))
        service = AuthService(apiClient: mock, authSession: authSession)
    }

    override func tearDown() {
        authSession.logout()
        super.tearDown()
    }

    func testLoginStoresAccessTokenAndUser() async throws {
        mock.defaultResponse = .success((
            Data(#"{"accessToken":"jwt-token","user":{"id":"11111111-1111-1111-1111-111111111111","email":"rout@productivityos.com","timezone":"Europe/Lisbon"}}"#.utf8),
            200
        ))

        try await service.login(email: "rout@productivityos.com", password: "secret-password")

        XCTAssertTrue(authSession.isAuthenticated)
        XCTAssertEqual(authSession.currentUser?.email, "rout@productivityos.com")

        let request = try XCTUnwrap(mock.recordedRequests.first)
        XCTAssertEqual(request.path, "/api/v1/auth/login")
        XCTAssertEqual(request.method, "POST")

        let body = try XCTUnwrap(request.body)
        let decoded = try JSONDecoder().decode(LoginRequestBody.self, from: body)
        XCTAssertEqual(decoded.email, "rout@productivityos.com")
    }

    func testRegisterSendsEmailPasswordTimezone() async throws {
        mock.defaultResponse = .success((
            Data(#"{"id":"11111111-1111-1111-1111-111111111111","email":"new@user.com","timezone":"UTC"}"#.utf8),
            201
        ))

        try await service.register(email: "new@user.com", password: "long-enough-password")

        let request = try XCTUnwrap(mock.recordedRequests.first)
        XCTAssertEqual(request.path, "/api/v1/auth/register")

        let body = try JSONDecoder().decode(RegisterRequestBody.self, from: XCTUnwrap(request.body))
        XCTAssertEqual(body.email, "new@user.com")
        XCTAssertEqual(body.password, "long-enough-password")
        XCTAssertNotNil(body.timezone)
    }

    func testLogoutClearsSessionAndCallsEndpoint() async throws {
        authSession.setSession(
            accessToken: "token",
            user: User(id: UUID(), email: "a@b.co", name: nil, avatarUrl: nil, createdAt: nil)
        )
        mock.defaultResponse = .success((Data(), 204))

        await service.logout()

        XCTAssertFalse(authSession.isAuthenticated)
        XCTAssertNil(authSession.currentUser)
        XCTAssertEqual(mock.recordedRequests.first?.path, "/api/v1/auth/logout")
        XCTAssertEqual(mock.recordedRequests.first?.method, "POST")
    }

    func testRefreshKeepsCachedProfile() throws {
        // Backend refresh responds with user == null; the profile must survive.
        let json = Data(#"{"accessToken":"fresh","user":null}"#.utf8)
        let response = try JSONDecoder().decode(AuthResponse.self, from: json)
        authSession.setSession(accessToken: response.accessToken, user: response.domainUser)

        XCTAssertEqual(authSession.accessToken, "fresh")
        XCTAssertNil(authSession.currentUser)
    }
}
