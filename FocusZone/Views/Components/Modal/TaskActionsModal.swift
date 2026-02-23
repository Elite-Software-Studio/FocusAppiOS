import SwiftUI

struct TaskActionsModal: View {
    let task: Task
    let onStart: () -> Void
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: (DeletionType) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingTimer = false
    @State private var showingDeletionOptions = false
    @ObservedObject private var timerService = TaskTimerService.shared
    
    enum DeletionType {
        case instance
        case allInstances
        case futureInstances
    }
    
    // Computed property to check if current time is within task's scheduled window
    private var isCurrentTimeInTaskWindow: Bool {
        let now = Date()
        let taskStartTime = task.startTime
        let taskEndTime = taskStartTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        // Show button only when current time is between task start and end time
        return now >= taskStartTime && now <= taskEndTime
    }
    

    
    var body: some View {
        VStack(spacing: 8) {
                    // Task Info Header Card
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            Text(task.icon)
                                .font(.system(size: 40))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.title)
                                    .font(AppFonts.headline())
                                    .foregroundColor(AppColors.textPrimary)
                                    .multilineTextAlignment(.leading)
                                
                                if let taskType = task.taskType {
                                    Text(taskType.displayName)
                                        .font(AppFonts.caption())
                                        .foregroundColor(.gray)
                                }
                                
                                // Show task type indicator
                                if task.isGeneratedFromRepeat {
                                    Text(LanguageManager.localized("repeating_task_instance", comment: "Repeating task instance label"))
                                        .font(AppFonts.caption())
                                        .foregroundColor(.orange)
                                } else if task.isParentTask {
                                    Text(LanguageManager.localized("repeating_task_series", comment: "Repeating task series label"))
                                        .font(AppFonts.caption())
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(task.durationMinutes)m")
                                .font(AppFonts.subheadline())
                                .foregroundColor(task.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(task.color.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Progress if any
                        if timerService._minutesRemain(for: task) > 0 {
                            VStack(spacing: 6) {
                                HStack {
                                    Text(LanguageManager.localized("progress", comment: "Progress label"))
                                        .font(AppFonts.caption())
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(timerService.calculateSmartElapsedTime(for: task))/\(task.durationMinutes)m")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.gray)
                                }
                                
                                ProgressView(
                                    value: Double(timerService.calculateSmartElapsedTime(for: task)) / Double(task.durationMinutes),
                                    label: {
                                        Text("")
                                    }
                                )
                                .progressViewStyle(LinearProgressViewStyle(tint: task.color))
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.card)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    
                    // Action Buttons Card
                    VStack(spacing: 1) {
                        if (!task.isCompleted || timerService._minutesRemain(for: task) < 0) && isCurrentTimeInTaskWindow {
                            TaskActionButton(
                                title: LanguageManager.localized("start_focus_session", comment: "Start focus session button"),
                                icon: "play.fill",
                                color: task.color,
                                action: {
                                    showingTimer = true
                                }
                            )
                        }
                        
                        if !task.isCompleted {
                            TaskActionButton(
                                title: LanguageManager.localized("mark_complete", comment: "Mark complete button"),
                                icon: "checkmark.circle",
                                color: .green,
                                action: {
                                    onComplete()
                                    dismiss()
                                }
                            )
                        }
                        
                        TaskActionButton(
                            title: LanguageManager.localized("edit_task", comment: "Edit task button"),
                            icon: "pencil",
                            color: .blue,
                            action: {
                                onEdit()
                                dismiss()
                            }
                        )
                        
                        TaskActionButton(
                            title: LanguageManager.localized("duplicate_task", comment: "Duplicate task button"),
                            icon: "doc.on.doc",
                            color: .orange,
                            action: {
                                onDuplicate()
                                dismiss()
                            }
                        )
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        TaskActionButton(
                            title: LanguageManager.localized("delete_task", comment: "Delete task button"),
                            icon: "trash",
                            color: .red,
                            isDestructive: true,
                            action: {
                                if task.isGeneratedFromRepeat || task.isChildTask || task.isParentTask {
                                    showingDeletionOptions = true
                                } else {
                                    onDelete(.instance)
                                    dismiss()
                                }
                            }
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.card)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    
//                    // TODO: Cancel Button
//                    Button(action: { dismiss() }) {
//                        Text("Cancel")
//                            .font(AppFonts.body())
//                            .foregroundColor(.gray)
//                            .padding(.vertical, 16)
//                            .frame(maxWidth: .infinity)
//                            .background(
//                                RoundedRectangle(cornerRadius: 12)
//                                    .fill(Color.gray.opacity(0.1))
//                            )
//                    }
//                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24) // Add safe area padding for bottom
        .fullScreenCover(isPresented: $showingTimer, onDismiss: {
            onStart()
            dismiss()
        }) {
            TaskTimer(task: task)
        }
        .sheet(isPresented: $showingDeletionOptions) {
            TaskDeletionModal(
                task: task,
                onDeleteInstance: {
                    onDelete(.instance)
                },
                onDeleteAllInstances: {
                    onDelete(.allInstances)
                },
                onDeleteFutureInstances: {
                    onDelete(.futureInstances)
                },
                onCancel: {
                    showingDeletionOptions = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

struct TaskActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : color)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppFonts.body())
                    .foregroundColor(isDestructive ? .red : AppColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DeletionOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.textPrimary)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(AppColors.card)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TaskActionsModal(
        task: Task(
            id: UUID(),
            title: "Sample Task",
            icon: "💻",
            startTime: Date(),
            durationMinutes: 60,
            color: .blue,
            isCompleted: false,
            taskType: .work
        ),
        onStart: {},
        onComplete: {},
        onEdit: {},
        onDuplicate: {  },
        onDelete: { _ in }
    )
}
