import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import RevenueCat

// MARK: - AuthResult

struct AuthResult {
    let uid: String
    let idToken: String
    let refreshToken: String
}

// MARK: - AuthManagerDelegate

protocol AuthManagerDelegate: AnyObject {
    func authManagerDidAuthenticate(result: AuthResult)
    func authManagerDidFail(error: Error)
}

// MARK: - AuthManager

final class AuthManager: NSObject {

    // MARK: Singleton

    static let shared = AuthManager()
    private override init() { super.init() }

    // MARK: Properties

    weak var delegate: AuthManagerDelegate?

    /// Nonce used for Apple Sign-In; stored so we can validate the credential
    private var currentNonce: String?

    /// Presenter VC needed for both providers
    private weak var presentingViewController: UIViewController?

    // MARK: - Apple Sign-In

    func signInWithApple(from viewController: UIViewController) {
        presentingViewController = viewController

        let nonce = randomNonce()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Google Sign-In

    func signInWithGoogle(from viewController: UIViewController) {
        presentingViewController = viewController

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            delegate?.authManagerDidFail(error: AuthError.missingClientID)
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] result, error in
            if let error = error {
                self?.delegate?.authManagerDidFail(error: error)
                return
            }
            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                self?.delegate?.authManagerDidFail(error: AuthError.missingGoogleToken)
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            self?.signInToFirebase(credential: credential)
        }
    }

    // MARK: - Firebase Sign-In

    private func signInToFirebase(credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            if let error = error {
                self?.delegate?.authManagerDidFail(error: error)
                return
            }

            guard let user = authResult?.user else {
                self?.delegate?.authManagerDidFail(error: AuthError.unknownFirebaseUser)
                return
            }

            user.getIDToken { [weak self] idToken, error in
                if let error = error {
                    self?.delegate?.authManagerDidFail(error: error)
                    return
                }

                guard let idToken = idToken else {
                    self?.delegate?.authManagerDidFail(error: AuthError.missingIDToken)
                    return
                }

                let refreshToken = user.refreshToken ?? ""
                let uid = user.uid

                // Persist to Keychain
                KeychainHelper.save(key: .firebaseUID, value: uid)
                KeychainHelper.save(key: .firebaseIDToken, value: idToken)
                KeychainHelper.save(key: .refreshToken, value: refreshToken)

                // Initialize RevenueCat identity
                Purchases.shared.logIn(uid) { _, _, error in
                    if let error = error {
                        print("⚠️ RevenueCat logIn error: \(error.localizedDescription)")
                    }
                }

                let result = AuthResult(uid: uid, idToken: idToken, refreshToken: refreshToken)
                DispatchQueue.main.async {
                    self?.delegate?.authManagerDidAuthenticate(result: result)
                }
            }
        }
    }

    // MARK: - Nonce Helpers (Apple Sign-In)

    private func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let appleIDToken = appleIDCredential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8)
        else {
            delegate?.authManagerDidFail(error: AuthError.invalidAppleCredential)
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        signInToFirebase(credential: credential)
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        // User cancelled — don't propagate as a real error
        guard (error as? ASAuthorizationError)?.code != .canceled else { return }
        delegate?.authManagerDidFail(error: error)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentingViewController?.view.window
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
            ?? UIWindow()
    }
}

// MARK: - AuthError

enum AuthError: LocalizedError {
    case missingClientID
    case missingGoogleToken
    case missingIDToken
    case invalidAppleCredential
    case unknownFirebaseUser

    var errorDescription: String? {
        switch self {
        case .missingClientID:        return "Firebase client ID is missing."
        case .missingGoogleToken:     return "Could not retrieve Google ID token."
        case .missingIDToken:         return "Could not retrieve Firebase ID token."
        case .invalidAppleCredential: return "Apple credential is invalid."
        case .unknownFirebaseUser:    return "Firebase returned no user after sign-in."
        }
    }
}
