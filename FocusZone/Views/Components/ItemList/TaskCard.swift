import SwiftUI

struct TaskCard: View {
    var title: String
    var time: String
    var icon: String
    var color: Color
    var isCompleted: Bool
    var durationMinutes: Int = 60
    var task: Task? = nil
    var timelineViewModel: TimelineViewModel? = nil
    /// When true, card is inside a conflict group: hide conflict indicator and soften red (less visible).
    var isInConflictGroup: Bool = false
    
    @State private var currentTime = Date()
    @State private var hasConflicts: Bool = false
    @State private var conflictDetails: [TaskConflictService.TaskConflict] = []
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @ObservedObject private var timerService = TaskTimerService.shared

    var body: some View {
        // Calculate height based on duration (1 minute = 2 points, minimum 60pt)
        let baseHeight: CGFloat = max(60, CGFloat(durationMinutes) * 1)
        let progressInfo = calculateProgress()
        // Add minimum progress height to avoid thin line appearance
        let minProgressHeight: CGFloat = 12
        let calculatedProgressHeight = baseHeight * CGFloat(progressInfo.percentage)
        let progressHeight = progressInfo.shouldShow && progressInfo.percentage > 0 ? 
            max(minProgressHeight, calculatedProgressHeight) : calculatedProgressHeight
        
        HStack(alignment: .top, spacing: 0) {
            // Left side - Timeline with progress Capsule
            VStack(spacing: 0) {
                VerticalCapsuleMeter(
                    totalHeight: baseHeight,
                    width: 60,
                    backgroundColor: color.opacity(0.3),
                    baseColor: color,
                    progress: progressInfo.shouldShow && !isCompleted ? progressInfo.percentage : (isCompleted ? 1.0 : 0.0),
                    isCompleted: isCompleted
                ){
                    Text(icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }

                if shouldShowConnector() {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 60)
                        .overlay(
                            Rectangle()
                                .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                .frame(width: 2, height: 20)
                        )
                }
            }
            
            
            // Right side - Task content
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                
                // Time and status
                HStack {
                    Text(formatTimeRange())
                        .font(AppFonts.body())
                        .foregroundColor(.gray)
               
                    Spacer()
                    
                    // Status indicator - Fixed logic
                    statusIndicator(progressInfo: progressInfo)
                }
                
                // Task title
                Text(title)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                
                // Conflict indicators (hidden when card is already inside a conflict group)
                if hasConflicts && !isInConflictGroup {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(conflictDetails) { conflict in
                            TaskConflictIndicator(conflict: conflict)
                        }
                    }
                }
                
                // Progress text for active tasks (softer color when in conflict group)
                if progressInfo.shouldShow && !isCompleted && overdueMinutesFun() / 60 < 12 {
                    Text(getProgressText())
                        .font(AppFonts.caption())
                        .foregroundColor(progressColorTonedDown(progressInfo.color, isSevere: progressInfo.isSevere))
                }
                
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(height: baseHeight)
        }
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
    
    // MARK: - Helper Methods for Progress Display
         
    /// When in conflict group, use orange instead of red for progress/overdue so red is less visible.
    private func progressColorTonedDown(_ color: Color, isSevere: Bool) -> Color {
        guard isInConflictGroup, isSevere else { return color }
        return .orange
    }
    
