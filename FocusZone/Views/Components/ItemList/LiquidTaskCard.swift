import SwiftUI

/// Modern Liquid/Glass design TaskCard
struct LiquidTaskCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var title: String
    var time: String
    var icon: String
    var color: Color
    var isCompleted: Bool
    var durationMinutes: Int = 60
    var task: Task? = nil
    var timelineViewModel: TimelineViewModel? = nil
    
    @State private var currentTime = Date()
    @State private var hasConflicts: Bool = false
    @State private var conflictDetails: [TaskConflictService.TaskConflict] = []
    @State private var isPressed: Bool = false
    
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @ObservedObject private var timerService = TaskTimerService.shared
    
    var body: some View {
        let baseHeight: CGFloat = max(80, CGFloat(durationMinutes) * 1.2)
        let progressInfo = calculateProgress()
        
        HStack(alignment: .top, spacing: LiquidDesignSystem.Spacing.md) {
            // Left side - Icon and Progress
            iconSection(progressInfo: progressInfo, baseHeight: baseHeight)
            
            // Right side - Task content
            contentSection(progressInfo: progressInfo)
                .frame(height: baseHeight)
        }
        .padding(LiquidDesignSystem.Spacing.md)
        .background(cardBackground(progressInfo: progressInfo))
        .fluidScale(isPressed: isPressed)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            checkForConflicts()
        }
        .onChange(of: task) { _, _ in
            checkForConflicts()
        }
    }
    
    // MARK: - Icon Section
    
    @ViewBuilder
    private func iconSection(progressInfo: (shouldShow: Bool, percentage: Double, color: Color), baseHeight: CGFloat) -> some View {
        VStack(spacing: LiquidDesignSystem.Spacing.sm) {
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(colorScheme == .dark ? 0.3 : 0.2),
                                color.opacity(colorScheme == .dark ? 0.15 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                // Progress ring
                if progressInfo.shouldShow && !isCompleted {
                    Circle()
                        .trim(from: 0, to: progressInfo.percentage)
                        .stroke(
                            progressInfo.color,
                            style: StrokeStyle(
                                lineWidth: 3,
                                lineCap: .round
                            )
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                        .animation(LiquidDesignSystem.Animation.smooth, value: progressInfo.percentage)
                }
                
                // Completion ring
                if isCompleted {
                    Circle()
                        .stroke(
                            LiquidDesignSystem.Colors.success,
                            style: StrokeStyle(lineWidth: 3)
                        )
                        .frame(width: 56, height: 56)
                }
                
                // Icon or checkmark
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(LiquidDesignSystem.Colors.success)
                } else {
                    Text(icon)
                        .font(.title2)
                }
            }
            
            // Optional connector line for timeline view
            if shouldShowConnector() {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                LiquidDesignSystem.Colors.adaptiveGlassBorder(colorScheme),
                                LiquidDesignSystem.Colors.adaptiveGlassBorder(colorScheme).opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: 40)
            }
        }
    }
    
    // MARK: - Content Section
    
    @ViewBuilder
    private func contentSection(progressInfo: (shouldShow: Bool, percentage: Double, color: Color)) -> some View {
        VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.xs) {
            // Time and status
            HStack {
                Text(formatTimeRange())
                    .font(LiquidDesignSystem.Typography.labelMedium)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextSecondary(colorScheme))
                
                Spacer()
                
                statusBadge(progressInfo: progressInfo)
            }
            
            // Task title
            Text(title)
                .font(LiquidDesignSystem.Typography.titleMedium)
                .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextPrimary(colorScheme))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Duration
            HStack(spacing: LiquidDesignSystem.Spacing.xxs) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextTertiary(colorScheme))
                
                Text(formatDuration())
                    .font(LiquidDesignSystem.Typography.labelSmall)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextTertiary(colorScheme))
            }
            
            // Conflict indicators
            if hasConflicts {
                VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.xxs) {
                    ForEach(conflictDetails) { conflict in
                        TaskConflictIndicator(conflict: conflict)
                    }
                }
                .padding(.top, LiquidDesignSystem.Spacing.xxs)
            }
            
            // Progress text
            if progressInfo.shouldShow && !isCompleted {
                Text(getProgressText())
                    .font(LiquidDesignSystem.Typography.labelSmall)
                    .foregroundColor(progressInfo.color)
                    .padding(.top, LiquidDesignSystem.Spacing.xxs)
            }
        }
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private func cardBackground(progressInfo: (shouldShow: Bool, percentage: Double, color: Color)) -> some View {
        ZStack {
            // Base glass surface
            RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.lg)
                .fill(.ultraThinMaterial)
            
            // Subtle gradient overlay
            RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [
                            LiquidDesignSystem.Colors.adaptiveGlassBackground(colorScheme),
                            LiquidDesignSystem.Colors.adaptiveGlassBackground(colorScheme).opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Accent border for active/completed tasks
            if isCompleted || progressInfo.shouldShow {
                RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.lg)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                isCompleted ? LiquidDesignSystem.Colors.success.opacity(0.5) : color.opacity(0.5),
                                isCompleted ? LiquidDesignSystem.Colors.success.opacity(0.2) : color.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            } else {
                RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.lg)
                    .strokeBorder(
                        LiquidDesignSystem.Colors.adaptiveGlassBorder(colorScheme),
                        lineWidth: 1
                    )
            }
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
            radius: 12,
            x: 0,
            y: 4
        )
    }
    
    // MARK: - Status Badge
    
    @ViewBuilder
    private func statusBadge(progressInfo: (shouldShow: Bool, percentage: Double, color: Color)) -> some View {
        if isCompleted {
            LiquidBadge("Completed", color: LiquidDesignSystem.Colors.success)
        } else if progressInfo.shouldShow {
            let percentage = Int(progressInfo.percentage * 100)
            LiquidBadge("\(percentage)%", color: progressInfo.color)
        }
    }
    
    // MARK: - Helper Methods
    
    private func shouldShowConnector() -> Bool {
        return true // Can be customized based on position in list
    }
    
    private func calculateProgress() -> (shouldShow: Bool, percentage: Double, color: Color) {
        guard let task = task else {
            return (false, 0.0, color)
        }
        
        let now = currentTime
        let taskStartTime = task.startTime
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        if now < taskStartTime {
            return (false, 0.0, color)
        }
        
        if task.isCompleted {
            return (false, 1.0, LiquidDesignSystem.Colors.success)
        }
        
        if now >= taskStartTime && now <= taskEndTime {
            let totalDuration = taskEndTime.timeIntervalSince(taskStartTime)
            let elapsed = now.timeIntervalSince(taskStartTime)
            let progress = min(1.0, elapsed / totalDuration)
            
            let progressColor: Color
            if progress < 0.7 {
                progressColor = LiquidDesignSystem.Colors.success
            } else if progress < 0.9 {
                progressColor = LiquidDesignSystem.Colors.warning
            } else {
                progressColor = LiquidDesignSystem.Colors.error
            }
            
            return (true, progress, progressColor)
        }
        
        if now > taskEndTime {
            return (true, 1.0, LiquidDesignSystem.Colors.error)
        }
        
        return (false, 0.0, color)
    }
    
    private func formatTimeRange() -> String {
        guard let task = task else {
            return time
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let startTime = task.startTime
        let endTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        let startString = formatter.string(from: startTime).lowercased()
        let endString = formatter.string(from: endTime).lowercased()
        
        return "\(startString) - \(endString)"
    }
    
    private func formatDuration() -> String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func getProgressText() -> String {
        guard let task = task else { return "" }
        
        let now = currentTime
        let taskStartTime = task.startTime
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        if now < taskStartTime {
            let timeUntilStart = taskStartTime.timeIntervalSince(now)
            let minutesUntilStart = Int(timeUntilStart / 60)
            if minutesUntilStart > 60 {
                let hours = minutesUntilStart / 60
                let mins = minutesUntilStart % 60
                return "Starts in \(hours)h \(mins)m"
            } else {
                return "Starts in \(minutesUntilStart)m"
            }
        }
        
        if now >= taskStartTime && now <= taskEndTime {
            let remaining = taskEndTime.timeIntervalSince(now)
            let remainingMinutes = Int(remaining / 60)
            
            if remainingMinutes > 60 {
                let hours = remainingMinutes / 60
                let mins = remainingMinutes % 60
                return mins > 0 ? "\(hours)h \(mins)m remaining" : "\(hours)h remaining"
            } else if remainingMinutes > 0 {
                return "\(remainingMinutes)m remaining"
            } else {
                let remainingSeconds = Int(remaining)
                return "\(remainingSeconds)s remaining"
            }
        } else {
            let overdue = now.timeIntervalSince(taskEndTime)
            let overdueMinutes = Int(overdue / 60)
            
            if overdueMinutes > 60 {
                let hours = overdueMinutes / 60
                let mins = overdueMinutes % 60
                return mins > 0 ? "\(hours)h \(mins)m overdue" : "\(hours)h overdue"
            } else {
                return "\(overdueMinutes)m overdue"
            }
        }
    }
    
    private func checkForConflicts() {
        guard let task = task else {
            hasConflicts = false
            conflictDetails = []
            return
        }
        
        if let timelineViewModel = timelineViewModel {
            conflictDetails = timelineViewModel.detectConflicts(for: task)
            hasConflicts = !conflictDetails.isEmpty
        } else {
            hasConflicts = false
            conflictDetails = []
        }
    }
}

