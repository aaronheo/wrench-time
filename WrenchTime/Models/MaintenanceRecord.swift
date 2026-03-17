import Foundation
import SwiftData

@Model
final class MaintenanceRecord {
    var id: UUID
    var componentType: ComponentType
    var date: Date
    var distanceAtReplacement: Double
    var cost: Double?
    var notes: String
    var partName: String

    var bike: Bike?

    var distanceAtReplacementMiles: Double {
        distanceAtReplacement / 1609.34
    }

    init(
        componentType: ComponentType,
        date: Date = Date(),
        distanceAtReplacement: Double,
        cost: Double? = nil,
        notes: String = "",
        partName: String = ""
    ) {
        self.id = UUID()
        self.componentType = componentType
        self.date = date
        self.distanceAtReplacement = distanceAtReplacement
        self.cost = cost
        self.notes = notes
        self.partName = partName
    }
}
