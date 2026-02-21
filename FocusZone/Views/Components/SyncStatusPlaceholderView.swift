//
//  SyncStatusPlaceholderView.swift
//  FocusZone
//
//  Placeholder for Sync section in Settings. Will be replaced by FirebaseSyncStatusView.
//

import SwiftUI

struct SyncStatusPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "internaldrive")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.title2)
                Text(NSLocalizedString("sync_local_only", comment: "Data stored locally"))
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
            }
            Text(NSLocalizedString("sync_firebase_coming", comment: "Firebase sync coming soon"))
                .font(AppFonts.caption())
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

#Preview {
    SyncStatusPlaceholderView()
}
