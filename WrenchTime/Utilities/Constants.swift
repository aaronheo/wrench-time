import Foundation

enum Constants {
    // MARK: - Strava API
    enum Strava {
        /// Register your app at https://www.strava.com/settings/api
        static let clientId = "YOUR_STRAVA_CLIENT_ID"
        static let clientSecret = "YOUR_STRAVA_CLIENT_SECRET"
        static let redirectUri = "wrenchtime://strava-callback"
        static let callbackScheme = "wrenchtime"
        static let baseURL = "https://www.strava.com/api/v3"
        static let authURL = "https://www.strava.com/oauth/mobile/authorize"
        static let tokenURL = "https://www.strava.com/oauth/token"
        static let scopes = "read,activity:read_all"
    }

    // MARK: - Keychain Keys
    enum Keychain {
        static let stravaAccessToken = "strava_access_token"
        static let stravaRefreshToken = "strava_refresh_token"
        static let stravaExpiresAt = "strava_expires_at"
    }

    // MARK: - StoreKit Product IDs
    enum StoreKit {
        static let premiumMonthly = "com.wrenchtime.premium.monthly"
        static let premiumAnnual = "com.wrenchtime.premium.annual"
    }

    // MARK: - Affiliate Links
    enum Affiliate {
        static func amazonLink(for componentType: ComponentType) -> URL? {
            let searchTerm: String
            switch componentType {
            case .chain:           searchTerm = "bicycle+chain"
            case .frontTire:       searchTerm = "bicycle+tire"
            case .rearTire:        searchTerm = "bicycle+tire"
            case .brakePadsFront:  searchTerm = "bicycle+brake+pads"
            case .brakePadsRear:   searchTerm = "bicycle+brake+pads"
            case .cassette:        searchTerm = "bicycle+cassette"
            case .cables:          searchTerm = "bicycle+cables"
            case .barTape:         searchTerm = "bicycle+bar+tape"
            case .custom:          searchTerm = "bicycle+parts"
            }
            return URL(string: "https://www.amazon.com/s?k=\(searchTerm)&tag=wrenchtime-20")
        }

        static func chainReactionLink(for componentType: ComponentType) -> URL? {
            URL(string: "https://www.chainreactioncycles.com/search?q=\(componentType.displayName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
    }

    // MARK: - Notification
    enum Notification {
        static let approachingThreshold = 0.85
        static let dueThreshold = 1.0
    }

    // MARK: - Sync
    enum Sync {
        static let minimumSyncIntervalSeconds: TimeInterval = 3600  // 1 hour
    }
}
