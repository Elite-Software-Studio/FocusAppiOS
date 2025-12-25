import SwiftUI

struct LiquidDateSelector: View {
    @Binding var selectedDate: Date

    var body: some View {
        DatePicker(
            "Select Date",
            selection: $selectedDate,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .tint(LiquidDesignSystem.Colors.accent)
        .padding(LiquidDesignSystem.Spacing.lg)
        .glassSurface()
    }
}

#Preview {
    LiquidDateSelector(selectedDate: .constant(Date()))
        .padding()
        .background(LiquidDesignSystem.Colors.meshGradientBackground)
}

