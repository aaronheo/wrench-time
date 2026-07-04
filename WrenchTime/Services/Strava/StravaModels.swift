import Foundation

// MARK: - Strava API Response Models (plain Codable, not SwiftData)

struct StravaAthlete: Codable {
    let id: Int
    let firstname: String?
    let lastname: String?
    let bikes: [StravaGearSummary]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        firstname = try container.decodeIfPresent(String.self, forKey: .firstname)
        lastname = try container.decodeIfPresent(String.self, forKey: .lastname)
        bikes = try container.decodeIfPresent([StravaGearSummary].self, forKey: .bikes) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case id, firstname, lastname, bikes
    }
}

struct StravaGearSummary: Codable, Identifiable {
    let id: String
    let name: String
    let primary: Bool?
    let distance: Double  // meters
}

struct StravaGear: Codable {
    let id: String
    let name: String
    let brandName: String?
    let modelName: String?
    let distance: Double  // meters
    let primary: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, distance, primary
        case brandName = "brand_name"
        case modelName = "model_name"
    }
}

// MARK: - Activity Summary (for distance calculations)

struct StravaActivitySummary: Codable {
    let id: Int
    let type: String
    let distance: Double  // meters
    let gearId: String?

    enum CodingKeys: String, CodingKey {
        case id, type, distance
        case gearId = "gear_id"
    }
}

// MARK: - Token Response

struct StravaTokenAthlete: Codable {
    let id: Int
    let firstname: String?
    let lastname: String?
}

struct StravaTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int
    let athlete: StravaTokenAthlete?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case athlete
    }
}
