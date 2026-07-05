import SwiftUI
import SwiftData

struct MaintenanceListView: View {
    @Query(sort: \MaintenanceRecord.date, order: .reverse) private var records: [MaintenanceRecord]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var stravaAuth: StravaAuthService

    @State private var selectedRecord: MaintenanceRecord?

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    EmptyStateView(
                        icon: "wrench.and.screwdriver",
                        title: "No Maintenance Logged",
                        message: "When you replace a component, it will appear here."
                    )
                } else {
                    List {
                        ForEach(groupedByMonth, id: \.key) { month, monthRecords in
                            Section(month) {
                                ForEach(monthRecords) { record in
                                    MaintenanceRowView(record: record)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedRecord = record
                                        }
                                }
                                .onDelete { offsets in
                                    deleteRecords(offsets, from: monthRecords)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Maintenance")
            .sheet(item: $selectedRecord) { record in
                EditMaintenanceView(record: record)
            }
        }
    }

    private func deleteRecords(_ offsets: IndexSet, from monthRecords: [MaintenanceRecord]) {
        for index in offsets {
            let record = monthRecords[index]
            Task { await rollBackComponent(for: record) }
        }
    }

    /// If the deleted record is the most recent replacement for that component,
    /// recalculate the component's install distance using Strava data.
    @MainActor
    private func rollBackComponent(for record: MaintenanceRecord) async {
        guard let bike = record.bike else { return }

        // Find all records for this component type on this bike, sorted newest first
        let matchingRecords = records
            .filter { $0.bike?.id == bike.id && $0.componentType == record.componentType }
            .sorted { $0.date > $1.date }

        // Only roll back if this is the most recent record
        guard matchingRecords.first?.id == record.id else {
            modelContext.delete(record)
            return
        }

        // Find the component via direct query (relationships may not be loaded)
        let bikeId = bike.id
        let componentType = record.componentType
        var descriptor = FetchDescriptor<Component>(
            predicate: #Predicate { $0.bike?.id == bikeId && $0.type == componentType }
        )
        descriptor.fetchLimit = 1
        guard let component = try? modelContext.fetch(descriptor).first else {
            modelContext.delete(record)
            return
        }

        // Find the previous maintenance record (the one before the deleted one)
        let previousRecord = matchingRecords.dropFirst().first
        let installDate = previousRecord?.date ?? bike.dateAdded

        // Recalculate distanceAtInstall using Strava rides since the install date
        if let gearId = bike.stravaGearId, stravaAuth.isAuthenticated {
            let apiClient = StravaAPIClient(authService: stravaAuth)
            let distanceSinceInstall = (try? await apiClient.getNonVirtualDistance(
                gearId: gearId,
                after: installDate
            )) ?? 0
            component.distanceAtInstall = bike.totalDistanceMeters - distanceSinceInstall
        } else if let previousRecord {
            component.distanceAtInstall = previousRecord.distanceAtReplacement
        } else {
            component.distanceAtInstall = 0
        }
        component.installedDate = installDate

        modelContext.delete(record)
    }

    private var groupedByMonth: [(key: String, value: [MaintenanceRecord])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: records) { record in
            formatter.string(from: record.date)
        }

        return grouped.sorted { first, second in
            guard let firstDate = first.value.first?.date,
                  let secondDate = second.value.first?.date else { return false }
            return firstDate > secondDate
        }
    }
}

private struct MaintenanceRowView: View {
    let record: MaintenanceRecord

    var body: some View {
        HStack {
            Image(systemName: record.componentType.iconName)
                .foregroundStyle(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.componentType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let bike = record.bike {
                    Text(bike.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !record.partName.isEmpty {
                    Text(record.partName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.date.shortFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let cost = record.cost {
                    Text(cost.formattedCurrency)
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Text("@ \(record.distanceAtReplacementMiles.formattedMiles)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
