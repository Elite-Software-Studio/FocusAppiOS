//
//  AppleSignInCoordinator.swift
//  FocusZone
//
//  Presents Sign in with Apple and returns the Firebase credential.
//

import Foundation
import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseAuth

@MainActor
final class AppleSignInCoordinator: NSObject {
    private var continuation: CheckedContinuation<(AuthCredential, PersonNameComponents?), Error>?
    private var currentNonce: String?

    func signIn() async throws -> (AuthCredential, PersonNameComponents?) {
        let nonce = randomNonceString()
        currentNonce = nonce
        let hashed = sha256(nonce)

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashed

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { cont in
            continuation = cont
            controller.performRequests()
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
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
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let idToken = String(data: identityTokenData, encoding: .utf8) else {
            _Concurrency.Task { @MainActor in
                self.continuation?.resume(throwing: AppleSignInError.missingCredential)
                self.continuation = nil
            }
            return
        }
        let fullName = appleIDCredential.fullName

        _Concurrency.Task { @MainActor in
            guard let nonce = self.currentNonce else {
                self.continuation?.resume(throwing: AppleSignInError.missingNonce)
                self.continuation = nil
                return
            }
            self.currentNonce = nil
            let credential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: nonce,
                fullName: fullName
            )
            self.continuation?.resume(returning: (credential, fullName))
            self.continuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let authError = error as NSError
        if authError.code == ASAuthorizationError.canceled.rawValue {
            _Concurrency.Task { @MainActor in
                continuation?.resume(throwing: AppleSignInError.canceled)
                continuation = nil
            }
        } else {
            _Concurrency.Task { @MainActor in
                continuation?.resume(throwing: error)
                continuation = nil
            }
        }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let window = scene?.keyWindow ?? scene?.windows.first { $0.isKeyWindow }
        return window ?? UIWindow()
    }
}

enum AppleSignInError: LocalizedError, Equatable {
    case missingCredential
    case missingNonce
    case canceled

    var errorDescription: String? {
        switch self {
        case .missingCredential: return "Sign in with Apple failed: missing credential."
        case .missingNonce: return "Sign in with Apple failed: missing nonce."
        case .canceled: return "Sign in was canceled."
        }
    }
}
