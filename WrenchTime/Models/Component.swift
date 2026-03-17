import Foundation
import SwiftData

@Model
final class Component {
    var id: UUID
    var type: ComponentType
    var name: String
    var installedDate: Date
    var distanceAtInstall: Double
    var replacementThresholdMiles: Double
    var notes: String

    var bike: Bike?

    /// Miles ridden since this component was installed
    var currentMiles: Double {
        guard let bike else { return 0 }
        return max(0, (bike.totalDistanceMeters - distanceAtInstall) / 1609.34)
    }

    /// Wear as a fraction from 0.0 to 1.0
    var wearPercentage: Double {
        guard replacementThresholdMiles > 0 else { return 0 }
        return min(currentMiles / replacementThresholdMiles, 1.0)
    }

    /// Component has reached or exceeded replacement threshold
    var isDue: Bool {
        currentMiles >= replacementThresholdMiles
    }

    /// Component is at 85%+ of replacement threshold but not yet due
    var isApproaching: Bool {
        wearPercentage >= 0.85
    }

    /// Miles remaining until replacement
    var milesRemaining: Double {
        max(0, replacementThresholdMiles - currentMiles)
    }

    init(
        type: ComponentType,
        name: String? = nil,
        installedDate: Date = Date(),
        distanceAtInstall: Double = 0,
        replacementThresholdMiles: Double? = nil,
        notes: String = ""
    ) {
        self.id = UUID()
        self.type = type
        self.name = name ?? type.displayName
        self.installedDate = installedDate
        self.distanceAtInstall = distanceAtInstall
        self.replacementThresholdMiles = replacementThresholdMiles ?? type.defaultThresholdMiles
        self.notes = notes
    }
}
