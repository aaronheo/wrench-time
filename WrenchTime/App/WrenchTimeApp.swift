import SwiftUI
import SwiftData

@main
struct WrenchTimeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var stravaAuth = StravaAuthService()
    @StateObject private var storeKit = StoreKitService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stravaAuth)
                .environmentObject(storeKit)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task {
                            await storeKit.checkEntitlement()
                        }
                    }
                }
        }
        .modelContainer(for: [
            Bike.self,
            Component.self,
            MaintenanceRecord.self,
            RideSync.self,
            UserSettings.self
        ])
    }
}
