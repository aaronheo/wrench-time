import SwiftUI
import SwiftData

struct AddBikeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brandName = ""
    @State private var modelName = ""
    @State private var isPrimary = false
    @State private var addDefaultComponents = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Bike Details") {
                    TextField("Bike Name", text: $name)
                    TextField("Brand (optional)", text: $brandName)
                    TextField("Model (optional)", text: $modelName)
                    Toggle("Primary Bike", isOn: $isPrimary)
                }

                Section {
                    Toggle("Add Default Components", isOn: $addDefaultComponents)
                } footer: {
                    Text("Adds chain, tires, brake pads, and cassette with standard replacement intervals.")
                }
            }
            .navigationTitle("Add Bike")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addBike()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addBike() {
        let bike = Bike(
            name: name.trimmingCharacters(in: .whitespaces),
            brandName: brandName.trimmingCharacters(in: .whitespaces),
            modelName: modelName.trimmingCharacters(in: .whitespaces),
            isPrimary: isPrimary
        )
        modelContext.insert(bike)

        if addDefaultComponents {
            for componentType in ComponentType.defaultBikeComponents {
                let component = Component(type: componentType)
                component.bike = bike
                modelContext.insert(component)
            }
        }

        dismiss()
    }
}
