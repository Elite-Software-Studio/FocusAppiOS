import Foundation
import SwiftUI
import SwiftData
import WidgetKit  // Add this import

// MARK: - Conflict Group (overlapping tasks)
struct ConflictGroup: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let tasks: [Task]
}

/// A single timeline row: either one task or a conflict group.
enum TimelineItem: Identifiable {
    case task(Task)
    case conflictGroup(ConflictGroup)
    
    var id: AnyHashable {
        switch self {
        case .task(let t): return AnyHashable(t.id)
        case .conflictGroup(let g): return AnyHashable(g.id)
        }
    }
}

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var breakSuggestions: [BreakSuggestion] = []
    private let breakAnalyzer = SmartBreakAnalyzer()
    private let conflictService = TaskConflictService()
    
    private var modelContext: ModelContext?
    private let notificationService = NotificationService.shared

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func loadTodayTasks(for date: Date = Date()) {
        
        print("TimelineViewModel: Loading tasks for \(dateString(date))")
        print("Rendering \(breakSuggestions.count) breakSuggestions")

        guard let modelContext = modelContext else {
            print("TimelineViewModel: No modelContext available")
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                // Exclude cancelled tasks (deleted instances)
                task.statusRawValue != "cancelled"
            },
            sortBy: [SortDescriptor(\.startTime)]
        )

        do {
            let allTasks = try modelContext.fetch(descriptor)
            print("TimelineViewModel: Fetched \(allTasks.count) total tasks from database")
            
            // Debug: Print all tasks
            for (index, task) in allTasks.enumerated() {
                print("TimelineViewModel: Task \(index): \(task.title) - \(task.startTime) - \(task.durationMinutes)m")
            }
            
            var todayTasks: [Task] = []

            // First, get all actual tasks for this specific date
            let actualTasks = allTasks.filter { task in
                task.startTime >= startOfDay &&
                task.startTime < endOfDay &&
                !task.isGeneratedFromRepeat
            }
            todayTasks.append(contentsOf: actualTasks)

            // Then, generate virtual tasks from repeating tasks
            let repeatingTasks = allTasks.filter { task in
                task.repeatRuleRawValue != "none" &&
                task.repeatRuleRawValue != "once" &&
                !task.isGeneratedFromRepeat
            }

            for repeatingTask in repeatingTasks {
                if shouldIncludeRepeatingTask(task: repeatingTask, for: date) {
                    // Check if we already have a real task for this date/time/title
                    let taskExists = todayTasks.contains { existing in
                        calendar.isDate(existing.startTime, inSameDayAs: date) &&
                        existing.title == repeatingTask.title &&
                        calendar.component(.hour, from: existing.startTime) == calendar.component(.hour, from: repeatingTask.startTime) &&
                        calendar.component(.minute, from: existing.startTime) == calendar.component(.minute, from: repeatingTask.startTime)
                    }

                    if !taskExists {
                        if let virtualTask = createVirtualTask(from: repeatingTask, for: date) {
                            todayTasks.append(virtualTask)
                        }
                    }
                }
            }

            // Sort by start time and update the published property
            tasks = todayTasks.sorted { $0.startTime < $1.startTime }

            print("TimelineViewModel: Loaded \(tasks.count) tasks for \(dateString(date))")
            print("  - Actual tasks: \(actualTasks.count)")
            print("  - Virtual tasks: \(todayTasks.count - actualTasks.count)")
            
        } catch {
            print("TimelineViewModel: Error loading tasks: \(error)")
            tasks = []
        }
        updateWidgetData()
        updateBreakSuggestions()
    }
    
    private func shouldIncludeRepeatingTask(task: Task, for date: Date) -> Bool {
        let calendar = Calendar.current
        let taskStartDate = calendar.startOfDay(for: task.startTime)
        let targetDate = calendar.startOfDay(for: date)
        
        // Don't include if the target date is before the task's start date
        guard targetDate >= taskStartDate else { return false }
        
        // Don't include the original date (that's handled by actual task)
        guard !calendar.isDate(targetDate, inSameDayAs: taskStartDate) else { return false }
        
        switch task.repeatRuleRawValue {
        case "none":
            return false
            
        case "daily":
            return true // Every day after the start date
            
        case "weekdays":
            let weekday = calendar.component(.weekday, from: date)
            return weekday >= 2 && weekday <= 6 // Monday=2, Friday=6
            
        case "weekends":
            let weekday = calendar.component(.weekday, from: date)
            return weekday == 1 || weekday == 7 // Sunday=1, Saturday=7
            
        case "weekly":
            let taskWeekday = calendar.component(.weekday, from: task.startTime)
            let dateWeekday = calendar.component(.weekday, from: date)
            return dateWeekday == taskWeekday
            
        case "monthly":
            let taskDay = calendar.component(.day, from: task.startTime)
            let dateDay = calendar.component(.day, from: date)
            return dateDay == taskDay
            
        case "once":
            return false
            
        default:
            return false
        }
    }
    
    private func createVirtualTask(from originalTask: Task, for date: Date) -> Task? {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: originalTask.startTime)
        
        let newStartTime = calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: timeComponents.second ?? 0,
            of: date
        ) ?? date
        
        // Check if there's already a deleted instance for this date/time
        if hasDeletedInstance(for: originalTask, on: date) {
            // Don't create virtual task if user previously deleted it
            return nil
        }
        
        let virtualTask = Task(
            id: UUID(), // New unique ID for virtual task
            title: originalTask.title,
            icon: originalTask.icon,
            startTime: newStartTime,
            durationMinutes: originalTask.durationMinutes,
            color: originalTask.color,
            isCompleted: false, // Virtual tasks start as incomplete
            taskType: originalTask.taskType,
            status: .scheduled,
            repeatRule: .none, // Virtual tasks don't repeat themselves
            isGeneratedFromRepeat: true,
            parentTaskId: originalTask.id, // Reference to parent
            parentTask: originalTask // SwiftData relationship
        )
        
        return virtualTask
    }
    
    private func hasDeletedInstance(for originalTask: Task, on date: Date) -> Bool {
        guard let modelContext = modelContext else { return false }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let parentId = originalTask.id
        
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.parentTaskId == parentId &&
                task.statusRawValue == "cancelled" &&
                task.startTime >= startOfDay &&
                task.startTime < endOfDay
            }
        )
        
        do {
            let deletedInstances = try modelContext.fetch(descriptor)
            return !deletedInstances.isEmpty
        } catch {
            print("Error checking for deleted instances: \(error)")
            return false
        }
    }
    
    /// Returns timeline rows: single tasks or conflict groups, in chronological order.
    func timelineItems() -> [TimelineItem] {
        detectConflictGroups(tasks: tasks)
    }
    
    /// Detects overlapping tasks and groups them. Returns a flat list of single tasks and conflict groups in order.
    func detectConflictGroups(tasks: [Task]) -> [TimelineItem] {
        let sorted = tasks.sorted { $0.startTime < $1.startTime }
        var result: [TimelineItem] = []
        var currentGroup: [Task] = []
        var groupEnd: Date?
        
        for task in sorted {
            let taskEnd = task.estimatedEndTime
            if let end = groupEnd, task.startTime < end {
                currentGroup.append(task)
                groupEnd = max(end, taskEnd)
            } else {
                if currentGroup.count > 1 {
                    let start = currentGroup.map(\.startTime).min()!
                    let end = currentGroup.map(\.estimatedEndTime).max()!
                    result.append(.conflictGroup(ConflictGroup(start: start, end: end, tasks: currentGroup.sorted { $0.startTime < $1.startTime })))
                } else if let single = currentGroup.first {
                    result.append(.task(single))
                }
                currentGroup = [task]
                groupEnd = taskEnd
            }
        }
        if currentGroup.count > 1 {
            let start = currentGroup.map(\.startTime).min()!
            let end = currentGroup.map(\.estimatedEndTime).max()!
            result.append(.conflictGroup(ConflictGroup(start: start, end: end, tasks: currentGroup.sorted { $0.startTime < $1.startTime })))
        } else if let single = currentGroup.first {
            result.append(.task(single))
        }
        
        return result
    }
    
    private func itemStart(_ item: TimelineItem) -> Date {
        switch item {
        case .task(let t): return t.startTime
        case .conflictGroup(let g): return g.start
        }
    }
    
    func timeRange(for task: Task) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let endTime = task.startTime.addingTimeInterval(Double(task.durationMinutes) * 60)
        return "\(formatter.string(from: task.startTime)) - \(formatter.string(from: endTime))"
    }
    
    func taskColor(_ task: Task) -> Color {
        return task.color
    }
    
    func timeSpentOnTask(for task: Task) -> Double {
        let isTaskStarted = !task.isCompleted
        return isTaskStarted ? Date().timeIntervalSince(task.startTime) : 0
    }
    
    func scrollToNow() {
        print("Scroll to current time")
    }
    
    // MARK: - Task Management Actions
    
    func deleteTask(_ task: Task) {
        // Cancel notifications for this task
        notificationService.cancelNotifications(for: task.id.uuidString)
        
        // Handle different deletion scenarios
        if task.isGeneratedFromRepeat {
            // Virtual task - just remove from local array and create a "deleted instance" record
            handleVirtualTaskDeletion(task)
        } else if task.isParentTask {
            // Parent task with children - ask user what to do
            handleParentTaskDeletion(task)
        } else if task.isChildTask {
            // Child task - delete only this instance
            handleChildTaskDeletion(task)
        } else {
            // Regular task - simple deletion
            handleRegularTaskDeletion(task)
        }
        
        saveContext()
        refreshTasks()
        updateWidgetData() // Add this line

    }

    private func handleVirtualTaskDeletion(_ task: Task) {
        guard let modelContext = modelContext else { return }
        
        // Remove from local array
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
        }
        
        // Create a "deleted instance" record to prevent this virtual task from appearing again
        // This approach is better than modifying the parent task
        let deletedInstance = Task(
            id: UUID(), // New unique ID for virtual task
            title: task.title,
            icon: task.icon,
            startTime: task.startTime,
            durationMinutes: task.durationMinutes,
            color: task.color,
            isCompleted: false,
            taskType: task.taskType,
            status: .cancelled, // Mark as cancelled to indicate deletion
            repeatRule: .none,
            isGeneratedFromRepeat: true,
            parentTaskId: task.parentTaskId
        )
        
        modelContext.insert(deletedInstance)
        print("TimelineViewModel: Created deleted instance record for virtual task")
    }

    private func handleParentTaskDeletion(_ task: Task) {
        guard let modelContext = modelContext else { return }
        
        // For now, we'll delete the parent and all children
        // In a more advanced implementation, you might want to show an alert asking the user
        
        // Delete all children first
        for child in task.children ?? [] {
            notificationService.cancelNotifications(for: child.id.uuidString)
            modelContext.delete(child)
        }
        
        // Delete the parent task
        modelContext.delete(task)
        print("TimelineViewModel: Deleted parent task and \(task.children?.count ?? 0) children")
    }

    private func handleChildTaskDeletion(_ task: Task) {
        guard let modelContext = modelContext else { return }
        
        // Remove from parent's children array (SwiftData handles this automatically with relationships)
        modelContext.delete(task)
        print("TimelineViewModel: Deleted child task instance")
    }

    private func handleRegularTaskDeletion(_ task: Task) {
        guard let modelContext = modelContext else { return }
        
        // Simple deletion for regular tasks
        modelContext.delete(task)
        print("TimelineViewModel: Deleted regular task")
    }

    // MARK: - Advanced Deletion Options

    func deleteTaskInstance(_ task: Task) {
        // Delete only this specific instance (for repeating tasks)
        if task.isGeneratedFromRepeat {
            handleVirtualTaskDeletion(task)
        } else {
            handleChildTaskDeletion(task)
        }
        saveContext()
        refreshTasks()
    }

    func deleteAllTaskInstances(_ task: Task) {
        // Delete all instances of a repeating task
        let rootTask = task.rootParent
        handleParentTaskDeletion(rootTask)
        saveContext()
        refreshTasks()
    }

    func deleteFutureTaskInstances(_ task: Task, fromDate: Date = Date()) {
        guard let modelContext = modelContext else { return }
        
        let rootTask = task.rootParent
        
        // Delete all children that start after the specified date
        let futureChildren = (rootTask.children ?? []).filter { $0.startTime >= fromDate }
        for child in futureChildren {
            notificationService.cancelNotifications(for: child.id.uuidString)
            modelContext.delete(child)
        }
        
        // Also prevent future virtual tasks by modifying the repeat rule
        // (You might want to add an "endDate" property to Task for this)
        
        saveContext()
        refreshTasks()
        print("TimelineViewModel: Deleted \(futureChildren.count) future instances")
    }
    
    func duplicateTask(_ task: Task) {
        guard let modelContext = modelContext else { return }
        
        // Get the root task to duplicate (in case we're duplicating a child)
        let taskToDuplicate = task.isChildTask ? task.rootParent : task
        
        let duplicatedTask = Task(
            title: "\(taskToDuplicate.title) (Copy)",
            icon: taskToDuplicate.icon,
            startTime: taskToDuplicate.startTime.addingTimeInterval(3600), // +1 hour
            durationMinutes: taskToDuplicate.durationMinutes,
            color: taskToDuplicate.color,
            taskType: taskToDuplicate.taskType,
            repeatRule: taskToDuplicate.repeatRule,
            isGeneratedFromRepeat: false // Duplicated tasks are real tasks
        )
        
        modelContext.insert(duplicatedTask)
        notificationService.scheduleTaskReminders(for: duplicatedTask)

        saveContext()
        refreshTasks()
    }
    
    func completeTask(_ task: Task) {
        notificationService.cancelNotifications(for: task.id.uuidString)

        // If it's a virtual task, convert it to a real completed task
        if task.isGeneratedFromRepeat {
            guard let modelContext = modelContext else { return }
            
            let realTask = Task(
                id: task.id, // Keep the same ID
                title: task.title,
                icon: task.icon,
                startTime: task.startTime,
                durationMinutes: task.durationMinutes,
                color: task.color,
                isCompleted: true,
                taskType: task.taskType,
                status: .completed,
                repeatRule: .none, // Completed instances don't repeat
                isGeneratedFromRepeat: false, // Now it's a real task
                parentTaskId: task.parentTaskId,
                parentTask: task.parentTask
            )
            
            modelContext.insert(realTask)
            
            // Add to parent's children if parent exists
            if let parentTask = task.parentTask {
                if parentTask.children == nil { parentTask.children = [] }
                parentTask.children?.append(realTask)
            }
            
            saveContext()
            notificationService.sendTaskCompletionNotification(for: realTask, actualDuration: realTask.durationMinutes)

        } else {
            // For real tasks, just update the completion status
            task.isCompleted = true
            task.status = .completed
            task.updatedAt = Date()
            saveContext()
            
            // Send completion notification
            notificationService.sendTaskCompletionNotification(for: task, actualDuration: task.durationMinutes)
        }
        
        refreshTasks()
        updateWidgetData() // Add this line

    }
    
    func addTask(_ task: Task) {
        print("TimelineViewModel: Adding task - \(task.title)")
        guard let modelContext = modelContext else { return }
        modelContext.insert(task)
        saveContext()
        // Schedule notifications for the new task
        notificationService.scheduleTaskReminders(for: task)
        refreshTasks()
        updateWidgetData() // Add this line

    }
    
    func updateTask(_ task: Task) {
        task.updatedAt = Date()
        saveContext()
        // Reschedule notifications for the updated task
        notificationService.cancelNotifications(for: task.id.uuidString)
        notificationService.scheduleTaskReminders(for: task)
        refreshTasks()
        updateWidgetData() // Add this line

    }
    
    func refreshTasks() {
        // Reload tasks for the currently selected date
        // Note: You might want to pass the current date from the view
        loadTodayTasks(for: Date())
    }
    
    func refreshTasks(for date: Date) {
        print("TimelineViewModel: Explicitly refreshing tasks for \(dateString(date))")
        loadTodayTasks(for: date)
    }
    
    func forceRefreshTasks(for date: Date) {
        print("TimelineViewModel: Force refreshing tasks for \(dateString(date))")
        // Clear current tasks first
        tasks = []
        // Then reload
        loadTodayTasks(for: date)
    }
    
    // MARK: - Notification Helpers
    private func scheduleDailyPlanningReminder() {
        // Schedule daily planning reminder for 8:00 AM
        let calendar = Calendar.current
        guard let planningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) else { return }
        
        let taskCount = tasks.count
        notificationService.scheduleDailyPlanningReminder(at: planningTime, taskCount: taskCount)
    }
    
    func requestNotificationPermission() async {
        let granted = await notificationService.requestAuthorization()
        if granted {
            print("TimelineViewModel: Notification permission granted")
            // Reschedule notifications for existing tasks
            for task in tasks where !task.isGeneratedFromRepeat {
                notificationService.scheduleTaskReminders(for: task)
            }
        } else {
            print("TimelineViewModel: Notification permission denied")
        }
    }
       
    private func saveContext() {
        guard let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
            updateWidgetData() // Add this line

            print("TimelineViewModel: Context saved successfully")
        } catch {
            print("TimelineViewModel: Error saving context: \(error)")
        }
    }
    
    func clearAllTasks() {
        guard let modelContext = modelContext else {
            print("TimelineViewModel: No modelContext available")
            return
        }
        notificationService.cancelAllNotifications()

        let descriptor = FetchDescriptor<Task>()

        do {
            let allTasks = try modelContext.fetch(descriptor)
            for task in allTasks {
                modelContext.delete(task)
            }

            try modelContext.save()
            tasks = []
            print("TimelineViewModel: Cleared all tasks")
        } catch {
            print("TimelineViewModel: Error clearing tasks: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Task Count Methods
    
    func getCurrentTaskCount() -> Int {
        return tasks.count
    }
    
    func canCreateNewTask() -> Bool {
        guard let modelContext = modelContext else { return false }
        
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                // Count only non-cancelled tasks
                task.statusRawValue != "cancelled"
            }
        )
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            return allTasks.count < ProFeatures.maxTasksForFree
        } catch {
            print("Error fetching task count: \(error)")
            return false
        }
    }
    
    private func updateWidgetData() {
        WidgetDataManager.shared.updateWidgetData(tasks: tasks)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Test Methods
    
    // func createTestTask() {
    //         print(">>>>>>>>>> TimelineViewModel: Creating test task")
    //     
    //     guard let modelContext = modelContext else {
    //         print(">>>>>>>>>> TimelineViewModel: No modelContext available for test")
    //         return
    //     }
    //     
    //     let testTask = Task(
    //         title: "Test Task",
    //         icon: "🧪",
    //         startTime: Date(),
    //         durationMinutes: 30,
    //         color: .blue
    //     )
    //     
    //     print(">>>>>>>>>> TimelineViewModel: Test task created with ID: \(testTask.id)")
    //     modelContext.insert(testTask)
    //     
    //     do {
    //         try modelContext.save()
    //         print(">>>>>>>>>> TimelineViewModel: Test task saved successfully")
    //         
    //         // Try to fetch it back
    //         let descriptor = FetchDescriptor<Task>()
    //         let allTasks = try modelContext.fetch(descriptor)
    //         let testTasks = allTasks.filter { $0.id == testTask.id }
    //         print(">>>>>>>>>> TimelineViewModel: Found \(testTasks.count) test tasks after save")
    //         
    //     } catch {
    //         print(">>>>>>>>>> TimelineViewModel: Error saving test task: \(error)")
    //     }
    // }
}


