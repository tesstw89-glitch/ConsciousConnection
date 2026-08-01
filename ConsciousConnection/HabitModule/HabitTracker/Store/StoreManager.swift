import Foundation
import StoreKit
import Combine

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var isPremium = true
    @Published var errorMessage: String?
    @Published var showError = false

    static let maxFreeHabits = 9999

    init() { }

    func loadProducts() async { }

    func purchase(_ product: Product) async throws -> Transaction? {
        nil
    }

    func restorePurchases() async throws { }

    func updatePurchasedProducts() async { }

    var monthlyProduct: Product? { nil }
    var yearlyProduct: Product? { nil }
    var lifetimeProduct: Product? { nil }

    func canAddMoreHabits(currentCount: Int) -> Bool {
        true
    }

    func dismissError() {
        errorMessage = nil
        showError = false
    }

    #if DEBUG
    func debugTogglePremium() {
        isPremium.toggle()
    }
    #endif
}

enum StoreError: LocalizedError {
    case verificationFailed
    case purchaseFailed
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .verificationFailed: return "Transaction verification failed"
        case .purchaseFailed: return "Purchase could not be completed"
        case .productNotFound: return "Product not found"
        }
    }
}

extension Product.SubscriptionPeriod {
    var displayName: String {
        switch unit {
        case .day:
            return value == 7 ? "Weekly" : "\(value) Day\(value > 1 ? "s" : "")"
        case .week:
            return "\(value) Week\(value > 1 ? "s" : "")"
        case .month:
            return value == 1 ? "Monthly" : "\(value) Months"
        case .year:
            return value == 1 ? "Yearly" : "\(value) Years"
        @unknown default:
            return "Unknown"
        }
    }
}
