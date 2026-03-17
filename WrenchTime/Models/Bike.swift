import Foundation
import SwiftData

@Model
final class Bike {
    var id: UUID
    var name: String
    var brandName: String
    var modelName: String
    var stravaGearId: String?
    var totalDistanceMeters: Double
    var isPrimary: Bool
    var dateAdded: Date
    var lastSyncDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \Component.bike)
    var components: [Component] = []

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceRecord.bike)
    var maintenanceRecords: [MaintenanceRecord] = []

    var totalDistanceMiles: Double {
        totalDistanceMeters / 1609.34
    }

    /// Components sorted by wear percentage, most worn first
    var componentsByUrgency: [Component] {
        components.sorted { $0.wearPercentage > $1.wearPercentage }
    }

    /// Components that are at or past replacement threshold
    var dueComponents: [Component] {
        components.filter { $0.isDue }
    }

    /// Components approaching replacement threshold (>=85%)
    var approachingComponents: [Component] {
        components.filter { $0.isApproaching && !$0.isDue }
    }

    init(
        name: String,
        brandName: String = "",
        modelName: String = "",
        stravaGearId: String? = nil,
        totalDistanceMeters: Double = 0,
        isPrimary: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.brandName = brandName
        self.modelName = modelName
        self.stravaGearId = stravaGearId
        self.totalDistanceMeters = totalDistanceMeters
        self.isPrimary = isPrimary
        self.dateAdded = Date()
    }
}
