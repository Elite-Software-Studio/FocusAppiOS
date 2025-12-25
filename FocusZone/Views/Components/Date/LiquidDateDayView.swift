import SwiftUI

struct LiquidDateDayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let isSelected: Bool
    let isToday: Bool
    let hasTask: Bool
    let taskCount: Int
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Weekday label
            Text(shortWeekdayString(from: date))
                .font(LiquidDesignSystem.Typography.captionFont)
                .fontWeight(.medium)
                .foregroundStyle(
                    isSelected 
                        ? LiquidDesignSystem.Colors.accent
                        : LiquidDesignSystem.Colors.textSecondary
                )
            
            // Day circle
            ZStack {
                // Glass surface with glow
                Circle()
                    .fill(
                        isSelected
                            ? LiquidDesignSystem.Colors.accent
                            : LiquidDesignSystem.Colors.glassBackground
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(
                                isToday && !isSelected 
                                    ? LiquidDesignSystem.Colors.accent.opacity(0.5)
                                    : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isSelected 
                            ? LiquidDesignSystem.Colors.accent.opacity(0.4)
                            : Color.black.opacity(0.05),
                        radius: isSelected ? 12 : 4,
                        x: 0,
                        y: isSelected ? 6 : 2
                    )
                
                // Day number
                Text(dayString(from: date))
                    .font(LiquidDesignSystem.Typography.bodyLarge.bold())
                    .fontWeight(isSelected ? .bold : .semibold)
                    .foregroundStyle(textColor)
                
                // Task indicator
                if hasTask && !isSelected {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(LiquidDesignSystem.Colors.accent)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Text("\(taskCount)")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 2, y: 2)
                        }
                    }
                    .frame(width: 48, height: 48)
                }
            }
        }
        .padding(.vertical, 4)
        .scaleEffect(isPressed ? 0.9 : (isSelected ? 1.05 : 1.0))
        .animation(LiquidDesignSystem.Animation.smooth, value: isSelected)
        .animation(LiquidDesignSystem.Animation.quick, value: isPressed)
        .onTapGesture {
            isPressed = true
            
            withAnimation(LiquidDesignSystem.Animation.smooth) {
                selectedDate = date
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
    
    // MARK: - Computed Properties
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return LiquidDesignSystem.Colors.accent
        } else {
            return LiquidDesignSystem.Colors.textPrimary
        }
    }
    
    // MARK: - Helpers
    private func shortWeekdayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

#Preview {
    HStack(spacing: 16) {
        LiquidDateDayView(
            date: Date(),
            selectedDate: .constant(Date()),
            isSelected: true,
            isToday: true,
            hasTask: false,
            taskCount: 0
        )
        
        LiquidDateDayView(
            date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            selectedDate: .constant(Date()),
            isSelected: false,
            isToday: false,
            hasTask: true,
            taskCount: 3
        )
        
        LiquidDateDayView(
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            selectedDate: .constant(Date()),
            isSelected: false,
            isToday: false,
            hasTask: false,
            taskCount: 0
        )
    }
    .padding()
    .background(LiquidDesignSystem.Colors.meshGradientBackground)
}

