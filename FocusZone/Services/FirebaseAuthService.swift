//
//  FirebaseAuthService.swift
//  FocusZone
//
//  Anonymous auth for Firebase. No user action required; used for optional sync when online.
//

import Foundation
import FirebaseAuth

@MainActor
final class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()

    @Published private(set) var userId: String?
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var errorMessage: String?

    private init() {}

    /// Call once at app launch (e.g. from FocusZoneApp). Signs in anonymously when online.
    func configure() {
        // FirebaseApp.configure() must be called by the app (e.g. in FocusZoneApp.init or .task)
        signInAnonymouslyIfNeeded()
    }

    /// Sign in anonymously. Safe to call when offline; will retry when online.
    func signInAnonymouslyIfNeeded() {
        if let user = Auth.auth().currentUser {
            userId = user.uid
            isSignedIn = true
            errorMessage = nil
            return
        }
        Auth.auth().signInAnonymously { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isSignedIn = false
                    self?.userId = nil
                    return
                }
                self?.userId = result?.user.uid
                self?.isSignedIn = result?.user.uid != nil
                self?.errorMessage = nil
            }
        }
    }

    /// For later: link anonymous to email/Google so the same user can use multiple devices.
    func linkWithCredential(_ credential: AuthCredential) async throws {
        guard let user = Auth.auth().currentUser else { return }
        _ = try await user.link(with: credential)
        userId = user.uid
    }
}