    @ViewBuilder
    private func statusIndicator(progressInfo: (shouldShow: Bool, percentage: Double, color: Color, isSevere: Bool)) -> some View {
        let effectiveColor = progressColorTonedDown(progressInfo.color, isSevere: progressInfo.isSevere)
        if isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        } else if progressInfo.shouldShow && overdueMinutesFun() / 60 > 12 {
            Circle()
                .stroke(Color.white.opacity(0.55), lineWidth: 3)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .trim(from: 0, to: CGFloat(progressInfo.percentage))
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progressInfo.percentage)
                )
        } else if progressInfo.shouldShow && overdueMinutesFun() / 60 < 12 {
            Circle()
                .stroke(effectiveColor, lineWidth: 3)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .trim(from: 0, to: CGFloat(progressInfo.percentage))
                        .stroke(effectiveColor, lineWidth: 3)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progressInfo.percentage)
                )
        } else {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                .frame(width: 24, height: 24)
        }
    }
    
    // MARK: - Progress Calculation
    /// Returns (shouldShow, percentage, color, isSevere). isSevere is true when color is red (overdue or high progress).
    private func calculateProgress() -> (shouldShow: Bool, percentage: Double, color: Color, isSevere: Bool) {
        guard let task = task else {
            return (false, 0.0, color, false)
        }
        
        let now = currentTime
        let taskStartTime = task.startTime
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        if now < taskStartTime {
            return (false, 0.0, color, false)
        }
        if task.isCompleted {
            return (false, 1.0, .green, false)
        }
        if now >= taskStartTime && now <= taskEndTime {
            let totalDuration = taskEndTime.timeIntervalSince(taskStartTime)
            let elapsed = now.timeIntervalSince(taskStartTime)
            let progress = min(1.0, elapsed / totalDuration)
            let progressColor: Color
            let severe: Bool
            if progress < 0.7 {
                progressColor = .green
                severe = false
            } else if progress < 0.9 {
                progressColor = .orange
                severe = false
            } else {
                progressColor = .red
                severe = true
            }
            return (true, progress, progressColor, severe)
        }
        if now > taskEndTime {
            return (true, 1.0, .red, true)
        }
        return (false, 0.0, color, false)
    }

    private func shouldShowConnector() -> Bool {
        // Show connector for all tasks except maybe the last one
        if isInConflictGroup {
            return false
        }
        return true
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
        
        let duration = formatDuration()
        
        return "\(startString) - \(endString) (\(duration))"
    }
    
    private func formatDuration() -> String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        
        if hours > 0 {
            return minutes > 0 ? String(format: LanguageManager.localized("hrs", comment: "Hours abbreviation"), "\(hours)") + ", " + String(format: LanguageManager.localized("min", comment: "Minutes abbreviation"), "\(minutes)") : String(format: LanguageManager.localized("hrs", comment: "Hours abbreviation"), "\(hours)")
        } else {
            return String(format: LanguageManager.localized("min", comment: "Minutes abbreviation"), "\(minutes)")
        }
    }
    
    private func getProgressText() -> String {
        guard let task = task else { return "" }
        
        let now = currentTime
        let taskStartTime = task.startTime
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        // If task hasn't started yet
        if now < taskStartTime {
            let timeUntilStart = taskStartTime.timeIntervalSince(now)
            let minutesUntilStart = Int(timeUntilStart / 60)
            if minutesUntilStart > 60 {
                let hours = minutesUntilStart / 60
                let mins = minutesUntilStart % 60
                return String(format: LanguageManager.localized("starts_in", comment: "Starts in time format"), "\(hours)h \(mins)m")
            } else {
                return String(format: LanguageManager.localized("starts_in", comment: "Starts in time format"), "\(minutesUntilStart)m")
            }
        }
        
        // If task is currently active
        if now >= taskStartTime && now <= taskEndTime {
            let remaining = taskEndTime.timeIntervalSince(now)
            let remainingMinutes = Int(remaining / 60)
            
            if remainingMinutes > 60 {
                let hours = remainingMinutes / 60
                let mins = remainingMinutes % 60
                return mins > 0 ? String(format: LanguageManager.localized("remaining", comment: "Time remaining format"), "\(hours)h \(mins)m") : String(format: LanguageManager.localized("remaining", comment: "Time remaining format"), "\(hours)h")
            } else if remainingMinutes > 0 {
                return String(format: LanguageManager.localized("remaining", comment: "Time remaining format"), "\(remainingMinutes)m")
            } else {
                // Less than a minute remaining
                let remainingSeconds = Int(remaining)
                return String(format: LanguageManager.localized("remaining", comment: "Time remaining format"), "\(remainingSeconds)s")
            }
        } else {
            // Task is overdue
            let overdue = now.timeIntervalSince(taskEndTime)
            let overdueMinutes = Int(overdue / 60)
            
            if overdueMinutes > 60 {
                let hours = overdueMinutes / 60
                let mins = overdueMinutes % 60
                return mins > 0 ? String(format: LanguageManager.localized("overdue", comment: "Time overdue format"), "\(hours)h \(mins)m") : String(format: LanguageManager.localized("overdue", comment: "Time overdue format"), "\(hours)h")
            } else {
                return String(format: LanguageManager.localized("overdue", comment: "Time overdue format"), "\(overdueMinutes)m")
            }
        }
    }
    
    private func overdueMinutesFun() -> Int {
        guard let task = task else { return 0 }
        
        let now = currentTime
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        // Only calculate overdue if task has passed its end time
        if now > taskEndTime {
            let overdue = now.timeIntervalSince(taskEndTime)
            let overdueMinutes = Int(overdue / 60)
            return max(0, overdueMinutes) // Ensure non-negative
        }
        
        return 0
    }
    
    // MARK: - Conflict Detection
    
    private func checkForConflicts() {
        guard let task = task, !isInConflictGroup else {
            hasConflicts = false
            conflictDetails = []
            return
        }
        
        if let timelineViewModel = getTimelineViewModel() {
            conflictDetails = timelineViewModel.detectConflicts(for: task)
            hasConflicts = !conflictDetails.isEmpty
        } else {
            hasConflicts = false
            conflictDetails = []
        }
    }
    
    private func getTimelineViewModel() -> TimelineViewModel? {
        return timelineViewModel
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Timeline View Container
struct _TimelineView: View {
    @State private var selectedDate = Date()
    @State private var tasks: [Task] = sampleTasks
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Date Header
                WeekDateNavigator(selectedDate: $selectedDate)
            
                // Timeline
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            TaskCard(
                                title: task.title,
                                time: "",
                                icon: task.icon,
                                color: task.color,
                                isCompleted: task.isCompleted,
                                durationMinutes: task.durationMinutes,
                                task: task,
                                timelineViewModel: nil
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 48)
                }
            }
        }
    }
}

