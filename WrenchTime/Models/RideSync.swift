import Foundation
import SwiftData

@Model
final class RideSync {
    var id: UUID
    var syncDate: Date
    var bikeStravaGearId: String
    var previousDistanceMeters: Double
    var newDistanceMeters: Double
    var deltaMeters: Double

    var deltaMiles: Double {
        deltaMeters / 1609.34
    }

    init(
        bikeStravaGearId: String,
        previousDistanceMeters: Double,
        newDistanceMeters: Double
    ) {
        self.id = UUID()
        self.syncDate = Date()
        self.bikeStravaGearId = bikeStravaGearId
        self.previousDistanceMeters = previousDistanceMeters
        self.newDistanceMeters = newDistanceMeters
        self.deltaMeters = newDistanceMeters - previousDistanceMeters
    }
}