extension TimelineViewModel {
   
    // Add this method for manual debugging
    func debugWidget() {
        print("\n🔍 TIMELINE DEBUG:")
        print("Tasks in timeline: \(tasks.count)")
        
        for task in tasks {
            print("- \(task.title): \(task.startTime) (\(task.durationMinutes)m) - Completed: \(task.isCompleted)")
        }
        
        updateWidgetData()
        WidgetDataManager.shared.debugWidgetData()
    }
    
    func updateBreakSuggestions() {
         // Enhanced break suggestion update with intelligent spacing
         let suggestions = breakAnalyzer.analyzeTasks(tasks)
         
         // Log for debugging
         print("TimelineViewModel: Generated \(suggestions.count) break suggestions")
         for suggestion in suggestions {
             print("  - \(suggestion.type.displayName): \(suggestion.reason) (Impact: \(suggestion.impactScore))")
         }
         
         DispatchQueue.main.async {
             self.breakSuggestions = suggestions
         }
     }
    
    func acceptBreakSuggestion(_ suggestion: BreakSuggestion) {
            guard let modelContext = modelContext else { return }
            
            // Mark suggestion as accepted in the analyzer
            breakAnalyzer.markSuggestionAccepted(suggestion)
            
            // Create the break task
            let breakTask = Task(
                title: suggestion.type.displayName,
                icon: suggestion.icon,
                startTime: suggestion.suggestedStartTime,
                durationMinutes: suggestion.suggestedDuration,
                color: suggestion.type.color,
                taskType: suggestion.type == .snack ? .meal : .relax
            )
            
            modelContext.insert(breakTask)
            
            // Schedule notifications
            notificationService.scheduleTaskReminders(for: breakTask)
            
            saveContext()
            
            // Refresh tasks and suggestions
            refreshTasks()
            
            // Delay before updating suggestions to avoid immediate new suggestions
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.updateBreakSuggestions()
            }
            
