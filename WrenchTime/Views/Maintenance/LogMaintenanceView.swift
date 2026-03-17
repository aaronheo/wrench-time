import SwiftUI
import SwiftData

struct LogMaintenanceView: View {
    let bike: Bike
    let component: Component

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var partName = ""
    @State private var cost: Double?
    @State private var notes = ""
    @State private var date = Date()
    @State private var showAffiliateLinks = false

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
                        logMaintenance()
                    }
                }
            }
            .sheet(isPresented: $showAffiliateLinks) {
                AffiliateLinksView(componentType: component.type)
            }
        }
    }

    private func logMaintenance() {
        // Create maintenance record
        let record = MaintenanceRecord(
            componentType: component.type,
            date: date,
            distanceAtReplacement: bike.totalDistanceMeters,
            cost: cost,
            notes: notes,
            partName: partName
        )
        record.bike = bike
        modelContext.insert(record)

        // Reset component wear — installed fresh at current bike distance
        component.distanceAtInstall = bike.totalDistanceMeters
        component.installedDate = date

        dismiss()
    }
}
