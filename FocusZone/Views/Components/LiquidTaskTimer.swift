import SwiftUI
import SwiftData

/// Modern Liquid design TaskTimer with glass surfaces and fluid animations
struct LiquidTaskTimer: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var timerService = TaskTimerService.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss: DismissAction
    
    let task: Task

    @State private var showCompletionAlert = false
    @State private var showCelebration = false
    @State private var isAutoCompleted = false
    @StateObject private var focusManager = FocusModeManager()

    var body: some View {
        NavigationView {
            ZStack {
                // Liquid mesh background
                LiquidDesignSystem.Gradients.meshBackground(colorScheme)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: LiquidDesignSystem.Spacing.xl) {
                        // Task Info Header
                        taskInfoHeader
                            .padding(.top, LiquidDesignSystem.Spacing.lg)
                        
                        // Progress Circle
                        progressCircle
                        
                        // Statistics Card
                        if let currentTask = timerService.currentTask {
                            statisticsCard(for: currentTask)
                        }
                        
                        // Task Controls
                        controlButtons
                        
                        // Focus Status Banner
                        if focusManager.isActiveFocus {
                            FocusStatusBanner(
                                mode: focusManager.currentFocusMode,
                                blockedNotifications: focusManager.blockedNotifications
                            )
                        }
                        
                        Spacer(minLength: LiquidDesignSystem.Spacing.xxl)
                    }
                    .padding(.horizontal, LiquidDesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Focus Timer")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(LiquidDesignSystem.Typography.bodyLarge)
                    .foregroundColor(LiquidDesignSystem.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextTertiary(colorScheme))
                    }
                }
            }
        }
        .onAppear {
            timerService.setModelContext(modelContext)
            if timerService.currentTask == nil {
                timerService.startTask(task)
            }

            if ((task.focusSettings?.isEnabled) != nil) {
                focusManager.blockedNotifications = 1
                Task {
                    await focusManager.activateFocus(mode: .deepWork, duration: TimeInterval(timerService.currentRemainingMinutes * 60), task: task)
                }
            }
        }
        .onChange(of: timerService.currentTask?.isCompleted) { _, isCompleted in
            if isCompleted == true && !isAutoCompleted {
                isAutoCompleted = true
                withAnimation(LiquidDesignSystem.Animation.gentle) {
                    showCelebration = true
                    timerService.completeTask()
                }
            }
        }
        .overlay {
            if showCelebration {
                ConfettiCelebrationView(
                    isPresented: $showCelebration,
                    title: "Nice work!",
                    subtitle: "You completed \(task.title)",
                    accent: task.color,
                    duration: 5
                ) {
                    timerService.completeTask()
                    timerService.stopCurrentTask()
                    dismiss()
                }
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - Task Info Header
    
    private var taskInfoHeader: some View {
        VStack(spacing: LiquidDesignSystem.Spacing.md) {
            // Icon
            Text(task.icon)
                .font(.system(size: 64))
            
            // Title
            Text(task.title)
                .font(LiquidDesignSystem.Typography.headlineMedium)
                .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextPrimary(colorScheme))
                .multilineTextAlignment(.center)
            
            // Task Type
            if let taskType = task.taskType {
                HStack(spacing: LiquidDesignSystem.Spacing.xs) {
                    Text(taskType.icon)
                        .font(.title3)
                    Text(taskType.displayName)
                        .font(LiquidDesignSystem.Typography.bodyMedium)
                        .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextSecondary(colorScheme))
                }
            }
            
            // Planned duration
            Text("Planned: \(task.durationMinutes) minutes")
                .font(LiquidDesignSystem.Typography.labelMedium)
                .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextTertiary(colorScheme))
        }
    }
    
    // MARK: - Progress Circle
    
    private var progressCircle: some View {
        ZStack {
            // Glass background circle
            Circle()
                .fill(LiquidDesignSystem.Colors.adaptiveGlassBackground(colorScheme))
                .frame(width: 300, height: 300)
                .overlay(
                    Circle()
                        .strokeBorder(
                            LiquidDesignSystem.Colors.adaptiveGlassBorder(colorScheme),
                            lineWidth: 1
                        )
                )
            
            // Progress track
            Circle()
                .stroke(
                    LiquidDesignSystem.Colors.adaptiveSurfaceSecondary(colorScheme),
                    lineWidth: 16
                )
                .frame(width: 280, height: 280)
            
            // Progress fill
            Circle()
                .trim(from: 0, to: timerService.currentProgressPercentage)
                .stroke(
                    LinearGradient(
                        colors: [
                            timerService.isOvertime ? LiquidDesignSystem.Colors.error : task.color,
                            timerService.isOvertime ? LiquidDesignSystem.Colors.error.opacity(0.7) : task.color.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(LiquidDesignSystem.Animation.smooth, value: timerService.currentProgressPercentage)
            
            // Center content
            VStack(spacing: LiquidDesignSystem.Spacing.sm) {
                // Elapsed time
                Text(timerService.formattedElapsedTime)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(
                        timerService.isOvertime 
                            ? LiquidDesignSystem.Colors.error 
                            : LiquidDesignSystem.Colors.adaptiveTextPrimary(colorScheme)
                    )
                    .monospacedDigit()
                
                // Status badge
                statusBadge
            }
        }
        .shadow(
            color: task.color.opacity(0.2),
            radius: 30,
            x: 0,
            y: 10
        )
    }
    
    // MARK: - Status Badge
    
    @ViewBuilder
    private var statusBadge: some View {
        if timerService.currentTask?.isCompleted == true {
            LiquidBadge("COMPLETED!", color: LiquidDesignSystem.Colors.success)
                .font(LiquidDesignSystem.Typography.labelMedium)
        } else if timerService.isOvertime {
            LiquidBadge("OVERTIME!", color: LiquidDesignSystem.Colors.error)
                .font(LiquidDesignSystem.Typography.labelMedium)
        } else if timerService.currentRemainingMinutes > 0 {
            Text("Remaining: \(timerService.formattedRemainingTime)")
                .font(LiquidDesignSystem.Typography.labelMedium)
                .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextSecondary(colorScheme))
        } else {
            LiquidBadge("Time's up!", color: LiquidDesignSystem.Colors.warning)
                .font(LiquidDesignSystem.Typography.labelMedium)
        }
        
        if timerService.currentTask?.status == .paused {
            LiquidBadge("PAUSED", color: LiquidDesignSystem.Colors.warning)
                .font(LiquidDesignSystem.Typography.labelSmall)
                .padding(.top, LiquidDesignSystem.Spacing.xxs)
        }
    }
    
    // MARK: - Control Buttons
    
    @ViewBuilder
    private var controlButtons: some View {
        if timerService.currentTask == nil || timerService.currentTask?.isCompleted == true {
            // Start/Restart button
            Button(action: {
                if timerService.currentTask?.isCompleted == true {
                    timerService.stopCurrentTask()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        timerService.startTask(task)
                    }
                } else {
                    timerService.startTask(task)
                }
            }) {
                HStack(spacing: LiquidDesignSystem.Spacing.sm) {
                    Image(systemName: timerService.currentTask?.isCompleted == true ? "arrow.clockwise" : "play.fill")
                        .font(.title2)
                    Text(timerService.currentTask?.isCompleted == true ? "Restart" : "Start")
                        .font(LiquidDesignSystem.Typography.titleMedium)
                }
            }
            .liquidButton(size: .large, variant: .primary, isFullWidth: true)
            
        } else if timerService.currentTask?.isActive ?? false {
            // Complete button for active task
            Button(action: {
                withAnimation(LiquidDesignSystem.Animation.smooth) {
                    timerService.completeTask()
                }
            }) {
                HStack(spacing: LiquidDesignSystem.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    Text("Complete")
                        .font(LiquidDesignSystem.Typography.titleMedium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [
                                    LiquidDesignSystem.Colors.success,
                                    LiquidDesignSystem.Colors.success.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: LiquidDesignSystem.Colors.success.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 4
                )
            }
        }
    }
    
    // MARK: - Statistics Card
    
    private func statisticsCard(for currentTask: Task) -> some View {
        HStack(spacing: LiquidDesignSystem.Spacing.lg) {
            // Time Spent
            statItem(
                title: "Time Spent",
                value: "\(timerService.currentElapsedMinutes)m",
                icon: "clock"
            )
            
            LiquidDivider()
                .frame(width: 1, height: 40)
            
            // Progress
            statItem(
                title: "Progress",
                value: "\(Int(timerService.currentProgressPercentage * 100))%",
                icon: "chart.bar.fill"
            )
            
            LiquidDivider()
                .frame(width: 1, height: 40)
            
            // Status
            VStack(spacing: LiquidDesignSystem.Spacing.xxs) {
                HStack(spacing: LiquidDesignSystem.Spacing.xxs) {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundColor(statusColor(for: currentTask.status))
                    
                    Text("Status")
                        .font(LiquidDesignSystem.Typography.labelSmall)
                        .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextTertiary(colorScheme))
                }
                
                Text(statusText(for: currentTask.status))
                    .font(LiquidDesignSystem.Typography.labelMedium)
                    .foregroundColor(statusColor(for: currentTask.status))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(LiquidDesignSystem.Spacing.lg)
        .glassSurface(
            cornerRadius: LiquidDesignSystem.CornerRadius.lg,
            padding: 0
        )
    }
    
    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: LiquidDesignSystem.Spacing.xs) {
            HStack(spacing: LiquidDesignSystem.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextTertiary(colorScheme))
                
                Text(title)
                    .font(LiquidDesignSystem.Typography.labelSmall)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextTertiary(colorScheme))
            }
            
            Text(value)
                .font(LiquidDesignSystem.Typography.titleMedium)
                .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextPrimary(colorScheme))
        }
    }
    
    // MARK: - Helper Methods
    
    private func statusText(for status: TaskStatus) -> String {
        switch status {
        case .scheduled: return "Scheduled"
        case .inProgress: return "Active"
        case .paused: return "Paused"
        case .completed: return "Done"
        case .cancelled: return "Cancelled"
        }
    }
    
    private func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .scheduled: return LiquidDesignSystem.Colors.info
        case .inProgress: return LiquidDesignSystem.Colors.success
        case .paused: return LiquidDesignSystem.Colors.warning
        case .completed: return LiquidDesignSystem.Colors.success
        case .cancelled: return LiquidDesignSystem.Colors.error
        }
    }
}

// MARK: - Preview

#Preview {
    LiquidTaskTimer(task: Task(
        id: UUID(),
        title: "Focus Session",
        icon: "💻",
        startTime: Date(),
        durationMinutes: 60,
        color: .blue,
        isCompleted: false,
        taskType: .work
    ))
}

