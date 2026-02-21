import SwiftUI
import SwiftData

struct PreviewTask {
    let title: String
    let color: Color
    let duration: Int
    let icon: String
}

struct TaskFormView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedFocusMode: FocusMode? = nil
    @State private var enableFocusMode: Bool = false
    // Task to edit (nil for new task)
    let taskToEdit: Task?
    /// Pre-filled title when opening from Inbox (convert note to task).
    let initialTitle: String?
    
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
    @StateObject private var taskCreationState = TaskCreationState.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.modelContext) private var modelContext
    private let notificationService = NotificationService.shared
    
    init(taskToEdit: Task? = nil, initialTitle: String? = nil) {
        self.taskToEdit = taskToEdit
        self.initialTitle = initialTitle
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TaskFormHeader(onDismiss: { 
                        // Ensure dismiss is called on main thread
                        DispatchQueue.main.async {
                            dismiss()
                        }
                    })
                    
                    VStack(alignment: .leading, spacing: 40) {
                        
                        TaskTitleInput(
                            taskTitle: $taskTitle,
                            selectedColor: $selectedColor,
                            duration: $duration
                        )
                        
                        if taskTitle != "" {
                            TaskTimeSelector(
                                selectedDate: $selectedDate,
                                startTime: $startTime
                            )
                            
                            TaskDurationSelector(duration: $duration)
                            
                            TaskIconPicker(selectedIcon: $selectedIcon)
                            
                            FocusModeFormSection(
                                               isEnabled: $enableFocusMode,
                                               selectedMode: $selectedFocusMode,
                                               taskType: selectedTaskType
                                           )
                            
                            TaskColorPicker(selectedColor: $selectedColor)
                            
                            TaskRepeatSelector(repeatRule: $repeatRule)
                            
                            // Create/Update Task Button
                            Button(action: {
                                saveTask()
                            }) {
                                Text(taskToEdit == nil ? NSLocalizedString("create_task", comment: "Create task button title") : NSLocalizedString("update_task", comment: "Update task button title"))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(selectedColor)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(taskTitle.isEmpty)
                            
                            // Notification Info Section
                            NotificationInfoSection()
                            
//                          TaskAlertsSection(alerts: $alerts)
                            
                            TaskDetailsSection(
                                showSubtasks: $showSubtasks,
                                notes: $notes
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(AppColors.background.ignoresSafeArea())
        }
        .navigationBarHidden(true)
        .gesture(
            // Add swipe down gesture to dismiss
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 {
                        // Swipe down detected, dismiss the form
                        DispatchQueue.main.async {
                            dismiss()
                        }
                    }
                }
        )
        .onAppear {
            loadTaskData()
            if taskToEdit == nil, let title = initialTitle, !title.isEmpty {
                taskTitle = title
            }
            // Prefill next start time if available (for new tasks only)
            if taskToEdit == nil, let suggested = taskCreationState.nextSuggestedStartTime {
                let cal = Calendar.current
                // If suggested is the same day as the current selected date, keep the date and prefill the time.
                // Otherwise, move both date and time to the suggested day.
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
    }
    
    private func saveTask() {
        // Validate required fields
        guard !taskTitle.isEmpty else {
            print("TaskFormView: Error - Task title is empty")
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
            print("TaskFormView: Error creating final start time")
            return
        }
        
        print("TaskFormView: Final start time: \(finalStartTime)")
        
        if let taskToEdit = taskToEdit {
            // Update existing task
            print("TaskFormView: Updating existing task")
            
            // Cancel old notifications first
            notificationService.cancelNotifications(for: taskToEdit.id.uuidString)
            
            taskToEdit.title = taskTitle
            taskToEdit.icon = selectedIcon
            taskToEdit.startTime = finalStartTime
            taskToEdit.durationMinutes = duration
            taskToEdit.color = selectedColor
            taskToEdit.taskType = selectedTaskType
            taskToEdit.repeatRule = repeatRule
            taskToEdit.updatedAt = Date()
            taskToEdit.isCompleted = false
            
            print("TaskFormView: Task updated in memory")
            
            do {
                try modelContext.save()
                print("TaskFormView: Task updated successfully in database")
                
                // Schedule new notifications for updated task
                notificationService.scheduleTaskReminders(for: taskToEdit)
                print("TaskFormView: Rescheduled notifications for updated task")
                
            } catch {
                print("TaskFormView: Error updating task: \(error)")
                print("TaskFormView: Error details: \(error.localizedDescription)")
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
                        print("TaskFormView: Task limit reached, cannot create new task")
                        // Show error or dismiss form
                        DispatchQueue.main.async {
                            dismiss()
                        }
                        return
                    }
                } catch {
                    print("TaskFormView: Error checking task count: \(error)")
                }
            }
            
            // Create new task
            print("TaskFormView: Creating new task")
            
            let newTask = Task(
                title: taskTitle,
                icon: selectedIcon,
                startTime: finalStartTime,
                durationMinutes: duration,
                color: selectedColor,
                taskType: selectedTaskType,
                repeatRule: repeatRule
            )
            
            print("TaskFormView: New task created with ID: \(newTask.id)")
            print("TaskFormView: New task title: \(newTask.title)")
            print("TaskFormView: New task start time: \(newTask.startTime)")
            
            modelContext.insert(newTask)
            print("TaskFormView: Task inserted into ModelContext")
            
            do {
                try modelContext.save()
                print(">>>>>>> TaskFormView: Task created successfully and saved to database")
                print("TaskFormView: Saved task ID: \(newTask.id)")
                
                // Verify the task was actually saved by trying to fetch it
                let descriptor = FetchDescriptor<Task>()
                let allTasks = try modelContext.fetch(descriptor)
                let savedTasks = allTasks.filter { $0.id == newTask.id }
                print("TaskFormView: Verification - Found \(savedTasks.count) tasks with ID \(newTask.id)")
                
                // Schedule notifications for new task
                notificationService.scheduleTaskReminders(for: newTask)
                print("TaskFormView: Scheduled notifications for new task")

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
                print(">>>>>TaskFormView: Error creating task: \(error)")
                print("TaskFormView: Error details: \(error.localizedDescription)")
            }
        }
        
        print("TaskFormView: Dismissing form")
        // Ensure dismiss is called on main thread
        DispatchQueue.main.async {
            dismiss()
        }
    }
}

#Preview {
    TaskFormView()
        .environmentObject(NotificationService.shared)
}
