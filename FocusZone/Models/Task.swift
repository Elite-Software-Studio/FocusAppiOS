import SwiftUI
import SwiftData
import Foundation

enum TaskStatus: String, Codable, CaseIterable  {
    case scheduled = "scheduled"
    case inProgress = "inProgress"
    case paused = "paused"
    case completed = "completed"
    case cancelled = "cancelled"
}

@Model
class Task {
    @Attribute(.unique) var id: UUID
    var title: String
    var icon: String
    var startTime: Date
    var durationMinutes: Int
    var isCompleted: Bool
    var taskTypeRawValue: String?
    var statusRawValue: String
    var actualStartTime: Date?
    var repeatRuleRawValue: String
    var createdAt: Date
    var updatedAt: Date
    
    // Parent-Child Relationship
    var parentTaskId: UUID? // Track the original task for virtual tasks
    var isGeneratedFromRepeat: Bool = false
    var focusSettingsData: Data?

    
    // SwiftData relationships (one-to-many)
    @Relationship(deleteRule: .cascade, inverse: \Task.parentTask)
    var children: [Task] = []
    
    @Relationship
    var parentTask: Task?
    
    // Simple color storage as string
    var colorHex: String
    
    init(
        id: UUID = UUID(),
        title: String,
        icon: String,
        startTime: Date,
        durationMinutes: Int,
        color: Color = .blue,
        isCompleted: Bool = false,
        taskType: TaskType? = nil,
        status: TaskStatus = .scheduled,
        actualStartTime: Date? = nil,
        repeatRule: RepeatRule = .once,
        isGeneratedFromRepeat: Bool = false,
        parentTaskId: UUID? = nil,
        parentTask: Task? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.isCompleted = isCompleted
        self.taskTypeRawValue = taskType?.rawValue
        self.statusRawValue = status.rawValue
        self.actualStartTime = actualStartTime
        self.repeatRuleRawValue = repeatRule.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        self.colorHex = color.toHex()
        self.parentTaskId = parentTaskId
        self.isGeneratedFromRepeat = isGeneratedFromRepeat
        self.parentTask = parentTask
    }
    
    var focusSettings: FocusSettings? {
         get {
             guard let data = focusSettingsData else { return nil }
             return try? JSONDecoder().decode(FocusSettings.self, from: data)
         }
         set {
             focusSettingsData = try? JSONEncoder().encode(newValue)
             updatedAt = Date()
         }
     }
    
    // Computed properties
    var color: Color {
        get {
            Color(hex: colorHex) ?? .blue
        }
        set {
            colorHex = newValue.toHex()
            updatedAt = Date()
        }
    }
    
    var taskType: TaskType? {
        get {
            guard let rawValue = taskTypeRawValue else { return nil }
            return TaskType(rawValue: rawValue)
        }
        set {
            taskTypeRawValue = newValue?.rawValue
            updatedAt = Date()
        }
    }
    
    var status: TaskStatus {
        get {
            TaskStatus(rawValue: statusRawValue) ?? .scheduled
        }
        set {
            statusRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    var repeatRule: RepeatRule {
        get {
            RepeatRule(rawValue: repeatRuleRawValue) ?? .once
        }
        set {
            repeatRuleRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    // Computed properties for task timing
    var isScheduled: Bool {
        status == .scheduled
    }
    
    var isActive: Bool {
        status == .inProgress
    }
    
    var isPaused: Bool {
        status == .paused
    }
    
    var isFinished: Bool {
        status == .completed || isCompleted
    }
    
    var estimatedEndTime: Date {
        startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }
    
    // Helper methods for parent-child relationships
    var isParentTask: Bool {
        return !children.isEmpty || (repeatRule != .none && repeatRule != .once && !isGeneratedFromRepeat)
    }
    
    var isChildTask: Bool {
        return parentTask != nil || isGeneratedFromRepeat
    }
    
    var rootParent: Task {
        return parentTask?.rootParent ?? self
    }
}

