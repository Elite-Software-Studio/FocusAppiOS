import SwiftUI

struct LiquidTaskIconPicker: View {
    @Binding var selectedIcon: String
    
    let icons = ["🖥️", "📚", "🎨", "🎮", "🏋️‍♀️", "💼", "🍽️", "🌙", "🧘", "⏰"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.lg) {
            // Header
            HStack {
                Text(NSLocalizedString("what_type_of_task", comment: "What type of task question"))
                    .font(LiquidDesignSystem.Typography.headlineFont)
                    .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                
                Spacer()
            }
            
            // Icon grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 5),
                spacing: LiquidDesignSystem.Spacing.md
            ) {
                ForEach(icons, id: \.self) { icon in
                    LiquidIconButton(
                        icon: icon,
                        isSelected: selectedIcon == icon,
                        action: {
                            withAnimation(LiquidDesignSystem.Animation.quick) {
                                selectedIcon = icon
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Component

struct LiquidIconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glass background
                Circle()
                    .fill(
                        isSelected
                            ? LiquidDesignSystem.Colors.glassBackground
                            : LiquidDesignSystem.Colors.glassBackground.opacity(0.5)
                    )
                    .frame(width: 56, height: 56)
                
                // Icon text
                Text(icon)
                    .font(.system(size: 28))
                
                // Selection indicator
                if isSelected {
                    Circle()
                        .stroke(LiquidDesignSystem.Colors.accent, lineWidth: 3)
                        .frame(width: 60, height: 60)
                        .shadow(
                            color: LiquidDesignSystem.Colors.accent.opacity(0.4),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(LiquidDesignSystem.Animation.quick, value: isSelected)
    }
}

#Preview {
    @Previewable @State var selectedIcon: String = "🖥️"
    
    return VStack {
        LiquidTaskIconPicker(selectedIcon: $selectedIcon)
        
        Text("Selected: \(selectedIcon)")
            .padding()
    }
    .padding()
    .background(LiquidDesignSystem.Colors.meshGradientBackground)
}

