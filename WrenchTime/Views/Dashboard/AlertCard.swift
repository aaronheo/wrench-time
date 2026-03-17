import SwiftUI

struct AlertCard: View {
    let bike: Bike
    let component: Component

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: component.type.iconName)
                .font(.title3)
                .foregroundStyle(component.isDue ? .red : .orange)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(component.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(bike.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                WearProgressBar(percentage: component.wearPercentage, height: 6)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(Int(component.wearPercentage * 100).percentFormatted)
                    .font(.headline)
                    .foregroundStyle(component.isDue ? .red : .orange)

                Text(component.isDue ? "Replace now" : "\(Int(component.milesRemaining)) mi left")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(component.isDue ? Color.red.opacity(0.08) : Color.orange.opacity(0.08))
        )
    }
}
