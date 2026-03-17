import Foundation
import StoreKit

@MainActor
class StoreKitService: ObservableObject {
    @Published var products: [Product] = []
    @Published var isPremium = false
    @Published var isLoading = false

    private let productIds = [
        Constants.StoreKit.premiumMonthly,
        Constants.StoreKit.premiumAnnual
    ]

    // MARK: - Fetch Products

    func fetchProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: productIds)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            products = []
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            isPremium = true
            await transaction.finish()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Check Entitlement

    func checkEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIds.contains(transaction.productID) {
                    isPremium = true
                    return
                }
            }
        }
        isPremium = false
    }

    // MARK: - Restore

    func restore() async throws {
        try await AppStore.sync()
        await checkEntitlement()
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let value):
            return value
        }
    }
}

enum StoreKitError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        "Purchase verification failed."
    }
}
