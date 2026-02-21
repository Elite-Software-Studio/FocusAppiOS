//
//  FirebaseAuthService.swift
//  FocusZone
//
//  Anonymous auth by default; Sign in with Apple to sync across devices.
//

import Foundation
import FirebaseAuth

@MainActor
final class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()

    @Published private(set) var userId: String?
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var isAnonymous: Bool = true
    @Published private(set) var errorMessage: String?
    @Published private(set) var userDisplayName: String?

    private let displayNameKey = "focuszone_apple_display_name"

    private init() {
        userDisplayName = UserDefaults.standard.string(forKey: displayNameKey)
    }

    /// Call once at app launch. Signs in anonymously when online if no user.
    func configure() {
        if let user = Auth.auth().currentUser {
            updateState(from: user)
            return
        }
        signInAnonymouslyIfNeeded()
    }

    private func updateState(from user: User) {
        userId = user.uid
        isSignedIn = true
        isAnonymous = user.isAnonymous
        errorMessage = nil
    }

    /// Sign in anonymously. Safe to call when offline; will retry when online.
    func signInAnonymouslyIfNeeded() {
        if let user = Auth.auth().currentUser {
            updateState(from: user)
            return
        }
        Auth.auth().signInAnonymously { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isSignedIn = false
                    self?.userId = nil
                    self?.isAnonymous = true
                    return
                }
                if let user = result?.user {
                    self?.updateState(from: user)
                }
            }
        }
    }

    /// Sign in or link with Apple credential. If currently anonymous, links to keep data; otherwise signs in.
    func signInOrLinkWithApple(credential: AuthCredential, fullName: PersonNameComponents?) async throws {
        let auth = Auth.auth()
        if let user = auth.currentUser, user.isAnonymous {
            let result = try await user.link(with: credential)
            if let name = fullName, let display = [name.givenName, name.familyName].compactMap({ $0 }).joined(separator: " ").nilIfEmpty {
                userDisplayName = display
                UserDefaults.standard.set(display, forKey: displayNameKey)
            }
            updateState(from: result.user)
        } else {
            let result = try await auth.signIn(with: credential)
            if let name = fullName, let display = [name.givenName, name.familyName].compactMap({ $0 }).joined(separator: " ").nilIfEmpty {
                userDisplayName = display
                UserDefaults.standard.set(display, forKey: displayNameKey)
            }
            updateState(from: result.user)
        }
    }

    /// Sign out. Next app launch will sign in anonymously again.
    func signOut() throws {
        try Auth.auth().signOut()
        userId = nil
        isSignedIn = false
        isAnonymous = true
        userDisplayName = nil
        UserDefaults.standard.removeObject(forKey: displayNameKey)
        signInAnonymouslyIfNeeded()
    }

    func linkWithCredential(_ credential: AuthCredential) async throws {
        guard let user = Auth.auth().currentUser else { return }
        _ = try await user.link(with: credential)
        updateState(from: user)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
