import Foundation

// MARK: - Strava API Response Models (plain Codable, not SwiftData)

struct StravaAthlete: Codable {
    let id: Int
    let firstname: String?
    let lastname: String?
    let bikes: [StravaGearSummary]
}

struct StravaGearSummary: Codable, Identifiable {
    let id: String
    let name: String
    let primary: Bool
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

// MARK: - Token Response

struct StravaTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int
    let athlete: StravaAthlete?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case athlete
    }
}
