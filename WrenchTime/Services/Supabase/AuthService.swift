import Foundation
import Supabase
import AuthenticationServices
import CryptoKit

/// Owns the Supabase auth session (Google + Apple sign-in) and gates the app.
/// Sign-in is required; the session's JWT is what the API client sends to the backend.
@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var session: Session?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.client
    private var appleNonce: String?

    var isAuthenticated: Bool { session != nil }
    var userEmail: String? { session?.user.email }

    init() {
        // Hydrate synchronously from any persisted session for an instant first paint.
        // May be expired; restoreSession() refreshes it.
        session = client.auth.currentSession
    }

    /// Refresh the persisted session on launch. Drops to signed-out if it can't be refreshed.
    func restoreSession() async {
        do {
            session = try await client.auth.session
        } catch {
            session = nil
        }
    }

    // MARK: - Google (OAuth web flow via ASWebAuthenticationSession)

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            session = try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: Constants.Supabase.redirectURL)
            )
        } catch {
            if !isUserCancellation(error) {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Apple (native Sign in with Apple)

    /// Configure the Apple request just before it's presented (sets scopes + nonce).
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        appleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityTokenData = credential.identityToken,
                let identityToken = String(data: identityTokenData, encoding: .utf8)
            else {
                errorMessage = "Apple sign-in did not return an identity token."
                return
            }
            do {
                session = try await client.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(
                        provider: .apple,
                        idToken: identityToken,
                        nonce: appleNonce
                    )
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            if !isUserCancellation(error) {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Sign out

    func signOut() async {
        try? await client.auth.signOut()
        session = nil
    }

    // MARK: - Helpers

    private func isUserCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.code == ASWebAuthenticationSessionError.Code.canceledLogin.rawValue
            || nsError.code == ASAuthorizationError.Code.canceled.rawValue
    }

    private static func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var byte: UInt8 = 0
            guard SecRandomCopyBytes(kSecRandomDefault, 1, &byte) == errSecSuccess else { continue }
            if Int(byte) < charset.count {
                result.append(charset[Int(byte)])
                remaining -= 1
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
