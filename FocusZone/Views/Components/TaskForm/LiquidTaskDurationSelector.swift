import SwiftUI

struct LiquidTaskDurationSelector: View {
    @Binding var duration: Int
    
    // Base quick options
    private let baseDurations = [15, 30, 45, 60, 90, 120, 240]
    // Extended hour options in minutes (6h to 12h)
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
        VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.lg) {
            // Header
            HStack {
                Text(NSLocalizedString("how_long", comment: "How long question for duration selection"))
                    .font(LiquidDesignSystem.Typography.headlineFont)
                    .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Button(showExtendedRow ? NSLocalizedString("hide", comment: "Hide button") : NSLocalizedString("more", comment: "More button")) {
                    withAnimation(LiquidDesignSystem.Animation.spring) {
                        showExtendedRow.toggle()
                    }
                }
                .font(LiquidDesignSystem.Typography.subheadlineFont)
                .foregroundStyle(LiquidDesignSystem.Colors.accent)
                .contextMenu {
                    Button(NSLocalizedString("custom", comment: "Custom duration option")) {
                        showMoreSheet = true
                    }
                }
            }
            
            // Duration options
            VStack(spacing: LiquidDesignSystem.Spacing.sm) {
                // Quick row
                durationRow(options: baseDurations)
                
                // Extended hours row (6h…12h)
                if showExtendedRow {
                    durationRow(options: extendedHours)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showMoreSheet) {
            LiquidDurationPickerSheet(duration: $duration)
        }
    }
    
    private func durationRow(options: [Int]) -> some View {
        HStack(spacing: LiquidDesignSystem.Spacing.xs) {
            ForEach(options, id: \.self) { minutes in
                Button(action: {
                    withAnimation(LiquidDesignSystem.Animation.spring) {
                        duration = minutes
                    }
                }) {
                    Text(durationDisplayText(minutes))
                        .font(LiquidDesignSystem.Typography.captionFont)
                        .fontWeight(.medium)
                        .foregroundColor(duration == minutes ? .white : LiquidDesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, LiquidDesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                                .fill(
                                    duration == minutes
                                        ? LiquidDesignSystem.Colors.accentGradient
                                        : LiquidDesignSystem.Colors.glassBackground
                                )
                        )
                        .shadow(
                            color: duration == minutes 
                                ? LiquidDesignSystem.Colors.accent.opacity(0.3)
                                : Color.clear,
                            radius: duration == minutes ? 8 : 0,
                            x: 0,
                            y: duration == minutes ? 4 : 0
                        )
                }
                .buttonStyle(LiquidButtonStyle(variant: duration == minutes ? .primary : .ghost))
            }
        }
    }
}

// MARK: - Duration Picker Sheet

private struct LiquidDurationPickerSheet: View {
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
            ZStack {
                LiquidDesignSystem.Colors.meshGradientBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("Minutes", selection: $selected) {
                        ForEach(allOptions, id: \.self) { m in
                            Text(label(m)).tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .padding(LiquidDesignSystem.Spacing.lg)
                    .glassSurface()
                    .padding(LiquidDesignSystem.Spacing.lg)
                    
                    Spacer()
                }
            }
            .navigationTitle(NSLocalizedString("select_duration", comment: "Select duration navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                    .foregroundStyle(LiquidDesignSystem.Colors.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("set", comment: "Set button")) {
                        duration = selected
                        dismiss()
                    }
                    .foregroundStyle(LiquidDesignSystem.Colors.accent)
                    .fontWeight(.semibold)
                }
            }
            .onAppear { selected = duration }
        }
    }
}

#Preview {
    @Previewable @State var duration = 90
    return LiquidTaskDurationSelector(duration: $duration)
        .padding()
        .background(LiquidDesignSystem.Colors.meshGradientBackground)
}

