import SwiftUI

private let conflictRed = Color.red.opacity(0.85)
private let conflictBg = Color.red.opacity(0.08)

/// Container for overlapping tasks: header, stacked task cards, resolve button.
/// Style: light red background, rounded corners, 4pt left red border, padding.
struct ConflictGroupContainer: View {
    let conflictGroup: ConflictGroup
    let viewModel: TimelineViewModel
    let onTaskTap: (Task) -> Void
    let onResolve: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ConflictHeader(start: conflictGroup.start)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                ForEach(conflictGroup.tasks) { task in
                    TaskCard(
                        title: task.title,
                        time: viewModel.timeRange(for: task),
                        icon: task.icon,
                        color: viewModel.taskColor(task),
                        isCompleted: task.isCompleted,
                        durationMinutes: task.durationMinutes,
                        task: task,
                        timelineViewModel: viewModel,
                        isInConflictGroup: true
                    )
                    .onTapGesture { onTaskTap(task) }
                }
            }
            
            ResolveConflictButton(action: onResolve)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(conflictBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.bottom,16)
    }
}

// MARK: - Conflict Header
private struct ConflictHeader: View {
    let start: Date
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundColor(conflictRed)
            Text(formattedTime)
                .font(AppFonts.caption())
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeStr = formatter.string(from: start)
        return String(format: LanguageManager.localized("conflict_at_time", comment: "Conflict at time"), timeStr)
    }
}

// MARK: - Resolve Button
private struct ResolveConflictButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                Text(LanguageManager.localized("resolve_conflict", comment: "Resolve conflict button"))
                    .font(AppFonts.caption())
                    .fontWeight(.medium)
            }
            .foregroundColor(conflictRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
