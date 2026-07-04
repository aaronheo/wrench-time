import Foundation

enum APIError: LocalizedError {
    case notAuthenticated
    case http(status: Int, body: String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not signed in."
        case .http(let status, let body):
            return "Server error (\(status)). \(body)"
        case .invalidResponse:
            return "Unexpected response from the server."
        }
    }
}

/// Talks to the WrenchTime backend API, attaching the current Supabase JWT to
/// every request. The backend is the source of truth for all data.
@MainActor
final class WrenchAPIClient {
    static let shared = WrenchAPIClient()

    private let baseURL = Constants.API.baseURL
    private let urlSession = URLSession.shared
    private let auth = SupabaseManager.client.auth

    // MARK: - JSON coding (ISO 8601 with fractional seconds, as emitted by Postgres)

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { d in
            let container = try d.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = Self.isoFractional.date(from: string) ?? Self.isoPlain.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO 8601 date: \(string)")
        }
        return decoder
    }()

    private lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, e in
            var container = e.singleValueContainer()
            try container.encode(Self.isoFractional.string(from: date))
        }
        return encoder
    }()

    // MARK: - Core request plumbing

    private func accessToken() async throws -> String {
        do {
            return try await auth.session.accessToken
        } catch {
            throw APIError.notAuthenticated
        }
    }

    private func sendData(_ method: String, _ path: String, bodyData: Data?) async throws -> Data {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(try await accessToken())", forHTTPHeaderField: "Authorization")
        if let bodyData {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData
        }

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        try decoder.decode(T.self, from: await sendData("GET", path, bodyData: nil))
    }

    @discardableResult
    private func send<Body: Encodable, T: Decodable>(_ method: String, _ path: String, body: Body) async throws -> T {
        let data = try await sendData(method, path, bodyData: try encoder.encode(body))
        return try decoder.decode(T.self, from: data)
    }

    private func delete(_ path: String) async throws {
        _ = try await sendData("DELETE", path, bodyData: nil)
    }

    // MARK: - Bikes

    func listBikes() async throws -> [BikeDTO] {
        try await get("/api/bikes")
    }

    func getBike(_ id: UUID) async throws -> BikeDetailDTO {
        try await get("/api/bikes/\(id.uuidString)")
    }

    func createBike(_ body: BikeCreate) async throws -> BikeDTO {
        try await send("POST", "/api/bikes", body: body)
    }

    func updateBike(_ id: UUID, _ body: BikePatch) async throws -> BikeDTO {
        try await send("PATCH", "/api/bikes/\(id.uuidString)", body: body)
    }

    func deleteBike(_ id: UUID) async throws {
        try await delete("/api/bikes/\(id.uuidString)")
    }

    // MARK: - Components

    func createComponent(bikeId: UUID, _ body: ComponentCreate) async throws -> ComponentDTO {
        try await send("POST", "/api/bikes/\(bikeId.uuidString)/components", body: body)
    }

    func updateComponent(_ id: UUID, _ body: ComponentPatch) async throws -> ComponentDTO {
        try await send("PATCH", "/api/components/\(id.uuidString)", body: body)
    }

    func deleteComponent(_ id: UUID) async throws {
        try await delete("/api/components/\(id.uuidString)")
    }

    // MARK: - Maintenance

    func createMaintenance(bikeId: UUID, _ body: MaintenanceCreate) async throws -> MaintenanceDTO {
        try await send("POST", "/api/bikes/\(bikeId.uuidString)/maintenance", body: body)
    }

    func updateMaintenance(_ id: UUID, _ body: MaintenancePatch) async throws -> MaintenanceDTO {
        try await send("PATCH", "/api/maintenance/\(id.uuidString)", body: body)
    }

    func deleteMaintenance(_ id: UUID) async throws {
        try await delete("/api/maintenance/\(id.uuidString)")
    }

    // MARK: - Rides

    func listRides() async throws -> [RideSyncDTO] {
        try await get("/api/rides")
    }

    func createRide(_ body: RideCreate) async throws -> RideSyncDTO {
        try await send("POST", "/api/rides", body: body)
    }

    // MARK: - Settings

    func getSettings() async throws -> SettingsDTO {
        try await get("/api/settings")
    }

    func updateSettings(_ body: SettingsUpsert) async throws -> SettingsDTO {
        try await send("PUT", "/api/settings", body: body)
    }

    // MARK: - Sync

    func getSync() async throws -> SyncSnapshot {
        try await get("/api/sync")
    }

    @discardableResult
    func postSync(_ snapshot: SyncSnapshot) async throws -> SyncSnapshot {
        try await send("POST", "/api/sync", body: snapshot)
    }
}
