import SwiftUI

struct LiquidTaskRepeatSelector: View {
    @Binding var repeatRule: RepeatRule
    
    let repeatOptions = RepeatRule.allCases
    
    private var headerView: some View {
        HStack {
            Text(NSLocalizedString("how_often", comment: "How often question for repeat selection"))
                .font(LiquidDesignSystem.Typography.headlineSmall)
                .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
            
            Spacer()
        }
    }
    
    private func buttonView(for option: RepeatRule) -> some View {
        let isSelected = repeatRule == option
        
        return Button(action: {
            withAnimation(LiquidDesignSystem.Animation.smooth) {
                repeatRule = option
            }
        }) {
            buttonContent(for: option, isSelected: isSelected)
        }
        .buttonStyle(LiquidButtonStyle(variant: isSelected ? .primary : .ghost))
    }
    
    private func buttonContent(for option: RepeatRule, isSelected: Bool) -> some View {
        Text(option.displayName)
            .font(LiquidDesignSystem.Typography.caption)
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : LiquidDesignSystem.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, LiquidDesignSystem.Spacing.sm)
            .padding(.vertical, LiquidDesignSystem.Spacing.sm)
            .background(buttonBackground(isSelected: isSelected))
            .shadow(
                color: isSelected ? LiquidDesignSystem.Colors.primary.opacity(0.3) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
    }
    
    private func buttonBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.lg)
            .fill(
                isSelected
                ? AnyShapeStyle(LiquidDesignSystem.Gradients.primaryGradient)
                : AnyShapeStyle(LiquidDesignSystem.Colors.glassBackground)
            )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.lg) {
            // Header
            headerView
            
            // Grid of repeat options
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: LiquidDesignSystem.Spacing.sm
            ) {
                ForEach(repeatOptions, id: \.self) { option in
                    buttonView(for: option)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var repeatRule = RepeatRule.none
    
    return LiquidTaskRepeatSelector(repeatRule: $repeatRule)
        .padding()
        .background(LiquidDesignSystem.Colors.meshGradientBackground)
}

