import Foundation
import AuthenticationServices

@MainActor
class StravaAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var athleteName: String?

    private let keychain = KeychainService.shared

    init() {
        isAuthenticated = keychain.loadString(key: Constants.Keychain.stravaAccessToken) != nil
    }

    // MARK: - Authorization URL

    var authorizationURL: URL {
        var components = URLComponents(string: Constants.Strava.authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.Strava.clientId),
            URLQueryItem(name: "redirect_uri", value: Constants.Strava.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: Constants.Strava.scopes)
        ]
        return components.url!
    }

    // MARK: - Authenticate via ASWebAuthenticationSession

    func authenticate() async throws {
        isLoading = true
        defer { isLoading = false }

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: authorizationURL,
                callbackURLScheme: Constants.Strava.callbackScheme
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: StravaAuthError.noCallback)
                }
            }
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }

        guard let code = extractCode(from: callbackURL) else {
            throw StravaAuthError.noAuthorizationCode
        }

        let tokenResponse = try await exchangeCodeForToken(code: code)
        storeTokens(tokenResponse)
        isAuthenticated = true
        athleteName = [tokenResponse.athlete?.firstname, tokenResponse.athlete?.lastname]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    // MARK: - Token Exchange

    private func exchangeCodeForToken(code: String) async throws -> StravaTokenResponse {
        var request = URLRequest(url: URL(string: Constants.Strava.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "client_id": Constants.Strava.clientId,
            "client_secret": Constants.Strava.clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw StravaAuthError.tokenExchangeFailed
        }

        return try JSONDecoder().decode(StravaTokenResponse.self, from: data)
    }

    // MARK: - Token Refresh

    func getValidAccessToken() async throws -> String {
        guard let expiresAtString = keychain.loadString(key: Constants.Keychain.stravaExpiresAt),
              let expiresAt = Double(expiresAtString) else {
            throw StravaAuthError.notAuthenticated
        }

        if Date().timeIntervalSince1970 < expiresAt - 60 {
            guard let token = keychain.loadString(key: Constants.Keychain.stravaAccessToken) else {
                throw StravaAuthError.notAuthenticated
            }
            return token
        }

        return try await refreshToken()
    }

    private func refreshToken() async throws -> String {
        guard let refreshToken = keychain.loadString(key: Constants.Keychain.stravaRefreshToken) else {
            throw StravaAuthError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: Constants.Strava.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "client_id": Constants.Strava.clientId,
            "client_secret": Constants.Strava.clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw StravaAuthError.tokenRefreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
        storeTokens(tokenResponse)
        return tokenResponse.accessToken
    }

    // MARK: - Logout

    func disconnect() {
        keychain.delete(key: Constants.Keychain.stravaAccessToken)
        keychain.delete(key: Constants.Keychain.stravaRefreshToken)
        keychain.delete(key: Constants.Keychain.stravaExpiresAt)
        isAuthenticated = false
        athleteName = nil
    }

    // MARK: - Helpers

    private func extractCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
    }

    private func storeTokens(_ response: StravaTokenResponse) {
        keychain.save(key: Constants.Keychain.stravaAccessToken, string: response.accessToken)
        keychain.save(key: Constants.Keychain.stravaRefreshToken, string: response.refreshToken)
        keychain.save(key: Constants.Keychain.stravaExpiresAt, string: String(response.expiresAt))
    }
}

// MARK: - Errors

enum StravaAuthError: LocalizedError {
    case noCallback
    case noAuthorizationCode
    case tokenExchangeFailed
    case tokenRefreshFailed
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .noCallback:           return "No callback received from Strava."
        case .noAuthorizationCode:  return "No authorization code in callback."
        case .tokenExchangeFailed:  return "Failed to exchange code for token."
        case .tokenRefreshFailed:   return "Failed to refresh access token."
        case .notAuthenticated:     return "Not authenticated with Strava."
        }
    }
}
