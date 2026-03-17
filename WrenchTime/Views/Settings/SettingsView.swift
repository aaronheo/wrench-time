import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArray: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var stravaAuth: StravaAuthService
    @EnvironmentObject private var storeKit: StoreKitService

    private var settings: UserSettings {
        if let existing = settingsArray.first {
            return existing
        }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        NavigationStack {
            List {
                // Strava section
                Section("Strava") {
                    NavigationLink {
                        StravaConnectView()
                    } label: {
                        HStack {
                            Image(systemName: "link")
                                .foregroundStyle(.orange)
                            Text(stravaAuth.isAuthenticated ? "Connected" : "Connect Strava")
                            Spacer()
                            if stravaAuth.isAuthenticated {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                // Preferences section
                Section("Preferences") {
                    Picker("Distance Unit", selection: Bindable(settings).distanceUnit) {
                        Text("Miles").tag(DistanceUnit.miles)
                        Text("Kilometers").tag(DistanceUnit.kilometers)
                    }

                    Toggle("Notifications", isOn: Bindable(settings).notificationsEnabled)
                        .onChange(of: settings.notificationsEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    let _ = await NotificationService().requestPermission()
                                }
                            }
                        }
                }

                // Premium section
                Section("Premium") {
                    NavigationLink {
                        PremiumUpgradeView()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(storeKit.isPremium ? "Premium Active" : "Upgrade to Premium")
                            Spacer()
                            if storeKit.isPremium {
                                Text("Active")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                // About section
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
