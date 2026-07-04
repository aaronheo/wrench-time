import SwiftUI
import SwiftData

struct LogMaintenanceView: View {
    let bike: Bike
    let component: Component

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stravaAuth: StravaAuthService

    @State private var partName = ""
    @State private var cost: Double?
    @State private var notes = ""
    @State private var date = Date()
    @State private var showAffiliateLinks = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Component") {
                    LabeledContent("Type", value: component.type.displayName)
                    LabeledContent("Bike", value: bike.name)
                    LabeledContent("Current Miles", value: Int(component.currentMiles).description)
                }

                Section("Replacement Details") {
                    TextField("Part Name (optional)", text: $partName)
                    HStack {
                        Text("Cost")
                        Spacer()
                        TextField("$0.00", value: $cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }

                Section {
                    Button {
                        showAffiliateLinks = true
                    } label: {
                        Label("Shop for Parts", systemImage: "cart")
                    }
                }
            }
            .navigationTitle("Log Replacement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await logMaintenance() }
                    }
                    .disabled(isSaving)
                }
            }
            .sheet(isPresented: $showAffiliateLinks) {
                AffiliateLinksView(componentType: component.type)
            }
        }
    }

    private func logMaintenance() async {
        isSaving = true
        defer { isSaving = false }

        let currentDistance = bike.totalDistanceMeters

        // Calculate distance ridden since the replacement date
        // so backdated replacements show correct mileage
        var distanceSinceReplacement = 0.0
        if let gearId = bike.stravaGearId, stravaAuth.isAuthenticated {
            let apiClient = StravaAPIClient(authService: stravaAuth)
            distanceSinceReplacement = (try? await apiClient.getNonVirtualDistance(
                gearId: gearId,
                after: date
            )) ?? 0
        }

        let distanceAtInstall = currentDistance - distanceSinceReplacement

        // Create maintenance record
        let record = MaintenanceRecord(
            componentType: component.type,
            date: date,
            distanceAtReplacement: distanceAtInstall,
            cost: cost,
            notes: notes,
            partName: partName
        )
        record.bike = bike
        modelContext.insert(record)

        // Reset this component — installed at the bike's distance on the replacement date
        component.distanceAtInstall = distanceAtInstall
        component.installedDate = date

        dismiss()
    }
}