// MARK: - Sample Data
let sampleTasks: [Task] = [
    Task(
        id: UUID(),
        title: "Rise and Shine",
        icon: "🌅",
        startTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
        durationMinutes: 145,
        color: .pink,
        isCompleted: true
    ),
    Task(
        id: UUID(),
        title: "Keep working",
        icon: "💼",
        startTime: Calendar.current.date(bySettingHour: 16, minute: 11, second: 0, of: Date()) ?? Date(),
        durationMinutes: 120, // 2h 30min
        color: .green,
        isCompleted: false
    ),
    Task(
        id: UUID(),
        title: "Go for a Run!",
        icon: "🏃‍♂️",
        startTime: Calendar.current.date(bySettingHour: 19, minute: 15, second: 0, of: Date()) ?? Date(),
        durationMinutes: 90, // 1h 30min
        color: .orange,
        isCompleted: false
    ),
    
    Task(
        id: UUID(),
        title: "Go for a Run!",
        icon: "🏃‍♂️",
        startTime: Calendar.current.date(bySettingHour: 19, minute: 35, second: 0, of: Date()) ?? Date(),
        durationMinutes: 60, // 1h 30min
        color: .orange,
        isCompleted: false
    ),
    Task(
        id: UUID(),
        title: "Wind Down",
        icon: "🌙",
        startTime: Calendar.current.date(bySettingHour: 15, minute: 00, second: 0, of: Date()) ?? Date(),
        durationMinutes: 45,
        color: .blue,
        isCompleted: false
    )
]

#Preview {
    _TimelineView()
}
