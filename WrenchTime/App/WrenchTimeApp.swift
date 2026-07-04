import SwiftUI
import SwiftData

@main
struct WrenchTimeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let container: ModelContainer
    @StateObject private var auth = AuthService()
    @StateObject private var stravaAuth = StravaAuthService()
    @StateObject private var storeKit = StoreKitService()
    @StateObject private var syncEngine: SyncEngine

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Bike.self, Component.self, MaintenanceRecord.self, RideSync.self, UserSettings.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        self.container = container
        _syncEngine = StateObject(wrappedValue: SyncEngine(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(stravaAuth)
                .environmentObject(storeKit)
                .environmentObject(syncEngine)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task {
                            await storeKit.checkEntitlement()
                            if auth.isAuthenticated {
                                await syncEngine.pullFromServer()
                            }
                        }
                    }
                }
        }
        .modelContainer(container)
    }
}
