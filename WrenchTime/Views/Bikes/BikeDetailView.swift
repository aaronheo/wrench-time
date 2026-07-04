import SwiftUI
import SwiftData

struct BikeDetailView: View {
    @Bindable var bike: Bike
    @Query private var components: [Component]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddComponent = false
    @State private var showLogMaintenance = false
    @State private var selectedComponent: Component?

    init(bike: Bike) {
        self._bike = .init(wrappedValue: bike)
        let bikeId = bike.id
        _components = Query(filter: #Predicate<Component> { $0.bike?.id == bikeId })
    }

    private var componentsByUrgency: [Component] {
        components.sorted { $0.wearPercentage > $1.wearPercentage }
    }

    var body: some View {
        List {
            // Bike info section
            Section("Bike Info") {
                LabeledContent("Total Distance", value: bike.totalDistanceMiles.formattedMiles)
                if !bike.brandName.isEmpty {
                    LabeledContent("Brand", value: bike.brandName)
                }
                if !bike.modelName.isEmpty {
                    LabeledContent("Model", value: bike.modelName)
                }
                Picker("Brakes", selection: Binding(
                    get: { bike.brakeType },
                    set: { newType in
                        bike.brakeTypeRaw = newType
                        for component in components where component.type == .brakePadsFront || component.type == .brakePadsRear {
                            component.replacementThresholdMiles = component.type.defaultThresholdMiles(brakeType: newType)
                        }
                    }
                )) {
                    ForEach(BrakeType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                LabeledContent("Added", value: bike.dateAdded.shortFormatted)
                if let lastSync = bike.lastSyncDate {
                    LabeledContent("Last Sync", value: lastSync.relativeDescription)
                }
            }

            // Components section
            Section {
                if components.isEmpty {
                    Text("No components tracked")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(componentsByUrgency) { component in
                        ComponentRow(component: component)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedComponent = component
                                showLogMaintenance = true
                            }
                    }
                    .onDelete(perform: deleteComponents)
                }
            } header: {
                HStack {
                    Text("Components")
                    Spacer()
                    Button {
                        showAddComponent = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }

            // Recent maintenance section
            if !bike.maintenanceRecords.isEmpty {
                Section("Recent Maintenance") {
                    let recentRecords = bike.maintenanceRecords
                        .sorted { $0.date > $1.date }
                        .prefix(5)

                    ForEach(Array(recentRecords)) { record in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(record.componentType.displayName)
                                    .font(.subheadline)
                                Text(record.date.shortFormatted)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let cost = record.cost {
                                Text(cost.formattedCurrency)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(bike.name)
        .sheet(isPresented: $showAddComponent) {
            AddComponentSheet(bike: bike)
        }
        .sheet(isPresented: $showLogMaintenance) {
            if let component = selectedComponent {
                LogMaintenanceView(bike: bike, component: component)
            }
        }
    }

    private func deleteComponents(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(componentsByUrgency[index])
        }
    }
}

// MARK: - Add Component Sheet

private struct AddComponentSheet: View {
    let bike: Bike
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: ComponentType = .chain
    @State private var customName = ""
    @State private var thresholdMiles: Double = 2000

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $selectedType) {
                    ForEach(ComponentType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .onChange(of: selectedType) { _, newType in
                    thresholdMiles = newType.defaultThresholdMiles(brakeType: bike.brakeType)
                    customName = newType.displayName
                }

                if selectedType == .custom {
                    TextField("Component Name", text: $customName)
                }

                HStack {
                    Text("Replace at")
                    Spacer()
                    TextField("Miles", value: $thresholdMiles, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text("mi")
                }
            }
            .navigationTitle("Add Component")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let component = Component(
                            type: selectedType,
                            name: selectedType == .custom ? customName : nil,
                            distanceAtInstall: bike.totalDistanceMeters,
                            replacementThresholdMiles: thresholdMiles
                        )
                        component.bike = bike
                        modelContext.insert(component)
                        dismiss()
                    }
                }
            }
            .onAppear {
                thresholdMiles = selectedType.defaultThresholdMiles(brakeType: bike.brakeType)
                customName = selectedType.displayName
            }
        }
    }
}
