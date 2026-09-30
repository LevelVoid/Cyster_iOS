import Foundation
import RevenueCat
import FirebaseAuth

class PremiumManager {
    static let shared = PremiumManager()
    
    static let proStatusChangedNotification = Notification.Name("PremiumManagerProStatusChanged")
    
    private(set) var isPro: Bool = false {
        didSet {
            if oldValue != isPro {
                NotificationCenter.default.post(name: PremiumManager.proStatusChangedNotification, object: nil)
            }
        }
    }
    
    private(set) var currentOffering: Offering?
    
    private init() {
        // Listen to Firebase Auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            if let user = user {
                self?.identify(userId: user.uid)
            } else {
                self?.logout()
            }
        }
    }
    
    // MARK: - Identity
    
    private func identify(userId: String) {
        Purchases.shared.logIn(userId) { [weak self] customerInfo, created, error in
            if let error = error {
                print("RevenueCat login error: \(error.localizedDescription)")
            } else if let customerInfo = customerInfo {
                self?.updateProStatus(with: customerInfo)
            }
        }
    }
    
    private func logout() {
        Purchases.shared.logOut { [weak self] customerInfo, error in
            if let error = error {
                print("RevenueCat logout error: \(error.localizedDescription)")
            } else if let customerInfo = customerInfo {
                self?.updateProStatus(with: customerInfo)
            }
        }
    }
    
    // MARK: - Offerings
    
    func fetchOfferings(completion: ((Offering?) -> Void)? = nil) {
        Purchases.shared.getOfferings { [weak self] offerings, error in
            if let error = error {
                print("RevenueCat getOfferings error: \(error.localizedDescription)")
                completion?(nil)
            } else if let offerings = offerings {
                self?.currentOffering = offerings.current
                completion?(offerings.current)
            } else {
                completion?(nil)
            }
        }
    }
    
    // MARK: - Purchasing
    
    func purchase(package: Package, completion: @escaping (Bool, Error?) -> Void) {
        Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, userCancelled in
            if userCancelled {
                completion(false, nil)
                return
            }
            if let error = error {
                completion(false, error)
            } else if let customerInfo = customerInfo {
                self?.updateProStatus(with: customerInfo)
                completion(self?.isPro ?? false, nil)
            }
        }
    }
    
    // MARK: - Restore
    
    func restorePurchases(completion: @escaping (Bool, Error?) -> Void) {
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            if let error = error {
                completion(false, error)
            } else if let customerInfo = customerInfo {
                self?.updateProStatus(with: customerInfo)
                completion(self?.isPro ?? false, nil)
            }
        }
    }
    
    // MARK: - State Management
    
    private func updateProStatus(with customerInfo: CustomerInfo) {
        let hasPro = customerInfo.entitlements["cyster_pro"]?.isActive == true
        DispatchQueue.main.async {
            self.isPro = hasPro
        }
    }
    
    func refreshProStatus() {
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            if let customerInfo = customerInfo {
                self?.updateProStatus(with: customerInfo)
            }
        }
    }
}
