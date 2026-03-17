import SwiftUI

struct AffiliateLinksView: View {
    let componentType: ComponentType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Find replacement parts for your \(componentType.displayName.lowercased()):")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Online Retailers") {
                    if let amazonURL = Constants.Affiliate.amazonLink(for: componentType) {
                        Link(destination: amazonURL) {
                            HStack {
                                Image(systemName: "cart.fill")
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading) {
                                    Text("Amazon")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Wide selection, fast shipping")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if let crcURL = Constants.Affiliate.chainReactionLink(for: componentType) {
                        Link(destination: crcURL) {
                            HStack {
                                Image(systemName: "bicycle")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text("Chain Reaction Cycles")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Specialist bike parts retailer")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Local Bike Shops") {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading) {
                            Text("Find Nearby Shops")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Support your local bike shop")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Coming Soon")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Shop Parts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
