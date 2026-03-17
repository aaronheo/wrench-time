import SwiftUI

struct ContentView: View {
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Bike.self, Component.self, MaintenanceRecord.self, RideSync.self, UserSettings.self], inMemory: true)
        .environmentObject(StravaAuthService())
        .environmentObject(StoreKitService())
}
