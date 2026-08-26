import Foundation

/// Focus session duration options matching `focsu-flow.png`
public enum FocusDuration: Int, CaseIterable, Identifiable, Codable, Sendable {
    case pomodoro25 = 1500  // 25 min
    case deepWork45 = 2700  // 45 min
    case focused60 = 3600   // 60 min
    case unlimited = 0      // Unlimited / Open-ended
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .pomodoro25: return "25 min"
        case .deepWork45: return "45 min"
        case .focused60: return "60 min"
        case .unlimited: return "∞"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .pomodoro25: return "Pomodoro"
        case .deepWork45: return "Deep Work"
        case .focused60: return "Focused"
        case .unlimited: return "Unlimited"
        }
    }
    
    public var totalSeconds: Int {
        rawValue
    }
    
    public var isUnlimited: Bool {
        self == .unlimited
    }
}
