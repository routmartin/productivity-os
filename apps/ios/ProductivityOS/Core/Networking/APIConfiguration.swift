import Foundation

/// API Environment Configuration
public struct APIConfiguration: Sendable {
    public enum Environment: String, Sendable {
        case development
        case staging
        case production
        
        public var defaultBaseURL: URL {
            switch self {
            case .development:
                return URL(string: "http://localhost:8080")!
            case .staging:
                return URL(string: "https://staging-api.productivityos.internal")!
            case .production:
                return URL(string: "https://productivity-os-api-13985383455.asia-southeast1.run.app")!
            }
        }
    }
    
    public let environment: Environment
    public let baseURL: URL
    public let apiVersion: String
    
    public init(
        environment: Environment = .production,
        customBaseURL: URL? = nil,
        apiVersion: String = "v1"
    ) {
        self.environment = environment
        self.baseURL = customBaseURL ?? environment.defaultBaseURL
        self.apiVersion = apiVersion
    }
    
    public static let shared = APIConfiguration()
}
