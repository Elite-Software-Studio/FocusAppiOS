import SwiftUI

struct TaskDurationSelector: View {
    @Binding var duration: Int
    
    // Base quick options
    private let baseDurations = [15, 30, 45, 60, 90, 120, 240]
    // Extended hour options in minutes (3h to 12h)
    private let extendedHours: [Int] = Array(stride(from: 6, through: 12, by: 2)).map { $0 * 60 }
    
    @State private var showMoreSheet: Bool = false
    @State private var showExtendedRow: Bool = false
    
    private func durationDisplayText(_ minutes: Int) -> String {
        switch minutes {
        case 15: return "15m"
        case 30: return "30m"
        case 45: return "45m"
        case 60: return "1h"
        case 90: return "1.5h"
        case 120: return "2h"
        case 240: return "4h"
        default:
            if minutes < 60 {
                return "\(minutes)m"
            } else {
                let hours = minutes / 60
                let remainingMinutes = minutes % 60
                if remainingMinutes == 0 {
                    return "\(hours)h"
                } else {
                    return "\(hours)h \(remainingMinutes)m"
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(LanguageManager.localized("how_long", comment: "How long question for duration selection"))
                    .font(AppFonts.headline())
                    .foregroundColor(.gray)
                Spacer()
                Button(showExtendedRow ? LanguageManager.localized("hide", comment: "Hide button") : LanguageManager.localized("more", comment: "More button")) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        showExtendedRow.toggle()
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.pink)
                .buttonStyle(PlainButtonStyle())
                .contextMenu {
                    Button(LanguageManager.localized("custom", comment: "Custom duration option")) { showMoreSheet = true }
                }
            }
            
            // Quick row
            durationRow(options: baseDurations)
            
            // Extended hours row (3h…12h)
            if showExtendedRow {
                durationRow(options: extendedHours)
            }
        }
        .sheet(isPresented: $showMoreSheet) {
            DurationPickerSheet(duration: $duration)
        }
    }
    
    private func durationRow(options: [Int]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, minutes in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { duration = minutes }
                }) {
                    Text(durationDisplayText(minutes))
                        .font(AppFonts.caption())
                        .foregroundColor(duration == minutes ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(duration == minutes ? Color.pink : Color.gray.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                if index < options.count - 1 {
                    Spacer().frame(width: 8)
                }
            }
        }
    }
}

private struct DurationPickerSheet: View {
    @Binding var duration: Int
    @Environment(\.dismiss) private var dismiss
    
    // 5 minutes to 12 hours, in 5m steps
    private let allOptions: [Int] = Array(stride(from: 5, through: 12 * 60, by: 5))
    @State private var selected: Int = 60
    
    private func label(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(LanguageManager.localized("minutes", comment: "Minutes section title")) {
                    Picker("Minutes", selection: $selected) {
                        ForEach(allOptions, id: \.self) { m in
                            Text(label(m)).tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .labelsHidden()
                }
            }
            .navigationTitle(LanguageManager.localized("select_duration", comment: "Select duration navigation title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LanguageManager.localized("cancel", comment: "Cancel button")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LanguageManager.localized("set", comment: "Set button")) {
                        duration = selected
                        dismiss()
                    }
                }
            }
            .onAppear { selected = duration }
        }
    }
}

#Preview {
    @State var duration = 90
    return TaskDurationSelector(duration: $duration)
}
