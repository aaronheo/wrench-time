import Foundation
import SwiftData

enum DistanceUnit: String, Codable {
    case miles
    case kilometers

    var abbreviation: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }

    var conversionFromMeters: Double {
        switch self {
        case .miles: return 1609.34
        case .kilometers: return 1000.0
        }
    }
}

@Model
final class UserSettings {
    var id: UUID
    var isPremium: Bool
    var stravaConnected: Bool
    var stravaAthleteId: Int?
    var distanceUnit: DistanceUnit
    var notificationsEnabled: Bool
    var lastFullSyncDate: Date?
    var maxFreeBikes: Int

    init() {
        self.id = UUID()
        self.isPremium = false
        self.stravaConnected = false
        self.distanceUnit = .miles
        self.notificationsEnabled = true
        self.maxFreeBikes = 1
    }
}
