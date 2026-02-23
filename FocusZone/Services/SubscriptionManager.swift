//
//  SubscriptionManager.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import Foundation
import StoreKit
import SwiftUI

// MARK: - Subscription Manager
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var currentSubscription: Product.SubscriptionInfo.Status?
    @Published var availableProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Product IDs - These need to match App Store Connect
    private let productIDs = [
        "focus_zen_plus_month",
        "focus_zen_plus_pro_best_value"
    ]
    
    private var updateListenerTask: _Concurrency.Task<Void, Error>?
    private var transactionListener: _Concurrency.Task<Void, Error>?
    
    init() {
        // Start listening for transaction updates
        transactionListener = listenForTransactions()
        
        // Load products and check subscription status
        _Concurrency.Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
        transactionListener?.cancel()
    }
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: productIDs)
            // Sort products: annual first (usually better value), then monthly
            availableProducts = storeProducts.sorted { product1, product2 in
                let isAnnual1 = product1.id.contains("annual")
                let isAnnual2 = product2.id.contains("annual")
                return isAnnual1 && !isAnnual2
            }
            print("✅ Loaded \(storeProducts.count) products")
            
            for product in storeProducts {
                print("📦 Product: \(product.displayName) - \(product.displayPrice)")
            }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("❌ Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    var bestValueProduct: Product? {
        // Return best value plan if available, otherwise monthly
        return availableProducts.first { $0.id.contains("focus_zen_plus_pro_best_value") } ?? availableProducts.first
    }
    
    var monthlyProduct: Product? {
        return availableProducts.first { $0.id.contains("month") }
    }
    
    func calculateSavingsPercentage() -> Double? {
        guard let monthly = monthlyProduct,
              let bestValue = bestValueProduct else { return nil }
        
        let monthlyPrice = monthly.price
        let bestValuePrice = bestValue.price
        
        // Calculate annual cost if paid monthly
        let annualCostIfMonthly = monthlyPrice * 12
        
        // Calculate savings
        let savings = annualCostIfMonthly - bestValuePrice
        let savingsPercentage = (savings / annualCostIfMonthly) * 100
        
        return Double(truncating: savingsPercentage as NSNumber)
    }
    
    func getMonthlyEquivalentPrice(for product: Product) -> String? {
        if product.id.contains("focus_zen_plus_pro_best_value") {
            let monthlyPrice = product.price / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale.current
            return formatter.string(from: NSDecimalNumber(decimal: monthlyPrice))
        }
        return nil
    }
    
    func updateSubscriptionStatus() async {
        var validSubscription: Product.SubscriptionInfo.Status?
        
        // Check for valid subscriptions
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                // Check if this is our subscription product
                if productIDs.contains(transaction.productID) {
                    if let subscription = try? await Product.products(for: [transaction.productID]).first?.subscription {
                        let status = try? await subscription.status.first
                        validSubscription = status
                        break
                    }
                }
            }
        }
        
        currentSubscription = validSubscription
        
        // Update subscription status
        if let subscription = validSubscription {
            switch subscription.state {
            case .subscribed:
                subscriptionStatus = .active
            case .expired, .revoked:
                subscriptionStatus = .expired
            case .inBillingRetryPeriod, .inGracePeriod:
                subscriptionStatus = .active // Still considered active
            default:
                subscriptionStatus = .inactive
            }
            
            print("🔄 Subscription status: \(subscriptionStatus)")
        } else {
            subscriptionStatus = .inactive
            print("🔄 No active subscription found")
        }
    }
    
    func purchaseSubscription() async -> Bool {
        guard let product = availableProducts.first else {
            errorMessage = "Product not available"
            return false
        }
        
        return await purchaseProduct(product)
    }
    
    func purchaseProduct(_ product: Product) async -> Bool {
        print("🛍️   >>>>>>>>>>> Start  Purchasing subscription...")
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                if case .verified(let transaction) = verificationResult {
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    
                    // Track purchase event
                    print("✅ Purchase successful: \(transaction.productID)")
                    return true
                }
                
            case .userCancelled:
                print("🚫 User cancelled purchase")
                
            case .pending:
                print("⏳ Purchase pending")
                
            @unknown default:
                print("❓ Unknown purchase result")
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("❌ Purchase failed: \(error)")
        }
        
        isLoading = false
        return false
    }
    
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            
            if subscriptionStatus == .active {
                print("✅ Purchases restored successfully")
                isLoading = false
                return true
            } else {
                errorMessage = "No active subscription found"
            }
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            print("❌ Failed to restore purchases: \(error)")
        }
        
        isLoading = false
        return false
    }
    
    
    private func listenForTransactions() -> _Concurrency.Task<Void, Error> {
        return _Concurrency.Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    print("🔄 Transaction update: \(transaction.productID)")
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }
        }
    }
    
    var isProUser: Bool {
        return subscriptionStatus == .active
    }
    
    var hasActiveSubscription: Bool {
        return subscriptionStatus == .active
    }
    
    var isInFreeTrial: Bool {
        guard let subscription = currentSubscription else { return false }
        
        // Check if user is in free trial period
        if case .verified(let renewalInfo) = subscription.renewalInfo {
            return renewalInfo.willAutoRenew && subscription.state == .subscribed
        }
        
        return false
    }
    
    var subscriptionExpiryDate: Date? {
        guard let subscription = currentSubscription,
              case .verified(let transaction) = subscription.transaction else {
            return nil
        }
        
        return transaction.expirationDate
    }
    
    var nextBillingDate: Date? {
        guard let subscription = currentSubscription,
              case .verified(let transaction) = subscription.transaction else {
            return nil
        }
        
        return transaction.expirationDate
    }
    
    // MARK: - Task Limit Methods
    
    func canCreateTask(currentTaskCount: Int) -> Bool {
        if isProUser {
            return true // Pro users have unlimited tasks
        }
        return currentTaskCount < ProFeatures.maxTasksForFree
    }
    
    func getTaskLimitMessage(currentTaskCount: Int) -> String {
        if isProUser {
            return "Unlimited tasks with Pro"
        }
        
        let remaining = ProFeatures.maxTasksForFree - currentTaskCount
        if remaining > 0 {
            return "\(remaining) tasks remaining"
        } else {
            return "Upgrade to Pro for unlimited tasks"
        }
    }
}

enum SubscriptionStatus: String, CaseIterable {
    case unknown = "unknown"
    case inactive = "inactive"
    case active = "active"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .unknown: return "Checking..."
        case .inactive: return "Free"
        case .active: return "Pro"
        case .expired: return "Expired"
        }
    }
    
    var isPro: Bool {
        return self == .active
    }
}


struct ProFeatures {
    static let maxTasksForFree = 3
    static let maxFocusSessionsForFree = 5
    static let maxInsightsForFree = 3
    
    static var proFeaturesList: [String] {
        return [
            LanguageManager.localized("unlimited_tasks", comment: "Unlimited tasks feature"),
            LanguageManager.localized("advanced_insights_recommendations", comment: "Advanced insights and recommendations feature"),
            LanguageManager.localized("custom_focus_modes", comment: "Custom focus modes feature"),
            LanguageManager.localized("smart_break_suggestions", comment: "Smart break suggestions feature"),
        ]
    }
}
