import Foundation

// MARK: - Response DTOs (mirror the backend's camelCase JSON)

struct BikeDTO: Codable, Identifiable {
    let id: UUID
    let name: String
    let brandName: String
    let modelName: String
    let stravaGearId: String?
    let brakeType: String
    let totalDistanceMeters: Double
    let isPrimary: Bool
    let dateAdded: Date
    let lastSyncDate: Date?
}

struct ComponentDTO: Codable, Identifiable {
    let id: UUID
    let bikeId: UUID
    let type: String
    let name: String
    let installedDate: Date
    let distanceAtInstall: Double
    let replacementThresholdMiles: Double
    let notes: String
}

struct MaintenanceDTO: Codable, Identifiable {
    let id: UUID
    let bikeId: UUID
    let componentType: String
    let date: Date
    let distanceAtReplacement: Double
    let cost: Double?
    let notes: String
    let partName: String
}

/// GET /api/bikes/:id — bike plus its nested collections.
struct BikeDetailDTO: Codable, Identifiable {
    let id: UUID
    let name: String
    let brandName: String
    let modelName: String
    let stravaGearId: String?
    let brakeType: String
    let totalDistanceMeters: Double
    let isPrimary: Bool
    let dateAdded: Date
    let lastSyncDate: Date?
    let components: [ComponentDTO]
    let maintenanceRecords: [MaintenanceDTO]
}

struct RideSyncDTO: Codable, Identifiable {
    let id: UUID
    let syncDate: Date
    let bikeStravaGearId: String
    let previousDistanceMeters: Double
    let newDistanceMeters: Double
    let deltaMeters: Double
}

struct SettingsDTO: Codable {
    let isPremium: Bool
    let stravaConnected: Bool
    let stravaAthleteId: Int?
    let distanceUnit: String
    let notificationsEnabled: Bool
    let lastFullSyncDate: Date?
    let maxFreeBikes: Int
}

// MARK: - Request DTOs
// Optional fields encode as absent (Codable omits nil), matching the API's
// "only update provided fields" PATCH semantics.

struct BikeCreate: Encodable {
    var id: UUID?
    var name: String
    var brandName: String
    var modelName: String
    var stravaGearId: String?
    var brakeType: String
    var totalDistanceMeters: Double
    var isPrimary: Bool
    var dateAdded: Date?
    var lastSyncDate: Date?
}

struct BikePatch: Encodable {
    var name: String?
    var brandName: String?
    var modelName: String?
    var stravaGearId: String?
    var brakeType: String?
    var totalDistanceMeters: Double?
    var isPrimary: Bool?
    var lastSyncDate: Date?
}

struct ComponentCreate: Encodable {
    var id: UUID?
    var type: String
    var name: String
    var installedDate: Date?
    var distanceAtInstall: Double
    var replacementThresholdMiles: Double
    var notes: String
}

struct ComponentPatch: Encodable {
    var type: String?
    var name: String?
    var installedDate: Date?
    var distanceAtInstall: Double?
    var replacementThresholdMiles: Double?
    var notes: String?
}

struct MaintenanceCreate: Encodable {
    var id: UUID?
    var componentType: String
    var date: Date?
    var distanceAtReplacement: Double
    var cost: Double?
    var notes: String
    var partName: String
}

struct MaintenancePatch: Encodable {
    var componentType: String?
    var date: Date?
    var distanceAtReplacement: Double?
    var cost: Double?
    var notes: String?
    var partName: String?
}

struct RideCreate: Encodable {
    var id: UUID?
    var syncDate: Date?
    var bikeStravaGearId: String
    var previousDistanceMeters: Double
    var newDistanceMeters: Double
    var deltaMeters: Double?
}

struct SettingsUpsert: Encodable {
    var isPremium: Bool?
    var stravaConnected: Bool?
    var stravaAthleteId: Int?
    var distanceUnit: String?
    var notificationsEnabled: Bool?
    var lastFullSyncDate: Date?
    var maxFreeBikes: Int?
}

// MARK: - Sync snapshot (GET/POST /api/sync)
// Full dataset exchanged in one round-trip for the local-cache mirror.

struct SyncSnapshot: Codable {
    var bikes: [SyncBike]
    var components: [SyncComponent]
    var maintenance: [SyncMaintenance]
}

struct SyncBike: Codable {
    var id: UUID
    var name: String
    var brandName: String
    var modelName: String
    var stravaGearId: String?
    var brakeType: String
    var totalDistanceMeters: Double
    var isPrimary: Bool
    var dateAdded: Date
    var lastSyncDate: Date?
}

struct SyncComponent: Codable {
    var id: UUID
    var bikeId: UUID
    var type: String
    var name: String
    var installedDate: Date
    var distanceAtInstall: Double
    var replacementThresholdMiles: Double
    var notes: String
}

struct SyncMaintenance: Codable {
    var id: UUID
    var bikeId: UUID
    var componentType: String
    var date: Date
    var distanceAtReplacement: Double
    var cost: Double?
    var notes: String
    var partName: String
}
