import SwiftUI
import SwiftData

struct EditMaintenanceView: View {
    let record: MaintenanceRecord

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stravaAuth: StravaAuthService

    @State private var partName: String
    @State private var cost: Double?
    @State private var notes: String
    @State private var date: Date
    @State private var isSaving = false

    init(record: MaintenanceRecord) {
        self.record = record
        _partName = State(initialValue: record.partName)
        _cost = State(initialValue: record.cost)
        _notes = State(initialValue: record.notes)
        _date = State(initialValue: record.date)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Component") {
                    LabeledContent("Type", value: record.componentType.displayName)
                    if let bike = record.bike {
                        LabeledContent("Bike", value: bike.name)
                    }
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
            }
            .navigationTitle("Edit Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveChanges() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func saveChanges() async {
        isSaving = true
        defer { isSaving = false }

        let dateChanged = date != record.date

        // Update record fields
        record.partName = partName
        record.cost = cost
        record.notes = notes
        record.date = date

        // If the date changed, recalculate the distance at replacement
        if dateChanged, let bike = record.bike {
            let currentDistance = bike.totalDistanceMeters

            var distanceSinceReplacement = 0.0
            if let gearId = bike.stravaGearId, stravaAuth.isAuthenticated {
                let apiClient = StravaAPIClient(authService: stravaAuth)
                distanceSinceReplacement = (try? await apiClient.getNonVirtualDistance(
                    gearId: gearId,
                    after: date
                )) ?? 0
            }

            let distanceAtInstall = currentDistance - distanceSinceReplacement
            record.distanceAtReplacement = distanceAtInstall

            // If this is the most recent record for this component, update the component too
            let bikeId = bike.id
            let componentType = record.componentType
            var maintenanceDescriptor = FetchDescriptor<MaintenanceRecord>(
                predicate: #Predicate { $0.bike?.id == bikeId && $0.componentType == componentType }
            )
            let allRecords = (try? modelContext.fetch(maintenanceDescriptor)) ?? []
            let mostRecent = allRecords.sorted { $0.date > $1.date }.first

            if mostRecent?.id == record.id {
                var componentDescriptor = FetchDescriptor<Component>(
                    predicate: #Predicate { $0.bike?.id == bikeId && $0.type == componentType }
                )
                componentDescriptor.fetchLimit = 1
                if let component = try? modelContext.fetch(componentDescriptor).first {
                    component.distanceAtInstall = distanceAtInstall
                    component.installedDate = date
                }
            }
        }

        dismiss()
    }
}
