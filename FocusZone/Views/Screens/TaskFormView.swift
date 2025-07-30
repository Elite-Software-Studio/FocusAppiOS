import SwiftUI

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
    
    @State private var taskTitle: String = ""
    @State private var selectedDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var duration: Int = 15
    @State private var selectedColor: Color = .pink
    @State private var selectedTaskType: TaskType? = nil
    @State private var selectedIcon: String = "📝"
    @State private var repeatRule: RepeatRule = .once
    @State private var alerts: [String] = ["At start of task"]
    @State private var showSubtasks: Bool = false
    @State private var notes: String = ""
    @State private var showingTimeSlots: Bool = false
    @State private var showingPreviewTasks: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    private let notificationService = NotificationService.shared
    
    init(taskToEdit: Task? = nil) {
        self.taskToEdit = taskToEdit
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TaskFormHeader(onDismiss: { dismiss() })
                    
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
                                Text(taskToEdit == nil ? "Create Task" : "Update Task")
                                    .font(AppFonts.headline())
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
                            
                            TaskAlertsSection(alerts: $alerts)
                            
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
        .onAppear {
            loadTaskData()
        }
    }
    
    // MARK: - Notification Info Section
    
    
    
    // MARK: - Methods
    
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
            return
        }
        
        if let taskToEdit = taskToEdit {
            // Update existing task
            
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
            
            do {
                try modelContext.save()
                print("TaskFormView: Task updated successfully")
                
                // Schedule new notifications for updated task
                notificationService.scheduleTaskReminders(for: taskToEdit)
                print("TaskFormView: Rescheduled notifications for updated task")
                
            } catch {
                print("TaskFormView: Error updating task: \(error)")
            }
        } else {
            // Create new task
            let newTask = Task(
                title: taskTitle,
                icon: selectedIcon,
                startTime: finalStartTime,
                durationMinutes: duration,
                color: selectedColor,
                taskType: selectedTaskType,
                repeatRule: repeatRule
            )
            
            modelContext.insert(newTask)
            
            do {
                try modelContext.save()
                print("TaskFormView: Task created successfully")
                
                // Schedule notifications for new task
                notificationService.scheduleTaskReminders(for: newTask)
                print("TaskFormView: Scheduled notifications for new task")
                
                // Show confirmation if notifications are enabled
                if notificationService.isAuthorized {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "h:mm a 'on' MMM d"
                    let timeString = formatter.string(from: finalStartTime)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        notificationService.sendImmediateNotification(
                            title: "✅ Task Created",
                            body: "'\(taskTitle)' scheduled for \(timeString)"
                        )
                    }
                }
                
            } catch {
                print("TaskFormView: Error creating task: \(error)")
            }
        }
        
        dismiss()
    }
}

#Preview {
    TaskFormView()
        .environmentObject(NotificationService.shared)
}
