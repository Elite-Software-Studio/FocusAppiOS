import SwiftUI
import Combine
import SwiftData

class TaskTimerService: ObservableObject {
    @Published var currentTask: Task?
    @Published var elapsedSeconds: Int = 0
    
    private var timer: Timer?
    private var startTime: Date?
    private var modelContext: ModelContext?
    
    @StateObject private var focusManager = FocusModeManager()
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // Start a task with smart time calculation
    @MainActor func startTask(_ task: Task, reset: Bool = false) {
        stopCurrentTask()
        
        // Smart time calculation: choose between previously spent time or schedule-based elapsed time
        let timeAlreadySpent = reset ? 0 : calculateSmartElapsedTime(for: task)
        let startingElapsedSeconds = timeAlreadySpent * 60
        
        // Update task status
        task.status = .inProgress
        task.actualStartTime = Date()
        if reset {
        }
        saveContext()
        
        // Set up timer service state
        currentTask = task
        
        // Set startTime to account for already spent time
        startTime = Date().addingTimeInterval(-TimeInterval(startingElapsedSeconds))
        
        elapsedSeconds = startingElapsedSeconds
        
        print("TaskTimerService: Starting task '\(task.title)' with \(timeAlreadySpent)m already elapsed")
        print("TaskTimerService: Starting timer at \(startingElapsedSeconds) seconds")
        
        _Concurrency.Task {
          await  focusManager.setupCustomNotificationFiltering(for: .deepWork)
        }
        startTimer()
    }
    
    // Calculate smart elapsed time: previously spent time OR schedule-based time
    public func calculateSmartElapsedTime(for task: Task) -> Int {
        return  task.durationMinutes - _minutesRemain (for: task)
    }
    
    
    public func _minutesRemain(for task: Task) -> Int {
        let now = Date()
        let taskStartTime = task.startTime
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        
        // If task is currently active
        if now >= taskStartTime && now <= taskEndTime {
            let remaining = taskEndTime.timeIntervalSince(now)
            let remainingMinutes = Int(remaining / 60)
            
            if remainingMinutes > 60 {
                return remainingMinutes
            } else if remainingMinutes > 0 {
                return remainingMinutes
            } else {
                // Less than a minute remaining
                let remainingSeconds = Int(remaining)
                return remainingSeconds / 60
            }
            
        }
        return 0
    }
    
    
    
    // Pause the current task
    @MainActor func pauseTask() {
        guard let task = currentTask else { return }
        
        stopTimer()
        
        // Calculate total time spent including current session
        let currentSessionMinutes = elapsedSeconds / 60
        task.status = .paused
        task.updatedAt = Date()
        saveContext()
    }
    
    // Resume a paused task
    @MainActor func resumeTask() {
        guard let task = currentTask, task.isPaused else { return }
        
        task.status = .inProgress
        task.updatedAt = Date()
        saveContext()
        
        // Use the actual time spent stored in the task (this takes priority)
        let timeAlreadySpent = _minutesRemain(for: task)
        startTime = Date().addingTimeInterval(-TimeInterval(timeAlreadySpent * 60))
        
        elapsedSeconds = timeAlreadySpent * 60
        startTimer()
    }
    
