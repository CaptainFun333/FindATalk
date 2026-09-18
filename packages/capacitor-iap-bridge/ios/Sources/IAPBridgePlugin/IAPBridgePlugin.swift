import Foundation
import Capacitor
import StoreKit

/// Wraps StoreKit 2 for FindATalk's in-app tip jar. Packaged as its own
/// local Capacitor plugin (packages/capacitor-iap-bridge, referenced from
/// the root package.json via a `file:` dependency) so `npx cap sync` keeps
/// ios/App/App/capacitor.config.json and ios/App/CapApp-SPM/Package.swift
/// up to date automatically — same reasoning as capacitor-streak-bridge
/// (see that plugin's own header comment / PROJECT_HANDOFF.md).
///
/// Tips are consumable products (see functions/index.js's product-id list)
/// — there is no ongoing "entitlement" to restore for them the way a
/// subscription or non-consumable would have one. What CAN go missing is a
/// transaction that completed at the App Store but never got finish()ed on
/// this device (app killed mid-flow, or a StoreKit "Ask to Buy" approval
/// that lands after the purchase() call already returned). Transaction.
/// updates and Transaction.unfinished both surface those; see startTransactionListener()
/// and restorePurchases() below.
@objc(IAPBridgePlugin)
public class IAPBridgePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "IAPBridgePlugin"
    public let jsName = "IAPBridge"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getProducts", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "purchase", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "finishTransaction", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "restorePurchases", returnType: CAPPluginReturnPromise)
    ]

    // Transactions StoreKit has handed us (via purchase() or the update
    // listener) that JS hasn't confirmed with the verifyIAPPurchase Cloud
    // Function yet, keyed by transaction id as a string (StoreKit's own id
    // is a UInt64, JS only ever sees the string form). finishTransaction()
    // looks the real Transaction object up here — StoreKit 2 requires
    // calling .finish() on the object itself, not just an id.
    private var pendingTransactions: [String: Transaction] = [:]
    private var updateListenerTask: Task<Void, Never>?

    override public func load() {
        startTransactionListener()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    /// Observes transactions StoreKit delivers outside a direct purchase()
    /// call in this session — e.g. a Family Sharing "Ask to Buy" approval
    /// that completes after the app relaunches. Surfaced to JS as a plain
    /// event so it can run the same verify-then-finish flow it uses for a
    /// direct purchase.
    private func startTransactionListener() {
        updateListenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self, case .verified(let transaction) = result else { continue }
                let idString = String(transaction.id)
                self.pendingTransactions[idString] = transaction
                self.notifyListeners("transactionsUpdated", data: [
                    "transactionId": idString,
                    "productId": transaction.productID,
                    "jwsRepresentation": result.jwsRepresentation
                ])
            }
        }
    }

    @objc func getProducts(_ call: CAPPluginCall) {
        guard let productIds = call.getArray("productIds", String.self), !productIds.isEmpty else {
            call.reject("Missing productIds")
            return
        }
        Task {
            do {
                let products = try await Product.products(for: Set(productIds))
                let result = products.map { product in
                    [
                        "id": product.id,
                        "displayName": product.displayName,
                        "displayPrice": product.displayPrice
                    ]
                }
                call.resolve(["products": result])
            } catch {
                call.reject("Failed to load products: \(error.localizedDescription)")
            }
        }
    }

    @objc func purchase(_ call: CAPPluginCall) {
        guard let productId = call.getString("productId") else {
            call.reject("Missing productId")
            return
        }
        Task {
            do {
                guard let product = try await Product.products(for: [productId]).first else {
                    call.reject("Unknown product: \(productId)")
                    return
                }
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    guard case .verified(let transaction) = verification else {
                        call.reject("Transaction failed StoreKit verification")
                        return
                    }
                    let idString = String(transaction.id)
                    pendingTransactions[idString] = transaction
                    call.resolve([
                        "transactionId": idString,
                        "productId": transaction.productID,
                        "jwsRepresentation": verification.jwsRepresentation
                    ])
                case .userCancelled:
                    call.reject("Purchase cancelled", "CANCELLED")
                case .pending:
                    call.reject("Purchase pending approval", "PENDING")
                @unknown default:
                    call.reject("Unknown purchase result")
                }
            } catch {
                call.reject("Purchase failed: \(error.localizedDescription)")
            }
        }
    }

    /// Called only after the Cloud Function has confirmed it recorded the
    /// purchase server-side — finishing before that would let a purchase
    /// StoreKit already charged for silently vanish if the network call to
    /// verifyIAPPurchase fails right after.
    @objc func finishTransaction(_ call: CAPPluginCall) {
        guard let transactionId = call.getString("transactionId") else {
            call.reject("Missing transactionId")
            return
        }
        guard let transaction = pendingTransactions[transactionId] else {
            call.reject("No pending transaction with id \(transactionId)")
            return
        }
        Task {
            await transaction.finish()
            pendingTransactions.removeValue(forKey: transactionId)
            call.resolve()
        }
    }

    /// Re-surfaces any transaction StoreKit still considers unfinished on
    /// this device (see the class-level doc comment above) so JS can run
    /// them back through verify-then-finish. Also nudges StoreKit to sync
    /// with the App Store first.
    @objc func restorePurchases(_ call: CAPPluginCall) {
        Task {
            do {
                try await AppStore.sync()
            } catch {
                // Non-fatal — still report whatever unfinished transactions
                // are already known locally.
            }
            var restored: [[String: Any]] = []
            for await result in Transaction.unfinished {
                guard case .verified(let transaction) = result else { continue }
                let idString = String(transaction.id)
                pendingTransactions[idString] = transaction
                restored.append([
                    "transactionId": idString,
                    "productId": transaction.productID,
                    "jwsRepresentation": result.jwsRepresentation
                ])
            }
            call.resolve(["transactions": restored])
        }
    }
}
