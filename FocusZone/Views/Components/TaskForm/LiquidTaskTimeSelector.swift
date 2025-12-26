import SwiftUI

struct LiquidTaskTimeSelector: View {
    @Binding var selectedDate: Date
    @Binding var startTime: Date
    @State private var showingTimePicker: Bool = false
    @State private var showingDatePicker: Bool = false
    
    // Time picker state
    @State private var selectedHour: Int = 12
    @State private var selectedMinute: Int = 0
    @State private var selectedPeriod: TimePeriod = .am
    
    enum TimePeriod: String, CaseIterable {
        case am = "AM"
        case pm = "PM"
    }
    
    private var selectedTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(selectedDate)
    }
    
    private var dateDisplayString: String {
        if isToday {
            return "Today"
        } else if isTomorrow {
            return "Tomorrow"
        } else {
            return selectedDateString
        }
    }
    
    private var hours: [Int] {
        Array(1...12)
    }
    
    private var minutes: [Int] {
        Array(stride(from: 0, to: 60, by: 5))
    }
    
    private var periods: [TimePeriod] {
        TimePeriod.allCases
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.lg) {
            // Header
            HStack {
                Text(NSLocalizedString("when", comment: "When question for time selection"))
                    .font(LiquidDesignSystem.Typography.headlineFont)
                    .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Button(NSLocalizedString("more", comment: "More button for time selection")) {
                    withAnimation(LiquidDesignSystem.Animation.smooth) {
                        showingTimePicker.toggle()
                    }
                    if showingTimePicker {
                        loadCurrentTime()
                    }
                }
                .font(LiquidDesignSystem.Typography.displayMedium.monospaced())
                .foregroundStyle(LiquidDesignSystem.Colors.accent)
            }
            
            if showingTimePicker {
                // Expanded view with glass surface
                VStack(spacing: LiquidDesignSystem.Spacing.lg) {
                    // Quick date selection
                    VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.sm) {
                        Text(NSLocalizedString("quick_select", comment: "Quick select section title"))
                            .font(LiquidDesignSystem.Typography.captionFont)
                            .fontWeight(.medium)
                            .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                        
                        HStack(spacing: LiquidDesignSystem.Spacing.sm) {
                            quickDateButton(title: NSLocalizedString("today", comment: "Today button"), isSelected: isToday) {
                                quickDateSelection(0)
                            }
                            
                            quickDateButton(title: NSLocalizedString("tomorrow", comment: "Tomorrow button"), isSelected: isTomorrow) {
                                quickDateSelection(1)
                            }
                        }
                    }
                    
                    // Date picker
                    VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.xs) {
                        Text(NSLocalizedString("select_date", comment: "Select date label"))
                            .font(LiquidDesignSystem.Typography.captionFont)
                            .fontWeight(.medium)
                            .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                        
                        DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .tint(LiquidDesignSystem.Colors.accent)
                            .labelsHidden()
                            .onChange(of: selectedDate) { _, newDate in
                                selectDate(newDate)
                            }
                    }
                    
                    // Time picker
                    VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.xs) {
                        Text(NSLocalizedString("select_time", comment: "Select time label"))
                            .font(LiquidDesignSystem.Typography.captionFont)
                            .fontWeight(.medium)
                            .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                        
                        LiquidTimePickerView(
                            selectedHour: $selectedHour,
                            selectedMinute: $selectedMinute,
                            selectedPeriod: $selectedPeriod,
                            hours: hours,
                            minutes: minutes,
                            periods: periods
                        )
                        .onChange(of: selectedHour) { _, _ in updateStartTime() }
                        .onChange(of: selectedMinute) { _, _ in updateStartTime() }
                        .onChange(of: selectedPeriod) { _, _ in updateStartTime() }
                    }
                }
                .padding(LiquidDesignSystem.Spacing.lg)
                .glassSurface()
            } else {
                // Compact view
                VStack(spacing: LiquidDesignSystem.Spacing.sm) {
                    // Time display with gradient background
                    Button(action: {
                        withAnimation(LiquidDesignSystem.Animation.smooth) {
                            showingTimePicker.toggle()
                        }
                        if showingTimePicker {
                            loadCurrentTime()
                        }
                    }) {
                        Text(selectedTimeString)
                            .font(LiquidDesignSystem.Typography.titleLarge)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, LiquidDesignSystem.Spacing.md)
                            .background(LiquidDesignSystem.Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.lg))
                            .shadow(
                                color: LiquidDesignSystem.Colors.accent.opacity(0.4),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                    }
                    
                    // Date display
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(LiquidDesignSystem.Colors.accent)
                        Text(dateDisplayString)
                            .font(LiquidDesignSystem.Typography.subheadlineFont)
                            .fontWeight(.medium)
                            .foregroundStyle(LiquidDesignSystem.Colors.accent)
                        
                        Spacer()
                        
                        Button(NSLocalizedString("change", comment: "Change button for time selection")) {
                            withAnimation(LiquidDesignSystem.Animation.smooth) {
                                showingTimePicker.toggle()
                            }
                            if showingTimePicker {
                                loadCurrentTime()
                            }
                        }
                        .font(LiquidDesignSystem.Typography.captionFont)
                        .fontWeight(.medium)
                        .foregroundStyle(LiquidDesignSystem.Colors.accent)
                    }
                    .padding(LiquidDesignSystem.Spacing.md)
                    .glassSurface()
                }
            }
        }
    }
    
    private func quickDateButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(LiquidDesignSystem.Typography.subheadlineFont)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : LiquidDesignSystem.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LiquidDesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                        .fill(isSelected ? LiquidDesignSystem.Colors.accent : LiquidDesignSystem.Colors.glassBackground)
                )
        }
        .buttonStyle(LiquidButtonStyle(variant: isSelected ? .primary : .ghost))
    }
    
    // MARK: - Helper Functions
    private func updateStartTime() {
        let calendar = Calendar.current
        var hour24 = selectedHour
        
        if selectedPeriod == .pm && selectedHour != 12 {
            hour24 += 12
        } else if selectedPeriod == .am && selectedHour == 12 {
            hour24 = 0
        }
        
        if let newStartTime = calendar.date(bySettingHour: hour24,
                                            minute: selectedMinute,
                                            second: 0,
                                            of: selectedDate) {
            startTime = newStartTime
        }
    }
    
    private func loadCurrentTime() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)
        let minute = calendar.component(.minute, from: startTime)
        
        // Convert to 12-hour format
        if hour == 0 {
            selectedHour = 12
            selectedPeriod = .am
        } else if hour < 12 {
            selectedHour = hour
            selectedPeriod = .am
        } else if hour == 12 {
            selectedHour = 12
            selectedPeriod = .pm
        } else {
            selectedHour = hour - 12
            selectedPeriod = .pm
        }
        
        // Round to nearest 5 minutes
        selectedMinute = (minute / 5) * 5
    }
    
    private func selectDate(_ date: Date) {
        selectedDate = date
        updateStartTime()
    }
    
    private func quickDateSelection(_ daysOffset: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: daysOffset, to: Date()) {
            selectDate(newDate)
        }
    }
}

