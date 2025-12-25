import SwiftUI

struct LiquidWeekDateNavigator: View {
    @Binding var selectedDate: Date
    var tasksForDate: [Date: Int] = [:]
    @State private var showingDatePicker = false
    @State private var currentWeekOffset: Int = 0
    @State private var baseWeekStart: Date? = nil
    @State private var preferredDayIndex: Int? = nil
    
    private var calendar: Calendar { Calendar.current }
    
    private var effectiveBaseWeekStart: Date {
        baseWeekStart ?? weekStart(for: selectedDate)
    }
    
    private var currentWeekStart: Date {
        calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: effectiveBaseWeekStart) ?? effectiveBaseWeekStart
    }
    
    private var currentWeek: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: currentWeekStart) }
    }
    
    private var isCurrentWeek: Bool {
        let todayWeekStart = weekStart(for: Date())
        return weeksBetween(effectiveBaseWeekStart, and: todayWeekStart) == currentWeekOffset
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: LiquidDesignSystem.Spacing.md) {
            // Header with month/year and navigation
            HStack(alignment: .center, spacing: LiquidDesignSystem.Spacing.sm) {
                // Month/Year button
                Button(action: { showingDatePicker = true }) {
                    HStack(spacing: LiquidDesignSystem.Spacing.xs) {
                        Text(monthYearString(from: selectedDate))
                            .font(LiquidDesignSystem.Typography.titleFont)
                            .fontWeight(.bold)
                            .foregroundStyle(LiquidDesignSystem.Colors.textPrimary)
                        
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundStyle(LiquidDesignSystem.Colors.accent)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Navigation controls
                HStack(spacing: LiquidDesignSystem.Spacing.sm) {
                    // Previous week
                    Button(action: { 
                        withAnimation(LiquidDesignSystem.Animation.smooth) { 
                            moveWeek(by: -1) 
                        } 
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundStyle(LiquidDesignSystem.Colors.accent)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(LiquidDesignSystem.Colors.glassBackground)
                            )
                            .shadow(
                                color: Color.black.opacity(0.05),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    }
                    
                    // Today button (only show if not current week)
                    if !isCurrentWeek {
                        Button(action: { 
                            withAnimation(LiquidDesignSystem.Animation.smooth) { 
                                jumpToToday() 
                            } 
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location")
                                    .font(.caption)
                                Text(NSLocalizedString("today", comment: "Today label"))
                                    .font(LiquidDesignSystem.Typography.captionFont)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(LiquidDesignSystem.Colors.accentGradient)
                            .clipShape(Capsule())
                            .shadow(
                                color: LiquidDesignSystem.Colors.accent.opacity(0.4),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Next week
                    Button(action: { 
                        withAnimation(LiquidDesignSystem.Animation.smooth) { 
                            moveWeek(by: 1) 
                        } 
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundStyle(LiquidDesignSystem.Colors.accent)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(LiquidDesignSystem.Colors.glassBackground)
                            )
                            .shadow(
                                color: Color.black.opacity(0.05),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    }
                }
            }
            .padding(.horizontal, LiquidDesignSystem.Spacing.lg)
            
            // Week days horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LiquidDesignSystem.Spacing.md) {
                    ForEach(currentWeek, id: \.self) { date in
                        LiquidDateDayView(
                            date: date,
                            selectedDate: $selectedDate,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasTask: hasTasksForDate(date),
                            taskCount: tasksForDate[normalizeDate(date)] ?? 0
                        )
                    }
                }
                .padding(.horizontal, LiquidDesignSystem.Spacing.lg)
            }
            
            // Week indicator dots
            HStack(spacing: 6) {
                ForEach((currentWeekOffset-2)...(currentWeekOffset+2), id: \.self) { offset in
                    Circle()
                        .fill(
                            offset == currentWeekOffset 
                                ? LiquidDesignSystem.Colors.accent
                                : LiquidDesignSystem.Colors.accent.opacity(0.2)
                        )
                        .frame(
                            width: offset == currentWeekOffset ? 8 : 6,
                            height: offset == currentWeekOffset ? 8 : 6
                        )
                }
            }
            .animation(LiquidDesignSystem.Animation.smooth, value: currentWeekOffset)
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.vertical, LiquidDesignSystem.Spacing.md)
        .liquidCard()
        .sheet(isPresented: $showingDatePicker) {
            LiquidDatePickerSheet(
                selectedDate: $selectedDate, 
                currentWeekOffset: $currentWeekOffset
            )
        }
        .onAppear {
            baseWeekStart = weekStart(for: selectedDate)
            preferredDayIndex = dayIndexInWeek(for: selectedDate)
            if let base = baseWeekStart {
                currentWeekOffset = weeksBetween(base, and: weekStart(for: selectedDate))
            }
        }
        .onChange(of: selectedDate) { _, newValue in
            preferredDayIndex = dayIndexInWeek(for: newValue)
            if let base = baseWeekStart {
                currentWeekOffset = weeksBetween(base, and: weekStart(for: newValue))
            } else {
                baseWeekStart = weekStart(for: newValue)
                currentWeekOffset = 0
            }
        }
    }
    
    // MARK: - Helper Functions
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func normalizeDate(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    private func hasTasksForDate(_ date: Date) -> Bool {
        (tasksForDate[normalizeDate(date)] ?? 0) > 0
    }
    
    private func weekStart(for date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }
    
    private func dayIndexInWeek(for date: Date) -> Int {
        let start = weekStart(for: date)
        let comps = calendar.dateComponents([.day], from: start, to: date)
        return max(0, min(6, comps.day ?? 0))
    }
    
    private func weeksBetween(_ from: Date, and to: Date) -> Int {
        calendar.dateComponents([.weekOfYear], from: from, to: to).weekOfYear ?? 0
    }
    
    private func moveWeek(by delta: Int) {
        currentWeekOffset += delta
        let index = preferredDayIndex ?? dayIndexInWeek(for: selectedDate)
        let newStart = currentWeekStart
        if let newDate = calendar.date(byAdding: .day, value: index, to: newStart) {
            selectedDate = newDate
        }
    }
    
    private func jumpToToday() {
        let today = Date()
        let todayStart = weekStart(for: today)
        if baseWeekStart == nil {
            baseWeekStart = weekStart(for: selectedDate)
        }
        if let base = baseWeekStart {
            currentWeekOffset = weeksBetween(base, and: todayStart)
        } else {
            currentWeekOffset = 0
        }
        preferredDayIndex = dayIndexInWeek(for: today)
        selectedDate = today
    }
}

#Preview {
    LiquidWeekDateNavigator(
        selectedDate: .constant(Date()),
        tasksForDate: [
            Calendar.current.startOfDay(for: Date()): 3,
            Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()): 1,
            Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()): 2
        ]
    )
    .padding()
    .background(LiquidDesignSystem.Colors.meshGradientBackground)
}

