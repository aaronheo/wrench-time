import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var stravaAuth: StravaAuthService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.medium")
                }

            BikeListView()
                .tabItem {
                    Label("Bikes", systemImage: "bicycle")
                }

            MaintenanceListView()
                .tabItem {
                    Label("Maintenance", systemImage: "wrench.and.screwdriver")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(.orange)
        .task {
            guard stravaAuth.isAuthenticated else { return }
            let apiClient = StravaAPIClient(authService: stravaAuth)
            let syncService = StravaSyncService(apiClient: apiClient)
            await syncService.syncBikes(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Bike.self, Component.self, MaintenanceRecord.self, RideSync.self, UserSettings.self], inMemory: true)
        .environmentObject(StravaAuthService())
        .environmentObject(StoreKitService())
}
