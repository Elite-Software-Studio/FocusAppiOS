//
//  FocusAnalyticsEngine.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/24/25.
//

import Foundation
import SwiftData

// MARK: - Focus Analytics Engine
@MainActor
class FocusAnalyticsEngine: ObservableObject {
    @Published var weeklyInsights: [FocusInsight] = []
    @Published var isAnalyzing = false
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Main Analysis Function
    func generateWeeklyInsights() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        guard let tasks = await fetchRecentTasks() else { return }
        
        var insights: [FocusInsight] = []
        
        // Analyze different patterns
        insights.append(contentsOf: analyzeTimeOfDayPatterns(tasks))
        insights.append(contentsOf: analyzeTaskDurationPatterns(tasks))
        insights.append(contentsOf: analyzeBreakEffectiveness(tasks))
        insights.append(contentsOf: analyzeCompletionPatterns(tasks))
        insights.append(contentsOf: analyzeDayOfWeekPatterns(tasks))
        
        // Sort by impact score and take top 3-5
        weeklyInsights = insights
            .sorted { $0.impactScore > $1.impactScore }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - Pattern Analysis Functions
    
    private func analyzeTimeOfDayPatterns(_ tasks: [Task]) -> [FocusInsight] {
        let timeSlots = categorizeTasksByTimeOfDay(tasks)
        var insights: [FocusInsight] = []
        
        // Find best performance time
        if let bestSlot = timeSlots.max(by: { $0.value.averageCompletionRate < $1.value.averageCompletionRate }) {
            let improvement = bestSlot.value.averageCompletionRate - timeSlots.values.map(\.averageCompletionRate).average()
            
            if improvement > 0.15 { // 15% better than average
                insights.append(FocusInsight(
                    type: .timeOfDay,
                    title: "🌅 Peak Performance Window",
                    message: "You're \(Int(improvement * 100))% more productive during \(bestSlot.key.displayName)",
                    recommendation: "Schedule your most important tasks between \(bestSlot.key.timeRange)",
                    impactScore: improvement * 100,
                    dataPoints: bestSlot.value.taskCount,
                    trend: .improving
                ))
            }
        }
        
        // Find worst performance time
        if let worstSlot = timeSlots.min(by: { $0.value.averageCompletionRate < $1.value.averageCompletionRate }) {
            let decline = timeSlots.values.map(\.averageCompletionRate).average() - worstSlot.value.averageCompletionRate
            
            if decline > 0.20 { // 20% worse than average
                insights.append(FocusInsight(
                    type: .timeOfDay,
                    title: "⚠️ Energy Dip Detected",
                    message: "Your focus drops \(Int(decline * 100))% during \(worstSlot.key.displayName)",
                    recommendation: "Consider scheduling breaks, admin tasks, or lighter work during \(worstSlot.key.timeRange)",
                    impactScore: decline * 80,
                    dataPoints: worstSlot.value.taskCount,
                    trend: .declining
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeTaskDurationPatterns(_ tasks: [Task]) -> [FocusInsight] {
        let durationGroups = Dictionary(grouping: tasks) { task in
            DurationCategory.from(minutes: task.durationMinutes)
        }
        
        var insights: [FocusInsight] = []
        
        // Find optimal task duration
        if let optimalDuration = durationGroups.max(by: { $0.value.averageCompletionRate < $1.value.averageCompletionRate }) {
            let completionRate = optimalDuration.value.averageCompletionRate
            
            if completionRate > 0.8 && optimalDuration.value.count >= 5 {
                insights.append(FocusInsight(
                    type: .taskDuration,
                    title: "⏱️ Sweet Spot Duration",
                    message: "You complete \(Int(completionRate * 100))% of \(optimalDuration.key.displayName) tasks",
                    recommendation: "Try breaking longer tasks into \(optimalDuration.key.suggestedDuration)-minute chunks",
                    impactScore: completionRate * 90,
                    dataPoints: optimalDuration.value.count,
                    trend: .stable
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeBreakEffectiveness(_ tasks: [Task]) -> [FocusInsight] {
        // Group tasks by whether they followed a break
        let tasksAfterBreaks = tasks.filter { task in
            // Check if there was a break in the previous 30 minutes
            let thirtyMinutesBefore = task.startTime.addingTimeInterval(-30 * 60)
            return tasks.contains { breakTask in
                breakTask.taskType == .relax &&
                breakTask.startTime >= thirtyMinutesBefore &&
                breakTask.startTime < task.startTime
            }
        }
        
        let tasksWithoutBreaks = tasks.filter { !tasksAfterBreaks.contains($0) }
        
        guard tasksAfterBreaks.count >= 3 && tasksWithoutBreaks.count >= 3 else { return [] }
        
        let breakBenefit = tasksAfterBreaks.averageCompletionRate - tasksWithoutBreaks.averageCompletionRate
        
        if breakBenefit > 0.15 {
            return [FocusInsight(
                type: .breakPattern,
                title: "🧘 Break Power Boost",
                message: "Tasks after breaks have \(Int(breakBenefit * 100))% higher completion rates",
                recommendation: "Schedule 5-10 minute breaks before important tasks",
                impactScore: breakBenefit * 85,
                dataPoints: tasksAfterBreaks.count,
                trend: .improving
            )]
        }
        
        return []
    }
    
    private func analyzeCompletionPatterns(_ tasks: [Task]) -> [FocusInsight] {
        let last7Days = tasks.filter { task in
            task.startTime >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        }
        
        let completionRate = last7Days.averageCompletionRate
        let totalFocusMinutes = last7Days.filter(\.isCompleted).reduce(0) { $0 + $1.durationMinutes }
        
        var insights: [FocusInsight] = []
        
        // Weekly summary
        if last7Days.count >= 5 {
            let weeklyGoal: Double = 0.75 // 75% completion target
            
            if completionRate >= weeklyGoal {
                insights.append(FocusInsight(
                    type: .completion,
                    title: "🎯 Consistency Champion",
                    message: "You completed \(Int(completionRate * 100))% of tasks this week (\(totalFocusMinutes/60)h focused)",
                    recommendation: "Great momentum! Consider gradually increasing your daily focus goals",
                    impactScore: completionRate * 70,
                    dataPoints: last7Days.count,
                    trend: .improving
                ))
            } else {
                let shortfall = weeklyGoal - completionRate
                insights.append(FocusInsight(
                    type: .completion,
                    title: "📈 Room for Growth",
                    message: "You're \(Int(shortfall * 100))% away from your completion goal this week",
                    recommendation: "Try reducing task durations by 25% or scheduling fewer tasks per day",
                    impactScore: shortfall * 60,
                    dataPoints: last7Days.count,
                    trend: .needsImprovement
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeDayOfWeekPatterns(_ tasks: [Task]) -> [FocusInsight] {
        let dayGroups = Dictionary(grouping: tasks) { task in
            Calendar.current.component(.weekday, from: task.startTime)
        }
        
        guard dayGroups.count >= 4 else { return [] }
        
        let dayPerformance = dayGroups.mapValues { tasks in
            tasks.averageCompletionRate
        }
        
        if let bestDay = dayPerformance.max(by: { $0.value < $1.value }),
           let worstDay = dayPerformance.min(by: { $0.value < $1.value }) {
            
            let difference = bestDay.value - worstDay.value
            
            if difference > 0.25 {
                return [FocusInsight(
                    type: .dayOfWeek,
                    title: "📅 Weekly Rhythm",
                    message: "\(dayName(bestDay.key)) is your strongest day (\(Int(bestDay.value * 100))% completion)",
                    recommendation: "Schedule your most challenging tasks on \(dayName(bestDay.key))s",
                    impactScore: difference * 75,
                    dataPoints: dayGroups[bestDay.key]?.count ?? 0,
                    trend: .stable
                )]
            }
        }
        
        return []
    }
    
    // MARK: - Helper Functions
    
    private func fetchRecentTasks() async -> [Task]? {
        guard let modelContext = modelContext else { return nil }
        
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.startTime >= thirtyDaysAgo && !task.isGeneratedFromRepeat
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching tasks for analysis: \(error)")
            return nil
        }
    }
    
    private func categorizeTasksByTimeOfDay(_ tasks: [Task]) -> [TimeOfDay: TimeSlotMetrics] {
        let grouped = Dictionary(grouping: tasks) { task in
            TimeOfDay.from(date: task.startTime)
        }
        
        return grouped.mapValues { tasks in
            TimeSlotMetrics(
                taskCount: tasks.count,
                averageCompletionRate: tasks.averageCompletionRate,
                totalMinutes: tasks.reduce(0) { $0 + $1.durationMinutes }
            )
        }
    }
    
    private func dayName(_ weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.weekdaySymbols = formatter.weekdaySymbols
        return formatter.weekdaySymbols[weekday - 1]
    }
}

// MARK: - Supporting Models

struct FocusInsight: Identifiable, Codable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let recommendation: String
    let impactScore: Double // 0-100, higher = more important
    let dataPoints: Int // How many tasks this insight is based on
    let trend: Trend
    let createdAt = Date()
}

enum InsightType: String, Codable, CaseIterable {
    case timeOfDay = "timeOfDay"
    case taskDuration = "taskDuration"
    case breakPattern = "breakPattern"
    case completion = "completion"
    case dayOfWeek = "dayOfWeek"
}

enum Trend: String, Codable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
    case needsImprovement = "needsImprovement"
}

enum TimeOfDay: String, CaseIterable {
    case earlyMorning = "earlyMorning" // 6-9 AM
    case lateMorning = "lateMorning"   // 9-12 PM
    case earlyAfternoon = "earlyAfternoon" // 12-3 PM
    case lateAfternoon = "lateAfternoon"   // 3-6 PM
    case evening = "evening"               // 6-9 PM
    case night = "night"                   // 9+ PM
    
    static func from(date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<9: return .earlyMorning
        case 9..<12: return .lateMorning
        case 12..<15: return .earlyAfternoon
        case 15..<18: return .lateAfternoon
        case 18..<21: return .evening
        default: return .night
        }
    }
    
    var displayName: String {
        switch self {
        case .earlyMorning: return "early morning"
        case .lateMorning: return "late morning"
        case .earlyAfternoon: return "early afternoon"
        case .lateAfternoon: return "late afternoon"
        case .evening: return "evening"
        case .night: return "night"
        }
    }
    
    var timeRange: String {
        switch self {
        case .earlyMorning: return "6-9 AM"
        case .lateMorning: return "9 AM-12 PM"
        case .earlyAfternoon: return "12-3 PM"
        case .lateAfternoon: return "3-6 PM"
        case .evening: return "6-9 PM"
        case .night: return "9+ PM"
        }
    }
}

enum DurationCategory: String, CaseIterable {
    case short = "short"       // 15-30 min
    case medium = "medium"     // 30-60 min
    case long = "long"         // 60-120 min
    case extended = "extended" // 120+ min
    
    static func from(minutes: Int) -> DurationCategory {
        switch minutes {
        case 0..<30: return .short
        case 30..<60: return .medium
        case 60..<120: return .long
        default: return .extended
        }
    }
    
    var displayName: String {
        switch self {
        case .short: return "short (15-30 min)"
        case .medium: return "medium (30-60 min)"
        case .long: return "long (1-2 hour)"
        case .extended: return "extended (2+ hour)"
        }
    }
    
    var suggestedDuration: String {
        switch self {
        case .short: return "25"
        case .medium: return "45"
        case .long: return "90"
        case .extended: return "120"
        }
    }
}

struct TimeSlotMetrics {
    let taskCount: Int
    let averageCompletionRate: Double
    let totalMinutes: Int
}

// MARK: - Array Extensions for Analytics

extension Array where Element == Task {
    var averageCompletionRate: Double {
        guard !isEmpty else { return 0 }
        let completedCount = filter(\.isCompleted).count
        return Double(completedCount) / Double(count)
    }
}

extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
