//
//  StoreService.swift
//  XCStringGPTTranslator
//
//  Created by wp on 2024/4/9.
//

import Foundation
import SecureDefaults
import StoreKit

private enum Const {
    static let accessProductId = "unlock_all"
    static let signDateKey = "sign_date"
    static let signSecrect = "t8sLT4Y7stfDHTaSZJWumTtFFAlSHzj1"
}

@Observable
class StoreService {
    static let shared = StoreService()

    private(set) var isPurchased = false

    @ObservationIgnored
    private var updates: Task<Void, Never>?

    @ObservationIgnored
    private(set) var activeTransactions: Set<StoreKit.Transaction> = [] {
        didSet {
            for transaction in activeTransactions {
                // 更新签名时间
                if transaction.productID == Const.accessProductId {
                    isPurchased = true
                    SecureDefaults.shared.setValue(Int(Date().timeIntervalSince1970), forKey: Const.signDateKey)
                }
            }
        }
    }

    deinit {
        updates?.cancel()
    }

    init() {
        let defaults = SecureDefaults.shared
        if !defaults.isKeyCreated {
            defaults.password = Const.signSecrect
        }
        let signDate = defaults.integer(forKey: Const.signDateKey)
        let nowTimestamp = Int(Date().timeIntervalSince1970)

        // 签名维持一周
        if signDate > 0, signDate < nowTimestamp, signDate + 3600 * 24 * 7 > nowTimestamp {
            isPurchased = true
        } else {
            isPurchased = false
        }

        updates = Task {
            for await update in StoreKit.Transaction.updates {
                if let transaction = try? update.payloadValue {
                    await fetchActiveTransactions()
                    await transaction.finish()
                }
            }
        }
    }

    func purchase() async throws {
        guard let product = try await Product.products(
            for: [Const.accessProductId]
        ).first else {
            throw "Error Product Id!"
        }

        let result = try await product.purchase()
        switch result {
        case let .success(verificationResult):
            if let transaction = try? verificationResult.payloadValue {
                activeTransactions.insert(transaction)
                await transaction.finish()
            }
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await fetchActiveTransactions()
    }
}

extension StoreService {
    func fetchActiveTransactions() async {
        var activeTransactions: Set<StoreKit.Transaction> = []
        for await entitlement in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? entitlement.payloadValue {
                activeTransactions.insert(transaction)
            }
        }
        self.activeTransactions = activeTransactions
    }
}
