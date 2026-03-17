import SwiftUI
import SwiftData

struct MaintenanceListView: View {
    @Query(sort: \MaintenanceRecord.date, order: .reverse) private var records: [MaintenanceRecord]

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
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Maintenance")
        }
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