    // Complete the current task
    @MainActor func completeTask() {
        guard let task = currentTask else { return }
        
        stopTimer()
        
        let totalTimeSpent = elapsedSeconds / 60
        task.isCompleted = true
        task.status = .completed
        task.updatedAt = Date()
        
        print("TaskTimerService: Completed task with \(totalTimeSpent)m total time")
        saveContext()
        
        // Clear after a brief delay to show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentTask = nil
            self.elapsedSeconds = 0
        }
    }
    
    // Stop the current task
    func stopCurrentTask() {
        stopTimer()
        
        // Save current progress before stopping
        if let task = currentTask {
            let totalTimeSpent = elapsedSeconds / 60
            task.status = .scheduled
            task.updatedAt = Date()
            saveContext()
            
            print("TaskTimerService: Stopped task with \(totalTimeSpent)m total time")
        }
        
        
        _Concurrency.Task {
            await focusManager.deactivateFocus()
        }
        currentTask = nil
        elapsedSeconds = 0
        startTime = nil
    }
    
    // Private timer methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.elapsedSeconds += 1
                
                // Auto-complete when reaching the planned duration
                if self.currentRemainingMinutes <= 0 && !self.isOvertime && self.elapsedSeconds >= (self.currentTask?.durationMinutes ?? 0) * 60 {
                    self.handleTimerCompletion()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Handle automatic timer completion
    @MainActor private func handleTimerCompletion() {
        guard let task = currentTask else { return }
        
        stopTimer()
        
        // Mark task as completed automatically
        task.isCompleted = true
        task.status = .completed
        task.updatedAt = Date()
        saveContext()
        
        print("TaskTimerService: Auto-completed task '\(task.title)' after \(task.durationMinutes) minutes")
        
        // Clear after a brief delay to show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentTask = nil
            self.elapsedSeconds = 0
        }
    }
    
    // MARK: - Computed Properties
    
    var currentElapsedMinutes: Int {
        elapsedSeconds / 60
    }
    
    var currentRemainingMinutes: Int {
        guard let task = currentTask else { return 0 }
        let remainingSeconds = max(0, (task.durationMinutes * 60) - elapsedSeconds)
        return remainingSeconds / 60
    }
    
    var currentRemainingSeconds: Int {
        guard let task = currentTask else { return 0 }
        let remainingTotalSeconds = max(0, (task.durationMinutes * 60) - elapsedSeconds)
        return remainingTotalSeconds % 60
    }
    
    var currentProgressPercentage: Double {
        guard let task = currentTask, task.durationMinutes > 0 else { return 0 }
        return min(1.0, Double(elapsedSeconds) / Double(task.durationMinutes * 60))
    }
    
    var isOvertime: Bool {
        guard let task = currentTask else { return false }
        return elapsedSeconds > (task.durationMinutes * 60)
    }
    
    var formattedElapsedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedRemainingTime: String {
        guard let task = currentTask else { return "00:00" }
        
        let totalRemainingSeconds = max(0, (task.durationMinutes * 60) - elapsedSeconds)
        let minutes = totalRemainingSeconds / 60
        let seconds = totalRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Additional computed properties for better timer control
    var isTimerRunning: Bool {
        return timer != nil && currentTask?.isActive == true
    }
    
    var shouldShowOvertime: Bool {
        return isOvertime && currentTask?.isActive == true
    }
    
    // Get formatted time remaining with units
    var timeRemainingWithUnits: String {
        guard let task = currentTask else { return "No active task" }
        
        if isOvertime {
            let overtimeSeconds = elapsedSeconds - (task.durationMinutes * 60)
            let overtimeMinutes = overtimeSeconds / 60
            let seconds = overtimeSeconds % 60
            
            if overtimeMinutes > 0 {
                return "\(overtimeMinutes)m \(seconds)s overtime"
            } else {
                return "\(seconds)s overtime"
            }
        } else {
            let remainingTotalSeconds = (task.durationMinutes * 60) - elapsedSeconds
            let minutes = remainingTotalSeconds / 60
            let seconds = remainingTotalSeconds % 60
            
            if minutes > 0 {
                return "\(minutes)m \(seconds)s remaining"
            } else if seconds > 0 {
                return "\(seconds)s remaining"
            } else {
                return "Time's up!"
            }
        }
    }
    
    // Get progress information for UI
    var progressInfo: (percentage: Double, color: Color, isOvertime: Bool) {
        guard let task = currentTask else {
            return (0.0, .gray, false)
        }
        
        let percentage = currentProgressPercentage
        let overtime = isOvertime
        
        let color: Color
        if overtime {
            color = .red
        } else if percentage < 0.5 {
            color = .green
        } else if percentage < 0.8 {
            color = .orange
        } else {
            color = .red
        }
        
        return (min(1.0, percentage), color, overtime)
    }
    
    // MARK: - Private Methods
    private func saveContext() {
        guard let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
            print("TaskTimerService: Context saved successfully")
        } catch {
            print("TaskTimerService: Error saving context: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    // Check if a task can be resumed
    func canResumeTask(_ task: Task) -> Bool {
        return _minutesRemain(for: task) > 0 && _minutesRemain(for: task)  < task.durationMinutes && !task.isCompleted
    }
    
    // Get time spent vs planned for a task
    func getTaskTimeInfo(_ task: Task) -> (spent: Int, planned: Int, remaining: Int, percentage: Double) {
        let spent = _minutesRemain(for: task)
        let planned = task.durationMinutes
        let remaining = max(0, planned - spent)
        let percentage = planned > 0 ? Double(spent) / Double(planned) : 0.0
        
        return (spent, planned, remaining, min(1.0, percentage))
    }
    
    // Format duration in a human-readable way
    func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }
    
    // Calculate how late a task start would be (for UI display)
    func getLateStartInfo(for task: Task) -> (isLate: Bool, minutesLate: Int) {
        let now = Date()
        let taskStartTime = task.startTime
        
        if now > taskStartTime {
            let lateSeconds = now.timeIntervalSince(taskStartTime)
            let minutesLate = Int(lateSeconds / 60)
            return (true, minutesLate)
        }
        
        return (false, 0)
    }
    
    // Get the effective remaining time considering schedule
    func getEffectiveRemainingTime(for task: Task) -> Int {
        let now = Date()
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        if now >= taskEndTime {
            return 0 // Task time window has passed
        }
        
        let remainingScheduledTime = taskEndTime.timeIntervalSince(now)
        return Int(remainingScheduledTime / 60)
    }
}
