import SwiftUI

struct MileageSummaryCard: View {
    let bike: Bike

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bicycle")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading) {
                    Text(bike.name)
                        .font(.headline)

                    if !bike.brandName.isEmpty || !bike.modelName.isEmpty {
                        Text([bike.brandName, bike.modelName].filter { !$0.isEmpty }.joined(separator: " "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if bike.isPrimary {
                    Text("Primary")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Total Distance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(bike.totalDistanceMiles.formattedMiles)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Components")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    let dueCount = bike.dueComponents.count
                    let approachingCount = bike.approachingComponents.count

                    if dueCount > 0 {
                        Text("\(dueCount) due")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    } else if approachingCount > 0 {
                        Text("\(approachingCount) soon")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                    } else {
                        Text("All good")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
            }

            if let lastSync = bike.lastSyncDate {
                Text("Synced \(lastSync.relativeDescription)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
