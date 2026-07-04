import SwiftUI

/// Top-level gate: shows the app when authenticated, the sign-in screen otherwise.
/// Sign-in is required. Drives the sync engine on auth transitions.
struct RootView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var syncEngine: SyncEngine
    @State private var didAttemptRestore = false

    var body: some View {
        Group {
            if auth.isAuthenticated {
                ContentView()
            } else if didAttemptRestore {
                SignInView()
            } else {
                // Brief window while we refresh any persisted session on launch.
                ProgressView()
            }
        }
        .task {
            await auth.restoreSession()
            didAttemptRestore = true
            if auth.isAuthenticated {
                syncEngine.start()
                await syncEngine.pullFromServer()
            }
        }
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                syncEngine.start()
                Task { await syncEngine.pullFromServer() }
            } else {
                syncEngine.handleSignOut()
            }
        }
    }
}
