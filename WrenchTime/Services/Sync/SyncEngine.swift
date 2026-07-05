import Foundation
import SwiftData

/// Mirrors the local SwiftData cache to the backend, which is the source of truth.
///
/// - Pull (server → local) on sign-in and app foreground; the server wins.
/// - Push (local → server) whenever SwiftData saves, debounced. Because it hooks
///   the save notification, every existing mutation (including Strava sync) is
///   mirrored without touching view code.
@MainActor
final class SyncEngine: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncedAt: Date?
    @Published var lastError: String?

    private let context: ModelContext
    private let api = WrenchAPIClient.shared

    private var didInitialPull = false
    private var isApplyingRemote = false
    /// Local edits have been made that haven't reached the server yet.
    private var pendingPush = false
    private var pushTask: Task<Void, Never>?
    private var saveObserver: NSObjectProtocol?

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Lifecycle

    /// Begin observing local saves. Idempotent.
    func start() {
        guard saveObserver == nil else { return }
        saveObserver = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.schedulePush()
            }
        }
    }

    /// Sign-out teardown: stop pushing and clear the local cache so the next user
    /// starts clean (prevents one account's data leaking into another).
    func handleSignOut() {
        pushTask?.cancel()
        didInitialPull = false
        pendingPush = false
        if let saveObserver {
            NotificationCenter.default.removeObserver(saveObserver)
            self.saveObserver = nil
        }
        wipeLocalCache()
        lastSyncedAt = nil
    }

    // MARK: - Pull (server → local)

    /// Pull the server's dataset into the local cache (server wins). If there are
    /// un-pushed local edits, flush them first so a pull can never delete a
    /// locally-added item that hasn't synced to the server yet.
    func pullFromServer() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        if pendingPush {
            await performPush()
        } else {
            await performPull()
        }
    }

    private func performPull() async {
        do {
            let snapshot = try await api.getSync()
            // A local edit landed while the request was in flight — don't clobber it.
            if pendingPush {
                await performPush()
                return
            }
            if snapshot.bikes.isEmpty, localHasData() {
                // First sign-in with pre-existing local data: adopt it onto the server
                // instead of wiping it.
                didInitialPull = true
                pendingPush = true
                await performPush()
            } else {
                applyRemote(snapshot)
                didInitialPull = true
                lastSyncedAt = Date()
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Push (local → server)

    private func schedulePush() {
        guard didInitialPull, !isApplyingRemote else { return }
        pendingPush = true
        pushTask?.cancel()
        pushTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000) // ~1.2s debounce
            guard !Task.isCancelled else { return }
            await self?.runPush()
        }
    }

    /// Debounced-push entry point. If another sync op holds the lock, skip — the
    /// pending flag stays set so the next pull/push flushes it.
    func runPush() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        await performPush()
    }

    private func performPush() async {
        guard didInitialPull else { return }
        do {
            let snapshot = try gatherLocalSnapshot()
            guard !snapshot.bikes.isEmpty else {
                pendingPush = false
                return // never wipe the server with an empty push
            }
            try await api.postSync(snapshot)
            pendingPush = false
            lastSyncedAt = Date()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Local <-> snapshot

    private func gatherLocalSnapshot() throws -> SyncSnapshot {
        let bikes = try context.fetch(FetchDescriptor<Bike>())
        let components = try context.fetch(FetchDescriptor<Component>())
        let maintenance = try context.fetch(FetchDescriptor<MaintenanceRecord>())

        return SyncSnapshot(
            bikes: bikes.map {
                SyncBike(
                    id: $0.id,
                    name: $0.name,
                    brandName: $0.brandName,
                    modelName: $0.modelName,
                    stravaGearId: $0.stravaGearId,
                    brakeType: $0.brakeType.rawValue,
                    totalDistanceMeters: $0.totalDistanceMeters,
                    isPrimary: $0.isPrimary,
                    isWaxedChain: $0.isWaxedChain,
                    lastWaxedAtMeters: $0.lastWaxedAtMeters,
                    dateAdded: $0.dateAdded,
                    lastSyncDate: $0.lastSyncDate
                )
            },
            components: components.compactMap { component in
                guard let bikeId = component.bike?.id else { return nil }
                return SyncComponent(
                    id: component.id,
                    bikeId: bikeId,
                    type: component.type.rawValue,
                    name: component.name,
                    installedDate: component.installedDate,
                    distanceAtInstall: component.distanceAtInstall,
                    replacementThresholdMiles: component.replacementThresholdMiles,
                    notes: component.notes
                )
            },
            maintenance: maintenance.compactMap { record in
                guard let bikeId = record.bike?.id else { return nil }
                return SyncMaintenance(
                    id: record.id,
                    bikeId: bikeId,
                    componentType: record.componentType.rawValue,
                    date: record.date,
                    distanceAtReplacement: record.distanceAtReplacement,
                    cost: record.cost,
                    notes: record.notes,
                    partName: record.partName
                )
            }
        )
    }

    /// Reconcile the local cache to exactly match the server snapshot (server wins).
    private func applyRemote(_ snapshot: SyncSnapshot) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        do {
            // --- Bikes ---
            let existingBikes = try context.fetch(FetchDescriptor<Bike>())
            var bikeById = Dictionary(existingBikes.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let remoteBikeIds = Set(snapshot.bikes.map(\.id))
            for bike in existingBikes where !remoteBikeIds.contains(bike.id) {
                context.delete(bike)
            }
            for remote in snapshot.bikes {
                let bike: Bike
                if let existing = bikeById[remote.id] {
                    bike = existing
                } else {
                    bike = Bike(name: remote.name)
                    bike.id = remote.id
                    context.insert(bike)
                    bikeById[remote.id] = bike
                }
                bike.name = remote.name
                bike.brandName = remote.brandName
                bike.modelName = remote.modelName
                bike.stravaGearId = remote.stravaGearId
                bike.brakeTypeRaw = BrakeType(rawValue: remote.brakeType) ?? .disc
                bike.totalDistanceMeters = remote.totalDistanceMeters
                bike.isPrimary = remote.isPrimary
                bike.isWaxedChain = remote.isWaxedChain ?? false
                bike.lastWaxedAtMeters = remote.lastWaxedAtMeters ?? 0
                bike.dateAdded = remote.dateAdded
                bike.lastSyncDate = remote.lastSyncDate
            }

            // --- Components ---
            let existingComponents = try context.fetch(FetchDescriptor<Component>())
            var componentById = Dictionary(existingComponents.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let remoteComponentIds = Set(snapshot.components.map(\.id))
            for component in existingComponents where !remoteComponentIds.contains(component.id) {
                context.delete(component)
            }
            for remote in snapshot.components {
                guard let bike = bikeById[remote.bikeId] else { continue }
                let component: Component
                if let existing = componentById[remote.id] {
                    component = existing
                } else {
                    component = Component(
                        type: ComponentType(rawValue: remote.type) ?? .custom,
                        replacementThresholdMiles: remote.replacementThresholdMiles
                    )
                    component.id = remote.id
                    context.insert(component)
                    componentById[remote.id] = component
                }
                component.type = ComponentType(rawValue: remote.type) ?? .custom
                component.name = remote.name
                component.installedDate = remote.installedDate
                component.distanceAtInstall = remote.distanceAtInstall
                component.replacementThresholdMiles = remote.replacementThresholdMiles
                component.notes = remote.notes
                component.bike = bike
            }

            // --- Maintenance ---
            let existingMaintenance = try context.fetch(FetchDescriptor<MaintenanceRecord>())
            var maintenanceById = Dictionary(existingMaintenance.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let remoteMaintenanceIds = Set(snapshot.maintenance.map(\.id))
            for record in existingMaintenance where !remoteMaintenanceIds.contains(record.id) {
                context.delete(record)
            }
            for remote in snapshot.maintenance {
                guard let bike = bikeById[remote.bikeId] else { continue }
                let record: MaintenanceRecord
                if let existing = maintenanceById[remote.id] {
                    record = existing
                } else {
                    record = MaintenanceRecord(
                        componentType: ComponentType(rawValue: remote.componentType) ?? .custom,
                        distanceAtReplacement: remote.distanceAtReplacement
                    )
                    record.id = remote.id
                    context.insert(record)
                    maintenanceById[remote.id] = record
                }
                record.componentType = ComponentType(rawValue: remote.componentType) ?? .custom
                record.date = remote.date
                record.distanceAtReplacement = remote.distanceAtReplacement
                record.cost = remote.cost
                record.notes = remote.notes
                record.partName = remote.partName
                record.bike = bike
            }

            try context.save()
        } catch {
            lastError = "Failed to apply server data: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func localHasData() -> Bool {
        ((try? context.fetchCount(FetchDescriptor<Bike>())) ?? 0) > 0
    }

    private func wipeLocalCache() {
        isApplyingRemote = true
        defer { isApplyingRemote = false }
        do {
            try context.delete(model: MaintenanceRecord.self)
            try context.delete(model: Component.self)
            try context.delete(model: RideSync.self)
            try context.delete(model: Bike.self)
            try context.save()
        } catch {
            lastError = "Failed to clear local cache: \(error.localizedDescription)"
        }
    }
}
