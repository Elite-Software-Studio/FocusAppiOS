import SwiftUI

/// Modern Liquid design TaskActionsModal with glass bottom sheet
struct LiquidTaskActionsModal: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    let task: Task
    let onStart: () -> Void
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: (TaskActionsModal.DeletionType) -> Void
    
    @State private var showingTimer = false
    @State private var showingDeletionOptions = false
    @ObservedObject private var timerService = TaskTimerService.shared
    
    // Computed property to check if current time is within task's scheduled window
    private var isCurrentTimeInTaskWindow: Bool {
        let now = Date()
        let taskStartTime = task.startTime
        let taskEndTime = taskStartTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        return now >= taskStartTime && now <= taskEndTime
    }
    
    var body: some View {
        VStack(spacing: LiquidDesignSystem.Spacing.lg) {
            // Drag indicator
            dragIndicator
            
            // Task Info Header
            taskInfoCard
            
            // Action Buttons
            actionButtonsStack
        }
        .padding(LiquidDesignSystem.Spacing.lg)
        .background(backgroundView)
        .sheet(isPresented: $showingTimer) {
            LiquidTaskTimer(task: task)
        }
        .actionSheet(isPresented: $showingDeletionOptions) {
            deletionActionSheet
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        LiquidDesignSystem.Gradients.meshBackground(colorScheme)
            .ignoresSafeArea()
    }
    
    // MARK: - Drag Indicator
    
    private var dragIndicator: some View {
        Capsule()
            .fill(LiquidDesignSystem.Colors.adaptiveTextTertiary(colorScheme).opacity(0.3))
            .frame(width: 40, height: 5)
            .padding(.top, LiquidDesignSystem.Spacing.xs)
    }
    
    // MARK: - Task Info Card
    
    private var taskInfoCard: some View {
        VStack(spacing: LiquidDesignSystem.Spacing.md) {
            HStack(spacing: LiquidDesignSystem.Spacing.md) {
                // Icon
                Text(task.icon)
                    .font(.system(size: 48))
                
                // Task Details
                VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.xxs) {
                    Text(task.title)
                        .font(LiquidDesignSystem.Typography.headlineSmall)
                        .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextPrimary(colorScheme))
                        .multilineTextAlignment(.leading)
                    
                    if let taskType = task.taskType {
                        Text(taskType.displayName)
                            .font(LiquidDesignSystem.Typography.labelMedium)
                            .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextSecondary(colorScheme))
                    }
                    
                    // Repeat indicator
                    if task.isGeneratedFromRepeat {
                        LiquidBadge(
                            NSLocalizedString("repeating_task_instance", comment: "Repeating task instance label"),
                            color: LiquidDesignSystem.Colors.warning
                        )
                    } else if task.isParentTask {
                        LiquidBadge(
                            NSLocalizedString("repeating_task_series", comment: "Repeating task series label"),
                            color: LiquidDesignSystem.Colors.info
                        )
                    }
                }
                
                Spacer()
                
                // Duration badge
                Text("\(task.durationMinutes)m")
                    .font(LiquidDesignSystem.Typography.labelLarge)
                    .foregroundColor(task.color)
                    .padding(.horizontal, LiquidDesignSystem.Spacing.sm)
                    .padding(.vertical, LiquidDesignSystem.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(task.color.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    )
            }
            
            // Progress bar if task has started
            if timerService._minutesRemain(for: task) > 0 {
                progressSection
            }
        }
        .padding(LiquidDesignSystem.Spacing.lg)
        .glassSurface(
            cornerRadius: LiquidDesignSystem.CornerRadius.lg,
            padding: 0
        )
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: LiquidDesignSystem.Spacing.xs) {
            HStack {
                Text(NSLocalizedString("progress", comment: "Progress label"))
                    .font(LiquidDesignSystem.Typography.labelSmall)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextSecondary(colorScheme))
                
                Spacer()
                
                Text("\(timerService.calculateSmartElapsedTime(for: task))/\(task.durationMinutes)m")
                    .font(LiquidDesignSystem.Typography.labelSmall)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextSecondary(colorScheme))
            }
            
            LiquidProgressBar(
                progress: Double(timerService.calculateSmartElapsedTime(for: task)) / Double(task.durationMinutes),
                height: 6
            )
        }
    }
    
    // MARK: - Action Buttons Stack
    
    private var actionButtonsStack: some View {
        VStack(spacing: LiquidDesignSystem.Spacing.sm) {
            // Start Focus Session
            if (!task.isCompleted || timerService._minutesRemain(for: task) < 0) && isCurrentTimeInTaskWindow {
                actionButton(
                    title: NSLocalizedString("start_focus_session", comment: "Start focus session button"),
                    icon: "play.fill",
                    color: task.color,
                    isPrimary: true,
                    action: {
                        showingTimer = true
                    }
                )
            }
            
            // Mark Complete
            if !task.isCompleted {
                actionButton(
                    title: NSLocalizedString("mark_complete", comment: "Mark complete button"),
                    icon: "checkmark.circle.fill",
                    color: LiquidDesignSystem.Colors.success,
                    action: {
                        onComplete()
                        dismiss()
                    }
                )
            }
            
            // Edit Task
            actionButton(
                title: NSLocalizedString("edit_task", comment: "Edit task button"),
                icon: "pencil",
                color: LiquidDesignSystem.Colors.info,
                action: {
                    onEdit()
                    dismiss()
                }
            )
            
            // Duplicate Task
            actionButton(
                title: NSLocalizedString("duplicate_task", comment: "Duplicate task button"),
                icon: "doc.on.doc",
                color: LiquidDesignSystem.Colors.warning,
                action: {
                    onDuplicate()
                    dismiss()
                }
            )
            
            // Delete Task
            actionButton(
                title: NSLocalizedString("delete_task", comment: "Delete task button"),
                icon: "trash",
                color: LiquidDesignSystem.Colors.error,
                isDestructive: true,
                action: {
                    if task.isGeneratedFromRepeat || task.isParentTask {
                        showingDeletionOptions = true
                    } else {
                        onDelete(.instance)
                        dismiss()
                    }
                }
            )
        }
    }
    
    // MARK: - Action Button
    
    private func actionButton(
        title: String,
        icon: String,
        color: Color,
        isPrimary: Bool = false,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: LiquidDesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isPrimary ? .white : color)
                
                Text(title)
                    .font(LiquidDesignSystem.Typography.titleSmall)
                    .foregroundColor(isPrimary ? .white : LiquidDesignSystem.Colors.adaptiveTextPrimary(colorScheme))
                
                Spacer()
            }
            .padding(LiquidDesignSystem.Spacing.md)
            .background(
                Group {
                    if isPrimary {
                        RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                            .fill(LiquidDesignSystem.Colors.adaptiveSurfaceSecondary(colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                                    .strokeBorder(
                                        isDestructive 
                                            ? color.opacity(0.3)
                                            : LiquidDesignSystem.Colors.adaptiveGlassBorder(colorScheme),
                                        lineWidth: isDestructive ? 1.5 : 1
                                    )
                            )
                    }
                }
            )
            .shadow(
                color: isPrimary ? color.opacity(0.3) : Color.black.opacity(0.05),
                radius: isPrimary ? 12 : 4,
                x: 0,
                y: isPrimary ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Deletion Action Sheet
    
    private var deletionActionSheet: ActionSheet {
        ActionSheet(
            title: Text(NSLocalizedString("delete_task", comment: "Delete task title")),
            message: Text(NSLocalizedString("choose_deletion_type", comment: "Choose deletion type message")),
            buttons: [
                .destructive(Text(NSLocalizedString("delete_this_instance", comment: "Delete this instance"))) {
                    onDelete(.instance)
                    dismiss()
                },
                .destructive(Text(NSLocalizedString("delete_all_instances", comment: "Delete all instances"))) {
                    onDelete(.allInstances)
                    dismiss()
                },
                .destructive(Text(NSLocalizedString("delete_future_instances", comment: "Delete future instances"))) {
                    onDelete(.futureInstances)
                    dismiss()
                },
                .cancel()
            ]
        )
    }
}

// MARK: - Preview

#Preview {
    LiquidTaskActionsModal(
        task: Task(
            title: "Morning Meeting",
            icon: "☕️",
            startTime: Date(),
            durationMinutes: 60,
            color: .blue
        ),
        onStart: {},
        onComplete: {},
        onEdit: {},
        onDuplicate: {},
        onDelete: { _ in }
    )
}

