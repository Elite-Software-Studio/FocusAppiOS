import SwiftUI
import SwiftData

struct LiquidTaskFormView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedFocusMode: FocusMode? = nil
    @State private var enableFocusMode: Bool = false
    
    // Task to edit (nil for new task)
    let taskToEdit: Task?
    
    // Form state
    @State private var taskTitle: String = ""
    @State private var selectedDate: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var startTime: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var duration: Int = 15
    @State private var selectedColor: Color = .pink
    @State private var selectedTaskType: TaskType? = nil
    @State private var selectedIcon: String = "📝"
    @State private var repeatRule: RepeatRule = .none
    @State private var alerts: [String] = [NSLocalizedString("at_start_of_task", comment: "Alert at start of task")]
    @State private var showSubtasks: Bool = true
    @State private var notes: String = ""
    @State private var showingTimeSlots: Bool = false
    @State private var showingPreviewTasks: Bool = false
    @State private var alarmEnabled: Bool = false
    
    @StateObject private var taskCreationState = TaskCreationState.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var alarmService = AlarmService.shared
    
    private let notificationService = NotificationService.shared
    
    init(taskToEdit: Task? = nil) {
        self.taskToEdit = taskToEdit
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Mesh gradient background
                LiquidDesignSystem.Colors.meshGradientBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        LiquidTaskFormHeader(onDismiss: {
                            DispatchQueue.main.async {
                                dismiss()
                            }
                        })
                        
                        // Form content
                        VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.xl) {
                            // Title input
                            LiquidTaskTitleInput(
                                taskTitle: $taskTitle,
                                selectedColor: $selectedColor,
                                duration: $duration
                            )
                            
                            // Show remaining fields only when title is not empty
                            if taskTitle != "" {
                                // Time selector
                                LiquidTaskTimeSelector(
                                    selectedDate: $selectedDate,
                                    startTime: $startTime
                                )
                                
                                // Duration selector
                                LiquidTaskDurationSelector(duration: $duration)
                                
                                // Icon picker
                                LiquidTaskIconPicker(selectedIcon: $selectedIcon)
                                
                                // Focus Mode section (reuse existing, wrapped in glass)
                                VStack(spacing: 0) {
                                    FocusModeFormSection(
                                        isEnabled: $enableFocusMode,
                                        selectedMode: $selectedFocusMode,
                                        taskType: selectedTaskType
                                    )
                                    .padding(LiquidDesignSystem.Spacing.lg)
                                }
                                .glassSurface()
                                
                                // Color picker
                                LiquidTaskColorPicker(selectedColor: $selectedColor)
                                
                                // Repeat selector
                                LiquidTaskRepeatSelector(repeatRule: $repeatRule)
                                
                                // Alarm toggle (wrapped in glass)
                                VStack(spacing: 0) {
                                    AlarmToggleSection(
                                        alarmEnabled: $alarmEnabled,
                                        alarmService: alarmService
                                    )
                                    .padding(LiquidDesignSystem.Spacing.lg)
                                }
                                .glassSurface()
                                
                                // Create/Update button
                                Button(action: {
                                    saveTask()
                                }) {
                                    Text(
                                        taskToEdit == nil
                                            ? NSLocalizedString("create_task", comment: "Create task button title")
                                            : NSLocalizedString("update_task", comment: "Update task button title")
                                    )
                                    .font(LiquidDesignSystem.Typography.headlineFont)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, LiquidDesignSystem.Spacing.lg)
                                    .background(
                                        RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.xl)
                                            .fill(
                                                LinearGradient(
                                                    colors: [selectedColor.opacity(0.9), selectedColor],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .shadow(
                                        color: selectedColor.opacity(0.4),
                                        radius: 12,
                                        x: 0,
                                        y: 6
                                    )
                                }
                                .buttonStyle(LiquidButtonStyle(variant: .primary))
                                .disabled(taskTitle.isEmpty)
                                
                                // Notification info (wrapped in glass)
                                VStack(spacing: 0) {
                                    NotificationInfoSection()
                                        .padding(LiquidDesignSystem.Spacing.lg)
                                }
                                .glassSurface()
                                
                                // Task details (notes)
                                VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.md) {
                                    Text("Any details?")
                                        .font(LiquidDesignSystem.Typography.headlineFont)
                                        .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                                    
                                    TextField(
                                        "Add notes, meeting links or phone numbers...",
                                        text: $notes,
                                        axis: .vertical
                                    )
                                    .font(LiquidDesignSystem.Typography.bodyFont)
                                    .foregroundStyle(LiquidDesignSystem.Colors.textPrimary)
                                    .padding(LiquidDesignSystem.Spacing.lg)
                                    .glassSurface()
                                    .lineLimit(4...8)
                                }
                            }
                        }
                        .padding(.horizontal, LiquidDesignSystem.Spacing.lg)
                        .padding(.bottom, LiquidDesignSystem.Spacing.xxl)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .gesture(
            // Swipe down to dismiss
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 {
                        DispatchQueue.main.async {
                            dismiss()
                        }
                    }
                }
        )
        .onAppear {
            loadTaskData()
            
            // Prefill next start time if available (for new tasks only)
            if taskToEdit == nil, let suggested = taskCreationState.nextSuggestedStartTime {
                let cal = Calendar.current
                if cal.isDate(suggested, inSameDayAs: selectedDate) {
                    let dateComponents = cal.dateComponents([.year, .month, .day], from: selectedDate)
                    let timeComponents = cal.dateComponents([.hour, .minute], from: suggested)
                    if let combined = cal.date(from: DateComponents(
                        year: dateComponents.year,
                        month: dateComponents.month,
                        day: dateComponents.day,
                        hour: timeComponents.hour,
                        minute: timeComponents.minute
                    )) {
                        startTime = combined
                    }
                } else {
                    selectedDate = suggested
                    startTime = suggested
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadTaskData() {
        guard let task = taskToEdit else { return }
        
        taskTitle = task.title
        selectedDate = task.startTime
        startTime = task.startTime
        duration = task.durationMinutes
        selectedColor = task.color
        selectedTaskType = task.taskType
        selectedIcon = task.icon
        repeatRule = task.repeatRule
        alarmEnabled = task.alarmEnabled
    }
    
    private func saveTask() {
        // Validate required fields
        guard !taskTitle.isEmpty else {
            print("LiquidTaskFormView: Error - Task title is empty")
            return
        }
        
        // Combine selectedDate and startTime
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        
        guard let finalStartTime = calendar.date(from: DateComponents(
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute
        )) else {
            print("LiquidTaskFormView: Error creating final start time")
            return
        }
        
        print("LiquidTaskFormView: Final start time: \(finalStartTime)")
        
        if let taskToEdit = taskToEdit {
            // Update existing task
            print("LiquidTaskFormView: Updating existing task")
            
            // Cancel old notifications first
            notificationService.cancelNotifications(for: taskToEdit.id.uuidString)
            
            taskToEdit.title = taskTitle
            taskToEdit.icon = selectedIcon
            taskToEdit.startTime = finalStartTime
            taskToEdit.durationMinutes = duration
            taskToEdit.color = selectedColor
            taskToEdit.taskType = selectedTaskType
            taskToEdit.repeatRule = repeatRule
            taskToEdit.alarmEnabled = alarmEnabled
            taskToEdit.updatedAt = Date()
            taskToEdit.isCompleted = false
            
            print("LiquidTaskFormView: Task updated in memory")
            
            do {
                try modelContext.save()
                print("LiquidTaskFormView: Task updated successfully in database")
                
                // Schedule new notifications for updated task
                notificationService.scheduleTaskReminders(for: taskToEdit)
                print("LiquidTaskFormView: Rescheduled notifications for updated task")
                
                // Schedule alarm if enabled
                if alarmEnabled {
                    _Concurrency.Task {
                        await alarmService.scheduleAlarm(for: taskToEdit)
                    }
                } else {
                    _Concurrency.Task {
                        await alarmService.cancelAlarm(for: taskToEdit)
                    }
                }
                
            } catch {
                print("LiquidTaskFormView: Error updating task: \(error)")
                print("LiquidTaskFormView: Error details: \(error.localizedDescription)")
            }
        } else {
            // Check task limit for new tasks
            if !subscriptionManager.isProUser {
                let descriptor = FetchDescriptor<Task>(
                    predicate: #Predicate<Task> { task in
                        task.statusRawValue != "cancelled"
                    }
                )
                
                do {
                    let allTasks = try modelContext.fetch(descriptor)
                    if allTasks.count >= ProFeatures.maxTasksForFree {
                        print("LiquidTaskFormView: Task limit reached, cannot create new task")
                        DispatchQueue.main.async {
                            dismiss()
                        }
                        return
                    }
                } catch {
                    print("LiquidTaskFormView: Error checking task count: \(error)")
                }
            }
            
            // Create new task
            print("LiquidTaskFormView: Creating new task")
            
            let newTask = Task(
                title: taskTitle,
                icon: selectedIcon,
                startTime: finalStartTime,
                durationMinutes: duration,
                color: selectedColor,
                taskType: selectedTaskType,
                repeatRule: repeatRule,
                alarmEnabled: alarmEnabled
            )
            
            print("LiquidTaskFormView: New task created with ID: \(newTask.id)")
            print("LiquidTaskFormView: New task title: \(newTask.title)")
            print("LiquidTaskFormView: New task start time: \(newTask.startTime)")
            
            modelContext.insert(newTask)
            print("LiquidTaskFormView: Task inserted into ModelContext")
            
            do {
                try modelContext.save()
                print(">>>>>>> LiquidTaskFormView: Task created successfully and saved to database")
                print("LiquidTaskFormView: Saved task ID: \(newTask.id)")
                
                // Verify the task was actually saved
                let descriptor = FetchDescriptor<Task>()
                let allTasks = try modelContext.fetch(descriptor)
                let savedTasks = allTasks.filter { $0.id == newTask.id }
                print("LiquidTaskFormView: Verification - Found \(savedTasks.count) tasks with ID \(newTask.id)")
                
                // Schedule notifications for new task
                notificationService.scheduleTaskReminders(for: newTask)
                print("LiquidTaskFormView: Scheduled notifications for new task")
                
                // Schedule alarm if enabled
                if alarmEnabled {
                    _Concurrency.Task {
                        await alarmService.scheduleAlarm(for: newTask)
                    }
                }
                
                // Prepare suggested next start time = end of this task
                let next = finalStartTime.addingTimeInterval(TimeInterval(duration * 60))
                taskCreationState.nextSuggestedStartTime = next
                
                // Show confirmation if notifications are enabled
                if notificationService.isAuthorized {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "h:mm a 'on' MMM d"
                    let timeString = formatter.string(from: finalStartTime)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        notificationService.sendImmediateNotification(
                            title: NSLocalizedString("task_created", comment: "Task created notification title"),
                            body: String(format: NSLocalizedString("task_scheduled_for", comment: "Task scheduled notification message"), taskTitle, timeString)
                        )
                    }
                }
                
            } catch {
                print(">>>>>LiquidTaskFormView: Error creating task: \(error)")
                print("LiquidTaskFormView: Error details: \(error.localizedDescription)")
            }
        }
        
        print("LiquidTaskFormView: Dismissing form")
        DispatchQueue.main.async {
            dismiss()
        }
    }
}

#Preview {
    LiquidTaskFormView()
        .environmentObject(NotificationService.shared)
}

