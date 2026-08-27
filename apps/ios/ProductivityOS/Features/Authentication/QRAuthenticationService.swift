import Foundation

final class QRAuthenticationService {
    static let shared = QRAuthenticationService()
    private init() {}

    /// Attempts to extract and validate a challenge string from the scanned QR code string.
    /// - Parameter code: The scanned QR code string.
    /// - Returns: A valid challenge string if extraction and validation succeed, otherwise nil.
    func parseChallenge(from code: String) -> String? {
        // Example validation: the challenge should be a non-empty alphanumeric string of certain length
        // Adjust the validation logic based on actual backend requirements
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // For example, a challenge could be a base64 or hex string, here just checking alphanumeric
        let allowedCharacters = CharacterSet.alphanumerics
        if trimmed.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return nil
        }

        return trimmed
    }

    /// Sends the challenge string to the backend API to authenticate the user.
    /// - Parameter challenge: The challenge string extracted from the QR code.
    /// - Throws: Throws an error if the API call fails or returns an error.
    func authenticate(challenge: String) async throws {
        struct QRExchangeRequest: Encodable {
            let challenge: String
        }

        struct QRExchangeResponse: Decodable {
            let token: String
            let expiresIn: Int
        }

        let request = QRExchangeRequest(challenge: challenge)
        let url = URL(string: "/qrExchange", relativeTo: APIConfiguration.shared.baseURL)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let qrResponse = try JSONDecoder().decode(QRExchangeResponse.self, from: data)

        // Save the token to the current session (no refresh token or user info available in this flow)
        AuthSession.shared.setSession(accessToken: qrResponse.token, refreshToken: nil, user: nil)
    }
}

