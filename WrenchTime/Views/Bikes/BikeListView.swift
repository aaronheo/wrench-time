import SwiftUI
import SwiftData

struct BikeListView: View {
    @Query(sort: \Bike.name) private var bikes: [Bike]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var storeKit: StoreKitService

    @State private var showAddBike = false
    @State private var showUpgradeAlert = false
    @State private var showUpgradeSheet = false

    private var sortedBikes: [Bike] {
        bikes.sorted { $0.isPrimary && !$1.isPrimary }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedBikes.isEmpty {
                    EmptyStateView(
                        icon: "bicycle",
                        title: "No Bikes",
                        message: "Add your first bike to start tracking maintenance.",
                        action: { showAddBike = true },
                        actionLabel: "Add Bike"
                    )
                } else {
                    List {
                        ForEach(sortedBikes) { bike in
                            NavigationLink(value: bike) {
                                BikeRowView(bike: bike)
                            }
                        }
                        .onDelete(perform: deleteBikes)
                    }
                }
            }
            .navigationTitle("Bikes")
            .navigationDestination(for: Bike.self) { bike in
                BikeDetailView(bike: bike)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if canAddBike {
                            showAddBike = true
                        } else {
                            showUpgradeAlert = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBike) {
                AddBikeView()
            }
            .alert("Premium Required", isPresented: $showUpgradeAlert) {
                Button("Upgrade") {
                    showUpgradeSheet = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Free accounts are limited to 1 bike. Upgrade to Premium to track unlimited bikes.")
            }
            .sheet(isPresented: $showUpgradeSheet) {
                NavigationStack {
                    PremiumUpgradeView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showUpgradeSheet = false }
                            }
                        }
                }
            }
        }
    }

    private var canAddBike: Bool {
        storeKit.isPremium || bikes.count < 1
    }

    private func deleteBikes(at offsets: IndexSet) {
        // Offsets index into `sortedBikes` (what the ForEach renders), not the
        // differently-ordered `@Query` array.
        for index in offsets {
            modelContext.delete(sortedBikes[index])
        }
    }
}

// MARK: - Bike Row

private struct BikeRowView: View {
    let bike: Bike

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(bike.name)
                        .font(.headline)
                    if bike.isPrimary {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                if !bike.brandName.isEmpty {
                    Text(bike.brandName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(bike.totalDistanceMiles.formattedMiles)
                    .font(.subheadline)
                    .fontWeight(.medium)

                let dueCount = bike.dueComponents.count
                if dueCount > 0 {
                    Text("\(dueCount) alert\(dueCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
