import SwiftUI

struct WeekDateNavigator: View {
    @Binding var selectedDate: Date
    var tasksForDate: [Date: Int] = [:]
    @State private var showingDatePicker = false
    @State private var currentWeekOffset: Int = 0
    @State private var baseWeekStart: Date? = nil
    @State private var preferredDayIndex: Int? = nil // 0..6, preserves weekday across week jumps
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
        VStack(alignment: .center,  spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Button(action: { showingDatePicker = true }) {
                    HStack(spacing: 8) {
                        Text(monthYearString(from: selectedDate))
                            .font(AppFonts.title())
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundColor(AppColors.accent)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { withAnimation(.easeInOut(duration: 0.3)) { moveWeek(by: -1) } }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(AppColors.accent)
                            .frame(width: 32, height: 32)
                            .background(AppColors.card)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    if !isCurrentWeek {
                        Button(action: { withAnimation(.easeInOut(duration: 0.3)) { jumpToToday() } }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location").font(.caption)
                                Text(LanguageManager.localized("today", comment: "Today label")).font(AppFonts.caption()).fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(LinearGradient(gradient: Gradient(colors: [AppColors.accent.opacity(0.9), AppColors.accent]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Capsule())
                            .shadow(color: AppColors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    Button(action: { withAnimation(.easeInOut(duration: 0.3)) { moveWeek(by: 1) } }) {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(AppColors.accent)
                            .frame(width: 32, height: 32)
                            .background(AppColors.card)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(currentWeek, id: \.self) { date in
                        DateDayView(
                            date: date,
                            selectedDate: $selectedDate,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasTask: hasTasksForDate(date),
                            taskCount: tasksForDate[normalizeDate(date)] ?? 0
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            HStack {
                ForEach((currentWeekOffset-2)...(currentWeekOffset+2), id: \.self) { offset in
                    Circle()
                        .fill(offset == currentWeekOffset ? AppColors.accent : AppColors.accent.opacity(0.2))
                        .frame(width: offset == currentWeekOffset ? 8 : 6, height: offset == currentWeekOffset ? 8 : 6)
                        .animation(.easeInOut(duration: 0.2), value: currentWeekOffset)
                }
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 20).fill(AppColors.background).shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2))
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate, currentWeekOffset: $currentWeekOffset)
        }
        .onAppear {
            // Initialize anchor week and preferred day
            baseWeekStart = weekStart(for: selectedDate)
            preferredDayIndex = dayIndexInWeek(for: selectedDate)
            // Align offset with selectedDate (in case parent prefilled)
            if let base = baseWeekStart {
                currentWeekOffset = weeksBetween(base, and: weekStart(for: selectedDate))
            }
        }
        .onChange(of: selectedDate) { _, newValue in
            // When selection changes (tap or external), keep weekday index and align offset
            preferredDayIndex = dayIndexInWeek(for: newValue)
            if let base = baseWeekStart {
                currentWeekOffset = weeksBetween(base, and: weekStart(for: newValue))
            } else {
                baseWeekStart = weekStart(for: newValue)
                currentWeekOffset = 0
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: date) }
    private func normalizeDate(_ date: Date) -> Date { calendar.startOfDay(for: date) }
    private func hasTasksForDate(_ date: Date) -> Bool { (tasksForDate[normalizeDate(date)] ?? 0) > 0 }

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
        if baseWeekStart == nil { baseWeekStart = weekStart(for: selectedDate) }
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
    WeekDateNavigator(
        selectedDate: .constant(Date()),
        tasksForDate: [
            Calendar.current.startOfDay(for: Date()): 3,
            Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()): 1,
            Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()): 2
        ]
    )
    .environmentObject(ThemeManager())
    .padding()
    .background(Color.gray.opacity(0.1))
}