            print("TimelineViewModel: Accepted break suggestion - \(suggestion.type.displayName)")
        }
    
        func dismissBreakSuggestion(_ suggestion: BreakSuggestion) {
            // Mark as dismissed in the analyzer
            breakAnalyzer.markSuggestionDismissed(suggestion)
            
            // Remove from current suggestions
            breakSuggestions.removeAll { $0.id == suggestion.id }
            
            // Don't immediately generate new suggestions to avoid spam
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.updateBreakSuggestions()
            }
            
            print("TimelineViewModel: Dismissed break suggestion - \(suggestion.type.displayName)")
        }
       
       // MARK: - Suggestion Quality Control
       
       func shouldShowBreakSuggestion(_ suggestion: BreakSuggestion) -> Bool {
           let now = Date()
           
           // Don't show suggestions for the past
           guard suggestion.suggestedStartTime > now else { return false }
           
           // Don't show suggestions too far in the future (more than 4 hours)
           let timeUntilSuggestion = suggestion.suggestedStartTime.timeIntervalSince(now)
           guard timeUntilSuggestion <= 4 * 3600 else { return false }
           
           // Check if there's already a task at the suggested time
           let conflictingTask = tasks.first { task in
               let taskEnd = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
               return suggestion.suggestedStartTime >= task.startTime &&
                      suggestion.suggestedStartTime <= taskEnd
           }
           
           if conflictingTask != nil {
               return false
           }
           
           // Check minimum impact score threshold
           return suggestion.impactScore >= 40.0
       }
       
       // MARK: - Enhanced Refresh Methods
       
       func refreshTasksWithBreakSuggestions(for date: Date = Date()) {
           loadTodayTasks(for: date)
           
           // Add a small delay to ensure tasks are loaded before analyzing breaks
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
               self.updateBreakSuggestions()
           }
       }
       
       // MARK: - Daily Cleanup
       
       func performDailyBreakSuggestionCleanup() {
           // Clean up old dismissed suggestions
           breakAnalyzer.cleanupDismissedSuggestions()
           
           // Remove any stale suggestions
           let now = Date()
           breakSuggestions.removeAll { suggestion in
               suggestion.suggestedStartTime.addingTimeInterval(TimeInterval(suggestion.suggestedDuration * 60)) < now
           }
           
           print("TimelineViewModel: Performed daily break suggestion cleanup")
       }
       
       // MARK: - Analytics Integration
       
       func trackBreakSuggestionMetrics() {
           let totalSuggestions = breakSuggestions.count
           let highImpactSuggestions = breakSuggestions.filter { $0.impactScore >= 70 }.count
           let typeDistribution = Dictionary(grouping: breakSuggestions, by: \.type)
           
           print("Break Suggestion Metrics:")
           print("  - Total suggestions: \(totalSuggestions)")
           print("  - High impact suggestions: \(highImpactSuggestions)")
           print("  - Type distribution: \(typeDistribution.mapValues { $0.count })")
       }
       
       // MARK: - Task Conflict Detection
       
       /// Detects conflicts for a given task using the enhanced conflict service
       /// The service automatically validates that conflicting tasks are still present
       /// and unchanged, preventing ghost conflicts and stale conflict data.
       /// 
       /// Note: For optimal performance, call conflictService.updateTaskStateCache(for: task)
       /// whenever a task is modified to keep the conflict detection cache in sync.
       func detectConflicts(for task: Task) -> [TaskConflictService.TaskConflict] {
           return conflictService.detectConflicts(for: task, in: tasks)
       }
       
       func getConflictingTasks(for task: Task) -> [Task] {
           let conflicts = detectConflicts(for: task)
           let conflictingIds = conflicts.compactMap { $0.conflictingTaskId }
           return tasks.filter { conflictingIds.contains($0.id) }
       }
       
       func hasConflicts(for task: Task) -> Bool {
           return !detectConflicts(for: task).isEmpty
       }
}
