import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Bike.isPrimary, order: .reverse) private var bikes: [Bike]
    @EnvironmentObject private var stravaAuth: StravaAuthService
    @Environment(\.modelContext) private var modelContext

    @State private var syncService: StravaSyncService?

    var body: some View {
        NavigationStack {
            ScrollView {
                if bikes.isEmpty {
                    EmptyStateView(
                        icon: "bicycle",
                        title: "Welcome to WrenchTime",
                        message: "Connect Strava or add a bike manually to get started."
                    )
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        // Mileage summary cards
                        ForEach(bikes) { bike in
                            MileageSummaryCard(bike: bike)
                        }

                        // Alerts section
                        let alerts = allAlerts
                        if !alerts.isEmpty {
                            Section {
                                ForEach(alerts, id: \.component.id) { alert in
                                    AlertCard(
                                        bike: alert.bike,
                                        component: alert.component
                                    )
                                }
                            } header: {
                                HStack {
                                    Text("Maintenance Alerts")
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await syncFromStrava()
            }
            .toolbar {
                if syncService?.isSyncing == true {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ProgressView()
                    }
                }
            }
        }
        .onAppear {
            if syncService == nil {
                let apiClient = StravaAPIClient(authService: stravaAuth)
                syncService = StravaSyncService(apiClient: apiClient)
            }
        }
    }

    private struct BikeAlert {
        let bike: Bike
        let component: Component
    }

    private var allAlerts: [BikeAlert] {
        bikes.flatMap { bike in
            bike.componentsByUrgency
                .filter { $0.isApproaching || $0.isDue }
                .map { BikeAlert(bike: bike, component: $0) }
        }
    }

    private func syncFromStrava() async {
        guard stravaAuth.isAuthenticated else { return }
        await syncService?.syncBikes(modelContext: modelContext)
    }
}
