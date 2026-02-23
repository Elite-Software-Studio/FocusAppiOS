//
//  AccountSectionView.swift
//  FocusZone
//
//  Account / Sign in with Apple section for Settings. Nice UX for sync across devices.
//

import SwiftUI
import SwiftData

struct AccountSectionView: View {
    @ObservedObject var authService: FirebaseAuthService
    @EnvironmentObject var syncService: FirebaseSyncService
    @Environment(\.modelContext) private var taskContext
    @Environment(\.inboxModelContext) private var inboxContext

    @State private var isSigningIn = false
    @State private var errorMessage: String?
    @State private var showSignOutConfirm = false

    private let coordinator = AppleSignInCoordinator()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if authService.isAnonymous {
                signedOutCard
            } else {
                signedInCard
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .confirmationDialog(LanguageManager.localized("sign_out", comment: "Sign out"), isPresented: $showSignOutConfirm) {
            Button(LanguageManager.localized("sign_out", comment: "Sign out"), role: .destructive) { signOut() }
            Button(LanguageManager.localized("cancel", comment: "Cancel"), role: .cancel) {}
        } message: {
            Text(LanguageManager.localized("sign_out_confirm_message", comment: "Sign out confirmation"))
        }
    }

    private var signedOutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "icloud.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(LanguageManager.localized("sync_across_devices", comment: "Sync across devices title"))
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                    Text(LanguageManager.localized("sign_in_apple_subtitle", comment: "Sign in with Apple subtitle"))
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
            }

            if let error = errorMessage {
                Text(error)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.danger)
            }

            if isSigningIn {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.9)
                    Text(LanguageManager.localized("signing_in", comment: "Signing in..."))
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                SignInWithAppleButtonView(action: startSignInWithApple)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    private var signedInCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayTitle)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                    Text(LanguageManager.localized("sync_enabled_all_devices", comment: "Sync enabled on all devices"))
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
            }

            Button(action: { showSignOutConfirm = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text(LanguageManager.localized("sign_out", comment: "Sign out"))
                        .font(AppFonts.subheadline())
                        .fontWeight(.medium)
                }
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(AppColors.textSecondary.opacity(0.12)))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    private var displayTitle: String {
        if let name = authService.userDisplayName, !name.isEmpty {
            return String(format: LanguageManager.localized("signed_in_as", comment: "Signed in as %@"), name)
        }
        return LanguageManager.localized("signed_in_with_apple", comment: "Signed in with Apple")
    }

    private func startSignInWithApple() {
        errorMessage = nil
        isSigningIn = true
        _Concurrency.Task {
            do {
                let (credential, fullName) = try await coordinator.signIn()
                try await authService.signInOrLinkWithApple(credential: credential, fullName: fullName)
                await triggerSync()
            } catch {
                if (error as? AppleSignInError) != .canceled {
                    errorMessage = error.localizedDescription
                }
            }
            await MainActor.run { isSigningIn = false }
        }
    }

    private func triggerSync() async {
        await syncService.sync(taskContext: taskContext, inboxContext: inboxContext)
    }

    private func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Signed out") {
    AccountSectionView(authService: FirebaseAuthService.shared)
        .environmentObject(FirebaseSyncService.shared)
        .environment(\.modelContext, try! ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext)
        .environment(\.inboxModelContext, try! ModelContainer(for: QuickNote.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext)
}
