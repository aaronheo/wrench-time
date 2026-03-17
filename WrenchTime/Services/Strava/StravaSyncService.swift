import Foundation
import SwiftData

@MainActor
class StravaSyncService: ObservableObject {
    @Published var isSyncing = false
    @Published var lastError: String?

    private let apiClient: StravaAPIClient
    private let notificationService: NotificationService

    init(apiClient: StravaAPIClient, notificationService: NotificationService = NotificationService()) {
        self.apiClient = apiClient
        self.notificationService = notificationService
    }

    /// Sync all bikes from Strava into SwiftData
    func syncBikes(modelContext: ModelContext) async {
        guard !isSyncing else { return }

        isSyncing = true
        lastError = nil
        defer { isSyncing = false }

        do {
            let athlete = try await apiClient.getAthlete()

            for gearSummary in athlete.bikes {
                try await syncSingleBike(gearSummary: gearSummary, modelContext: modelContext)
            }

            // Update last sync date in settings
            let settingsDescriptor = FetchDescriptor<UserSettings>()
            if let settings = try? modelContext.fetch(settingsDescriptor).first {
                settings.lastFullSyncDate = Date()
                settings.stravaAthleteId = athlete.id
                settings.stravaConnected = true
            }

            try modelContext.save()

            // Evaluate notifications after sync
            await notificationService.evaluateAllComponents(modelContext: modelContext)

        } catch {
            lastError = error.localizedDescription
        }
    }

    private func syncSingleBike(gearSummary: StravaGearSummary, modelContext: ModelContext) async throws {
        // Check if bike already exists
        let gearId = gearSummary.id
        var descriptor = FetchDescriptor<Bike>(
            predicate: #Predicate { $0.stravaGearId == gearId }
        )
        descriptor.fetchLimit = 1

        let existingBikes = try modelContext.fetch(descriptor)

        if let existingBike = existingBikes.first {
            // Update existing bike
            let previousDistance = existingBike.totalDistanceMeters
            let newDistance = gearSummary.distance

            if newDistance > previousDistance {
                existingBike.totalDistanceMeters = newDistance
                existingBike.lastSyncDate = Date()

                // Log sync delta
                let syncLog = RideSync(
                    bikeStravaGearId: gearId,
                    previousDistanceMeters: previousDistance,
                    newDistanceMeters: newDistance
                )
                modelContext.insert(syncLog)
            }
        } else {
            // New bike — fetch full details
            let gearDetail = try await apiClient.getGear(id: gearId)

            let bike = Bike(
                name: gearDetail.name,
                brandName: gearDetail.brandName ?? "",
                modelName: gearDetail.modelName ?? "",
                stravaGearId: gearId,
                totalDistanceMeters: gearDetail.distance,
                isPrimary: gearDetail.primary
            )
            bike.lastSyncDate = Date()
            modelContext.insert(bike)

            // Add default components
            for componentType in ComponentType.defaultBikeComponents {
                let component = Component(
                    type: componentType,
                    distanceAtInstall: gearDetail.distance
                )
                component.bike = bike
                modelContext.insert(component)
            }
        }
    }
}
