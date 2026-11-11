import SwiftUI

@main
struct ProductivityOSApp: App {
    @State private var authSession = AuthSession.shared

    var body: some Scene {
        WindowGroup {
            // AuthSession is observable: login/logout flips the root automatically.
            Group {
                if authSession.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            // DEBUG builds: shake or edge-swipe to open the API request log.
            .devGestureToOpenRequestLog()
        }
    }
}
