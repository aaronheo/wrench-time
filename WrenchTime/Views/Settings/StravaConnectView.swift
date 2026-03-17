import SwiftUI
import SwiftData

struct StravaConnectView: View {
    @EnvironmentObject private var stravaAuth: StravaAuthService
    @Environment(\.modelContext) private var modelContext

    @State private var syncService: StravaSyncService?
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        List {
            if stravaAuth.isAuthenticated {
                // Connected state
                Section("Status") {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Connected to Strava")
                    }

                    if let name = stravaAuth.athleteName, !name.isEmpty {
                        LabeledContent("Athlete", value: name)
                    }
                }

                Section {
                    Button {
                        Task { await syncFromStrava() }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync Now")
                            Spacer()
                            if syncService?.isSyncing == true {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(syncService?.isSyncing == true)
                }

                Section {
                    Button(role: .destructive) {
                        stravaAuth.disconnect()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Disconnect Strava")
                        }
                    }
                }
            } else {
                // Disconnected state
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.outdoor.cycle")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)

                        Text("Connect your Strava account to automatically sync your bikes and mileage.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            Task { await connectStrava() }
                        } label: {
                            HStack {
                                Text("Connect with Strava")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(stravaAuth.isLoading)

                        if stravaAuth.isLoading {
                            ProgressView("Connecting...")
                        }
                    }
                    .padding(.vertical)
                }
            }

            Section("Info") {
                Text("WrenchTime uses Strava to read your bike and gear data. We only access your gear information and activity distances — never GPS data or personal details.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Strava")
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if syncService == nil {
                let apiClient = StravaAPIClient(authService: stravaAuth)
                syncService = StravaSyncService(apiClient: apiClient)
            }
        }
    }

    private func connectStrava() async {
        do {
            try await stravaAuth.authenticate()
            await syncFromStrava()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func syncFromStrava() async {
        await syncService?.syncBikes(modelContext: modelContext)
        if let error = syncService?.lastError {
            errorMessage = error
            showError = true
        }
    }
}
