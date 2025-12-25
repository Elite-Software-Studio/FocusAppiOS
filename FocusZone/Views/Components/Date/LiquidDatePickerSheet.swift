import SwiftUI

struct LiquidDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var currentWeekOffset: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LiquidDesignSystem.Colors.meshGradientBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: LiquidDesignSystem.Spacing.xl) {
                        // Title
                        Text(NSLocalizedString("select_date", comment: "Select date title"))
                            .font(LiquidDesignSystem.Typography.titleLarge)
                            .fontWeight(.bold)
                            .foregroundStyle(LiquidDesignSystem.Colors.textPrimary)
                            .padding(.top, LiquidDesignSystem.Spacing.lg)
                        
                        // Calendar picker with glass surface
                        VStack(spacing: 0) {
                            DatePicker(
                                NSLocalizedString("select_date", comment: "Select date picker label"),
                                selection: $selectedDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            .tint(LiquidDesignSystem.Colors.accent)
                            .labelsHidden()
                            .padding(LiquidDesignSystem.Spacing.lg)
                        }
                        .glassSurface()
                        
                        // Quick select section
                        VStack(spacing: LiquidDesignSystem.Spacing.md) {
                            Text(NSLocalizedString("quick_select", comment: "Quick select title"))
                                .font(LiquidDesignSystem.Typography.headlineFont)
                                .foregroundStyle(LiquidDesignSystem.Colors.textPrimary)
                            
                            HStack(spacing: LiquidDesignSystem.Spacing.sm) {
                                quickDateButton(
                                    title: NSLocalizedString("today", comment: "Today button"),
                                    date: Date(),
                                    icon: "sun.max.fill"
                                )
                                quickDateButton(
                                    title: NSLocalizedString("tomorrow", comment: "Tomorrow button"),
                                    date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                                    icon: "sunrise.fill"
                                )
                                quickDateButton(
                                    title: NSLocalizedString("next_week", comment: "Next week button"),
                                    date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date(),
                                    icon: "calendar.badge.plus"
                                )
                            }
                        }
                        .padding(LiquidDesignSystem.Spacing.lg)
                        .glassSurface()
                        
                        Spacer(minLength: LiquidDesignSystem.Spacing.xl)
                    }
                    .padding(.horizontal, LiquidDesignSystem.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                    .foregroundStyle(LiquidDesignSystem.Colors.accent)
                    .fontWeight(.medium)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done", comment: "Done button")) {
                        currentWeekOffset = 0
                        dismiss()
                    }
                    .foregroundStyle(LiquidDesignSystem.Colors.accent)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func quickDateButton(title: String, date: Date, icon: String) -> some View {
        Button(action: {
            withAnimation(LiquidDesignSystem.Animation.quick) {
                selectedDate = date
            }
            currentWeekOffset = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }) {
            VStack(spacing: LiquidDesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(LiquidDesignSystem.Colors.accent)
                
                Text(title)
                    .font(LiquidDesignSystem.Typography.captionFont)
                    .fontWeight(.medium)
                    .foregroundStyle(LiquidDesignSystem.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LiquidDesignSystem.Spacing.md)
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
        .buttonStyle(LiquidButtonStyle(variant: .ghost))
    }
}

#Preview {
    LiquidDatePickerSheet(
        selectedDate: .constant(Date()),
        currentWeekOffset: .constant(0)
    )
}

