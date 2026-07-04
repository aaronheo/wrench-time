import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var auth: AuthService

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)
                Text("WrenchTime")
                    .font(.largeTitle.bold())
                Text("Track your bike maintenance across all your devices.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 16) {
                // NOTE: Sign in with Apple is deferred until a paid Apple Developer
                // account is available (free personal teams can't use the capability).
                // AuthService.handleAppleCompletion / prepareAppleRequest remain ready
                // to re-enable alongside the entitlement in project.yml.
                Button {
                    Task { await auth.signInWithGoogle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                        Text("Continue with Google")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 32)
            .disabled(auth.isLoading)
            .opacity(auth.isLoading ? 0.5 : 1)
            .overlay {
                if auth.isLoading {
                    ProgressView()
                }
            }

            if let error = auth.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Text("Sign-in is required to sync your data.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)

            Spacer().frame(height: 32)
        }
    }
}
