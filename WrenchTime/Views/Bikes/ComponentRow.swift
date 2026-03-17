import SwiftUI

struct ComponentRow: View {
    let component: Component

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: component.type.iconName)
                .font(.body)
                .foregroundStyle(statusColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(component.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(Int(component.wearPercentage * 100).percentFormatted)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor)
                }

                WearProgressBar(percentage: component.wearPercentage, height: 6)

                HStack {
                    Text("\(Int(component.currentMiles)) / \(Int(component.replacementThresholdMiles)) mi")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if component.isDue {
                        Text("Replace now")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                    } else {
                        Text("\(Int(component.milesRemaining)) mi remaining")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        if component.isDue { return .red }
        if component.isApproaching { return .orange }
        return .green
    }
}
