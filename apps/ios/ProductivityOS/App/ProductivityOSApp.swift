import SwiftUI

@main
struct ProductivityOSApp: App {
    @State private var authSession = AuthSession.shared

    var body: some Scene {
        WindowGroup {
            // AuthSession is observable: login/logout flips the root automatically.
            if authSession.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