// MARK: - Time Picker View

struct LiquidTimePickerView: View {
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var selectedPeriod: LiquidTaskTimeSelector.TimePeriod
    
    let hours: [Int]
    let minutes: [Int]
    let periods: [LiquidTaskTimeSelector.TimePeriod]
    
    var body: some View {
        HStack(spacing: 0) {
            // Hours column
            Picker("Hour", selection: $selectedHour) {
                ForEach(hours, id: \.self) { hour in
                    Text("\(hour)")
                        .tag(hour)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            .clipped()
            
            // Minutes column
            Picker("Minute", selection: $selectedMinute) {
                ForEach(minutes, id: \.self) { minute in
                    Text(String(format: "%02d", minute))
                        .tag(minute)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            .clipped()
            
            // AM/PM column
            Picker("Period", selection: $selectedPeriod) {
                ForEach(periods, id: \.self) { period in
                    Text(period.rawValue)
                        .tag(period)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                .fill(LiquidDesignSystem.Colors.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                .strokeBorder(
                    LiquidDesignSystem.Colors.accent.opacity(0.2),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    @Previewable @State var date = Date()
    @Previewable @State var time = Date()
    
    return LiquidTaskTimeSelector(
        selectedDate: $date,
        startTime: $time
    )
    .padding()
    .background(LiquidDesignSystem.Colors.meshGradientBackground)
}

