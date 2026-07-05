import Foundation
import SwiftData

@Model
final class Bike {
    var id: UUID
    var name: String
    var brandName: String
    var modelName: String
    var stravaGearId: String?
    var brakeTypeRaw: BrakeType?
    var totalDistanceMeters: Double
    var isPrimary: Bool
    var isWaxedChain: Bool = false
    /// The bike's odometer reading (meters) when the chain was last waxed.
    var lastWaxedAtMeters: Double = 0
    var dateAdded: Date
    var lastSyncDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \Component.bike)
    var components: [Component] = []

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceRecord.bike)
    var maintenanceRecords: [MaintenanceRecord] = []

    var brakeType: BrakeType {
        get { brakeTypeRaw ?? .disc }
        set { brakeTypeRaw = newValue }
    }

    var totalDistanceMiles: Double {
        totalDistanceMeters / 1609.34
    }

    // MARK: - Chain wax (only meaningful when isWaxedChain)

    /// Miles ridden since the chain was last waxed.
    var milesSinceWax: Double {
        max(0, (totalDistanceMeters - lastWaxedAtMeters) / 1609.34)
    }

    /// Miles remaining until the chain should be rewaxed.
    var milesUntilRewax: Double {
        max(0, Constants.Chain.rewaxIntervalMiles - milesSinceWax)
    }

    /// Wear toward the next rewax, from 0.0 to 1.0.
    var waxWearPercentage: Double {
        min(milesSinceWax / Constants.Chain.rewaxIntervalMiles, 1.0)
    }

    /// The chain is waxed and due (or overdue) for a rewax.
    var isRewaxDue: Bool {
        isWaxedChain && milesSinceWax >= Constants.Chain.rewaxIntervalMiles
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
        brakeType: BrakeType = .disc,
        totalDistanceMeters: Double = 0,
        isPrimary: Bool = false,
        isWaxedChain: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.brandName = brandName
        self.modelName = modelName
        self.stravaGearId = stravaGearId
        self.brakeTypeRaw = brakeType
        self.totalDistanceMeters = totalDistanceMeters
        self.isPrimary = isPrimary
        self.isWaxedChain = isWaxedChain
        self.lastWaxedAtMeters = isWaxedChain ? totalDistanceMeters : 0
        self.dateAdded = Date()
    }
}
