import Foundation

actor StravaAPIClient {
    private let authService: StravaAuthService
    private let baseURL = URL(string: Constants.Strava.baseURL)!
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    init(authService: StravaAuthService) {
        self.authService = authService
    }

    // MARK: - Athlete (includes bikes list)

    func getAthlete() async throws -> StravaAthlete {
        let data = try await authenticatedRequest(path: "/athlete")
        return try decoder.decode(StravaAthlete.self, from: data)
    }

    // MARK: - Gear Detail

    func getGear(id: String) async throws -> StravaGear {
        let data = try await authenticatedRequest(path: "/gear/\(id)")
        return try decoder.decode(StravaGear.self, from: data)
    }

    // MARK: - Activities

    /// Fetches all non-virtual ride distance (in meters) for a specific gear since a given date.
    func getNonVirtualDistance(gearId: String, after: Date) async throws -> Double {
        let epoch = Int(after.timeIntervalSince1970)
        var totalDistance = 0.0
        var page = 1

        while true {
            let data = try await authenticatedRequest(
                path: "/athlete/activities?after=\(epoch)&per_page=200&page=\(page)"
            )
            let activities = try decoder.decode([StravaActivitySummary].self, from: data)

            for activity in activities where activity.gearId == gearId && activity.type != "VirtualRide" {
                totalDistance += activity.distance
            }

            if activities.count < 200 { break }
            page += 1
        }

        return totalDistance
    }

    // MARK: - Authenticated Request

    private func authenticatedRequest(path: String) async throws -> Data {
        let token = try await authService.getValidAccessToken()

        guard let url = URL(string: baseURL.absoluteString + path) else {
            throw StravaAPIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            // Token rejected — force a refresh (the cached token is what just failed) and retry once.
            let newToken = try await authService.forceRefreshAccessToken()
            var retryRequest = request
            retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
            guard let retryHttp = retryResponse as? HTTPURLResponse, (200...299).contains(retryHttp.statusCode) else {
                throw StravaAPIError.unauthorized
            }
            return retryData
        case 429:
            throw StravaAPIError.rateLimited
        default:
            throw StravaAPIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

enum StravaAPIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case rateLimited
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:          return "Invalid response from Strava."
        case .unauthorized:             return "Strava authorization failed. Please reconnect."
        case .rateLimited:              return "Strava rate limit reached. Please try again later."
        case .httpError(let code):      return "Strava API error (HTTP \(code))."
        }
    }
}
