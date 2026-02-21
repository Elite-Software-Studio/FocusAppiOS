//
//  FirebaseSyncStatusView.swift
//  FocusZone
//
//  Shows Firebase sync status and allows manual sync.
//

import SwiftUI
import SwiftData

struct FirebaseSyncStatusView: View {
    @ObservedObject var syncService: FirebaseSyncService
    @Environment(\.modelContext) private var taskContext
    @Environment(\.inboxModelContext) private var inboxContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.title2)
                Text(statusText)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }

            if let date = syncService.lastSyncDate {
                Text(NSLocalizedString("last_synced", comment: "Last synced label") + " " + formatDate(date))
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }

            if case .syncing = syncService.syncStatus {
                ProgressView()
                    .scaleEffect(0.9)
            }

            if let error = syncService.errorMessage {
                Text(error)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.danger)
            }

            Button(action: triggerSync) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text(NSLocalizedString("sync_now", comment: "Sync now button"))
                        .font(AppFonts.subheadline())
                        .fontWeight(.medium)
                }
                .foregroundColor(canSync ? .white : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Capsule().fill(canSync ? AppColors.accent : AppColors.textSecondary.opacity(0.2)))
            }
            .disabled(!canSync)
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private var canSync: Bool {
        !syncService.syncStatus.isSyncing
    }

    private var statusIcon: String {
        switch syncService.syncStatus {
        case .idle: return "cloud"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch syncService.syncStatus {
        case .idle: return AppColors.textSecondary
        case .syncing: return AppColors.accent
        case .completed: return AppColors.success
        case .failed: return AppColors.danger
        }
    }

    private var statusText: String {
        switch syncService.syncStatus {
        case .idle: return NSLocalizedString("sync_idle", comment: "Sync idle")
        case .syncing: return NSLocalizedString("sync_syncing", comment: "Syncing")
        case .completed: return NSLocalizedString("sync_completed", comment: "Sync completed")
        case .failed: return NSLocalizedString("sync_failed", comment: "Sync failed")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func triggerSync() {
        _Concurrency.Task {
            await syncService.sync(taskContext: taskContext, inboxContext: inboxContext)
        }
    }
}

extension FirebaseSyncService.SyncStatus {
    var isSyncing: Bool {
        if case .syncing = self { return true }
        return false
    }
}

#Preview {
    let taskContainer = try! ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let inboxContainer = try! ModelContainer(for: QuickNote.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return FirebaseSyncStatusView(syncService: FirebaseSyncService.shared)
        .environment(\.modelContext, taskContainer.mainContext)
        .environment(\.inboxModelContext, inboxContainer.mainContext)
}
