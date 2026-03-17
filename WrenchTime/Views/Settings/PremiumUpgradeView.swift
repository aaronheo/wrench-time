import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @EnvironmentObject private var storeKit: StoreKitService
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.yellow)

                    Text("WrenchTime Premium")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Unlock the full potential of your bike maintenance tracking.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Feature comparison
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(name: "Track Bikes", free: "1 bike", premium: "Unlimited")
                    FeatureRow(name: "Component Tracking", free: "Yes", premium: "Yes")
                    FeatureRow(name: "Strava Sync", free: "Yes", premium: "Yes")
                    FeatureRow(name: "Maintenance History", free: "30 days", premium: "Unlimited")
                    FeatureRow(name: "Custom Components", free: "No", premium: "Yes")
                    FeatureRow(name: "Export Data", free: "No", premium: "Yes")
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Subscription options
                if storeKit.isLoading {
                    ProgressView("Loading products...")
                } else if storeKit.products.isEmpty {
                    VStack(spacing: 8) {
                        Text("Products unavailable")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Subscription options will be available when the app is published on the App Store.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ForEach(storeKit.products) { product in
                        Button {
                            Task {
                                do {
                                    let _ = try await storeKit.purchase(product)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(product.displayName)
                                    .font(.headline)
                                Text(product.displayPrice)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                // Restore button
                Button("Restore Purchases") {
                    Task {
                        try? await storeKit.restore()
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await storeKit.fetchProducts()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
}

private struct FeatureRow: View {
    let name: String
    let free: String
    let premium: String

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(free)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70)

            Text(premium)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.orange)
                .frame(width: 70)
        }
    }
}
