import SwiftUI

struct TaskTimeSelector: View {
    @Binding var selectedDate: Date
    @Binding var startTime: Date
    @State private var showingTimeSlots: Bool = false
    @State private var showingDatePicker: Bool = false
    
    private var timeSlots: [String] {
        generateTimeSlots(for: selectedDate)
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
    
    private func generateTimeSlots(for date: Date) -> [String] {
        var slots: [String] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let calendar = Calendar.current
        let startOfSelectedDay = calendar.startOfDay(for: date)
        let now = Date()
        
        // If selecting today, start from current time + 15 minutes
        // If selecting future date, start from 6:00 AM
        var startHour: Int
        var startMinute: Int
        
        if calendar.isDateInToday(date) {
            let currentHour = calendar.component(.hour, from: now)
            let currentMinute = calendar.component(.minute, from: now)
            startHour = currentHour
            startMinute = ((currentMinute / 15) + 1) * 15 // Next 15-minute slot
            if startMinute >= 60 {
                startHour += 1
                startMinute = 0
            }
        } else {
            startHour = 6
            startMinute = 0
        }
        
        // Generate time slots from start time to 11:45 PM in 15-minute intervals
        for hour in startHour...23 {
            let minuteRange = hour == startHour ? stride(from: startMinute, to: 60, by: 15) : stride(from: 0, to: 60, by: 15)
            for minute in minuteRange {
                if let timeSlot = calendar.date(byAdding: .hour, value: hour, to: startOfSelectedDay),
                   let finalTime = calendar.date(byAdding: .minute, value: minute, to: timeSlot) {
                    slots.append(formatter.string(from: finalTime))
                }
            }
        }
        
        return slots
    }
    
    private func selectTime(_ timeString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        if let time = formatter.date(from: timeString) {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            if let newStartTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                  minute: timeComponents.minute ?? 0,
                  second: 0,
                  of: selectedDate) {
                startTime = newStartTime
            }
        }
    }
    
    private func selectDate(_ date: Date) {
        selectedDate = date
        // Update startTime to maintain the same time on the new date
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        if let newStartTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
              minute: timeComponents.minute ?? 0,
              second: 0,
              of: date) {
            startTime = newStartTime
        }
    }
    
    private func quickDateSelection(_ daysOffset: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: daysOffset, to: Date()) {
            selectDate(newDate)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(LanguageManager.localized("when", comment: "When question for time selection"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                  
                Spacer()
                
                Button(LanguageManager.localized("more", comment: "More button for time selection")) {
                    showingTimeSlots.toggle()
                }
                .font(.system(size: 16))
                .foregroundColor(.blue)
            }
            
            if showingTimeSlots {
                VStack(spacing: 16) {
                    // Quick date selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LanguageManager.localized("quick_select", comment: "Quick select section title"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Button(LanguageManager.localized("today", comment: "Today button")) {
                                quickDateSelection(0)
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isToday ? .white : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isToday ? Color.blue : Color.blue.opacity(0.1))
                            )
                            
                            Button(LanguageManager.localized("tomorrow", comment: "Tomorrow button")) {
                                quickDateSelection(1)
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isTomorrow ? .white : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isTomorrow ? Color.blue : Color.blue.opacity(0.1))
                            )
                            
                            Button(LanguageManager.localized("next_week", comment: "Next week button")) {
                                quickDateSelection(7)
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
                    
                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LanguageManager.localized("select_date", comment: "Select date label"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                            .onChange(of: selectedDate) { newDate in
                                selectDate(newDate)
                            }
                    }
                    
                    // Time slots
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LanguageManager.localized("select_time", comment: "Select time label"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(timeSlots, id: \.self) { time in
                                    Button(action: {
                                        selectTime(time)
                                    }) {
                                        Text(time)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(time == selectedTimeString ? .white : .primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(time == selectedTimeString ? Color.blue : Color.gray.opacity(0.1))
                                            )
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    
                }
            } else {
                // Compact view
                VStack(spacing: 12) {
                    // Time display
                    Text(selectedTimeString)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.blue)
                        )
                        .onTapGesture {
                            showingTimeSlots.toggle()
                        }
                    
                    // Date display
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(dateDisplayString)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        Spacer()
                        
                        Button(LanguageManager.localized("change", comment: "Change button for time selection")) {
                            showingTimeSlots.toggle()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
        }
    }
}

#Preview {
    @State var date = Date()
    @State var time = Date()
    
    return TaskTimeSelector(
        selectedDate: $date,
        startTime: $time
    )
}
