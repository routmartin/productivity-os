import SwiftUI
import AppKit
import ApplicationServices
import OSLog
import UserNotifications
import ProductivityOS

/// Menu bar app entry point for the macOS Focus Companion.
///
/// URL scheme handling lives in `AppDelegate` via `NSAppleEventManager`
/// (the classic `kInternetEventClass`/`kAEGetURL` handler). SwiftUI's
/// `.onOpenURL` only fires while the menu bar popover is open, and plain
/// `application(_:open:)` delivery is unreliable for `LSUIElement` apps,
/// so neither reaches `productivityos://auth?challenge=...` links reliably.
/// The delegate receives them at the application level, regardless of
/// popover or running state.
@main
struct MacCompanionApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var authSession: AuthSession

    init() {
        _authSession = State(initialValue: AuthSession.shared)
    }

    var body: some Scene {
        MenuBarExtra {
            FocusPopoverView()
                .environment(\.macAuthCoordinator, appDelegate.coordinator)
        } label: {
            Text(menuBarLabel)
        }
        .menuBarExtraStyle(.menu)
    }

    private var menuBarLabel: String {
        // Phase 5 keeps the label static; live timer ticks are in the
        // popover. A future iteration can drive the label from
        // FocusCompanionState.elapsedSeconds when there's an active
        // session.
        if authSession.isAuthenticated {
            return "P/OS · on"
        } else {
            return "P/OS"
        }
    }
}

// MARK: - App delegate (URL scheme routing)

/// Plain `NSObject` (not actor-isolated): `@NSApplicationDelegateAdaptor`
/// historically fails to install the delegate when the class is annotated
/// `@MainActor`, and without the delegate the app never receives
/// `applicationDidFinishLaunching` or `application(_:open:)`. The SwiftUI
/// runtime calls these on the main thread, so no isolation is needed.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The Mac companion pairs with challenges issued by the backend that the
    /// web app is logged into. Locally that's the Vite dev proxy's target
    /// (`http://localhost:8080`, see `apps/web/vite.config.ts`); the global
    /// `APIClient.shared` defaults to production, which would reject local
    /// challenges. Keep an explicit development client for now.
    lazy var coordinator: MacAuthCoordinator = {
        let devConfig = APIConfiguration(environment: .development)
        let devClient = APIClient(config: devConfig)
        return MacAuthCoordinator(apiClient: devClient)
    }()
    private let log = Logger(subsystem: "com.productivityos.mac", category: "URLScheme")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue ?? ""
        guard urlString.hasPrefix("productivityos://") else { return }
        authenticate(urlString: urlString)
    }

    func application(_ sender: NSApplication, open urls: [URL]) {
        for url in urls where url.absoluteString.hasPrefix("productivityos://") {
            authenticate(urlString: url.absoluteString)
        }
    }

    private func authenticate(urlString: String) {
        log.info("Exchanging challenge from URL…")
        Task {
            let result = await coordinator.handle(urlString: urlString)
            switch result {
            case .authenticated(let email):
                log.info("Authenticated as \(email, privacy: .private)")
                postAuthCompleted(email: email, success: true)
            default:
                log.error("Auth failed: \(String(describing: result), privacy: .public)")
                postAuthCompleted(email: nil, success: false)
            }
            notify(result: result)
        }
    }

    /// Surface the outcome of a pairing attempt immediately. The popover is
    /// usually closed when the user clicks a `productivityos://` link, so a
    /// Notification Center banner is the only feedback that is actually seen.
    private func notify(result: MacAuthResult) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            let content = UNMutableNotificationContent()
            switch result {
            case .authenticated(let email):
                content.title = "Connected to \(email)"
                content.body = "Your Mac companion is now linked."
            default:
                content.title = "Pairing failed"
                content.body = Self.failureBody(for: result)
            }
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                center.add(request)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    guard granted else { return }
                    center.add(request)
                }
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }

    private static func failureBody(for result: MacAuthResult) -> String {
        switch result {
        case .authenticated:
            return "Linked successfully."
        case .invalidURL:
            return "Not a valid Productivity OS link."
        case .missingChallenge:
            return "The link is missing a challenge token."
        case .challengeExpired:
            return "That pairing link expired. Generate a new one on the web app."
        case .challengeAlreadyUsed:
            return "That pairing link was already used. Generate a new one."
        case .invalidChallenge:
            return "That pairing link was rejected. Generate a new one on the web app."
        case .network(let detail):
            return "Network error: \(detail)"
        case .unknown(let detail):
            return detail
        }
    }

    private func postAuthCompleted(email: String?, success: Bool) {
        var userInfo: [AnyHashable: Any] = ["success": success]
        if let email {
            userInfo["email"] = email
        }
        NotificationCenter.default.post(name: .macAuthAttemptCompleted, object: nil, userInfo: userInfo)
    }
}

extension Notification.Name {
    static let macAuthAttemptCompleted = Notification.Name("macAuthAttemptCompleted")
}

// MARK: - Environment plumbing

private struct MacAuthCoordinatorKey: EnvironmentKey {
    static let defaultValue: MacAuthCoordinator = .init()
}

extension EnvironmentValues {
    var macAuthCoordinator: MacAuthCoordinator {
        get { self[MacAuthCoordinatorKey.self] }
        set { self[MacAuthCoordinatorKey.self] = newValue }
    }
}