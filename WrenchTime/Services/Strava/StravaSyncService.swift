import Foundation
import SwiftData
import Observation

@MainActor
@Observable
class StravaSyncService {
    var isSyncing = false
    var lastError: String?

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
            print("[WrenchTime Sync] Athlete ID: \(athlete.id), bikes count: \(athlete.bikes.count)")
            for bike in athlete.bikes {
                print("[WrenchTime Sync] Bike: id=\(bike.id) name=\(bike.name) distance=\(bike.distance)")
            }

            // Fetch gear details in parallel, then apply to SwiftData sequentially
            let bikeList = athlete.bikes
            let gearDetails = try await withThrowingTaskGroup(of: (StravaGearSummary, StravaGear?).self) { group in
                for gearSummary in bikeList {
                    let gearId = gearSummary.id
                    var descriptor = FetchDescriptor<Bike>(
                        predicate: #Predicate { $0.stravaGearId == gearId }
                    )
                    descriptor.fetchLimit = 1
                    let isNew = (try? modelContext.fetch(descriptor).isEmpty) ?? true

                    group.addTask {
                        if isNew {
                            let detail = try await self.apiClient.getGear(id: gearSummary.id)
                            return (gearSummary, detail)
                        }
                        return (gearSummary, nil)
                    }
                }

                var results: [(StravaGearSummary, StravaGear?)] = []
                for try await result in group {
                    results.append(result)
                }
                return results
            }

            for (gearSummary, gearDetail) in gearDetails {
                syncSingleBike(gearSummary: gearSummary, gearDetail: gearDetail, modelContext: modelContext)
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

    private func syncSingleBike(gearSummary: StravaGearSummary, gearDetail: StravaGear?, modelContext: ModelContext) {
        let gearId = gearSummary.id
        var descriptor = FetchDescriptor<Bike>(
            predicate: #Predicate { $0.stravaGearId == gearId }
        )
        descriptor.fetchLimit = 1

        let existingBikes = try? modelContext.fetch(descriptor)

        if let existingBike = existingBikes?.first {
            let previousDistance = existingBike.totalDistanceMeters
            let newDistance = gearSummary.distance

            existingBike.totalDistanceMeters = newDistance
            existingBike.lastSyncDate = Date()

            if newDistance != previousDistance {
                let syncLog = RideSync(
                    bikeStravaGearId: gearId,
                    previousDistanceMeters: previousDistance,
                    newDistanceMeters: newDistance
                )
                modelContext.insert(syncLog)
            }

            // Reconcile component mileage with maintenance history
            let bikeId = existingBike.id
            let componentDescriptor = FetchDescriptor<Component>(
                predicate: #Predicate { $0.bike?.id == bikeId }
            )
            let maintenanceDescriptor = FetchDescriptor<MaintenanceRecord>(
                predicate: #Predicate { $0.bike?.id == bikeId }
            )
            if let components = try? modelContext.fetch(componentDescriptor),
               let maintenanceRecords = try? modelContext.fetch(maintenanceDescriptor) {
                for component in components {
                    let componentRecords = maintenanceRecords
                        .filter { $0.componentType == component.type }
                        .sorted { $0.date > $1.date }

                    if let lastRecord = componentRecords.first {
                        // Has maintenance — align with the most recent replacement.
                        component.distanceAtInstall = lastRecord.distanceAtReplacement
                        component.installedDate = lastRecord.date
                    }
                    // No maintenance record: leave the component's existing install
                    // baseline untouched — it may have been added mid-life at the bike's
                    // current mileage, and resetting to 0 would falsely max out its wear.
                }
            }
        } else if let gearDetail {
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

            for componentType in ComponentType.defaultBikeComponents {
                let component = Component(
                    type: componentType,
                    distanceAtInstall: 0,
                    replacementThresholdMiles: componentType.defaultThresholdMiles(brakeType: bike.brakeType)
                )
                component.bike = bike
                modelContext.insert(component)
            }
        }
    }
}
