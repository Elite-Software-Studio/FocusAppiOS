import SwiftUI

struct LiquidTaskRepeatSelector: View {
    @Binding var repeatRule: RepeatRule
    
    let repeatOptions = RepeatRule.allCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.lg) {
            // Header
            HStack {
                Text(NSLocalizedString("how_often", comment: "How often question for repeat selection"))
                    .font(LiquidDesignSystem.Typography.headlineFont)
                    .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                
                Spacer()
            }
            
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
                    Button(action: {
                        withAnimation(LiquidDesignSystem.Animation.spring) {
                            repeatRule = option
                        }
                    }) {
                        Text(option.displayName)
                            .font(LiquidDesignSystem.Typography.captionFont)
                            .fontWeight(.medium)
                            .foregroundColor(
                                repeatRule == option
                                    ? .white
                                    : LiquidDesignSystem.Colors.textPrimary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, LiquidDesignSystem.Spacing.sm)
                            .padding(.vertical, LiquidDesignSystem.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.lg)
                                    .fill(
                                        repeatRule == option
                                            ? LiquidDesignSystem.Colors.accentGradient
                                            : LiquidDesignSystem.Colors.glassBackground
                                    )
                            )
                            .shadow(
                                color: repeatRule == option
                                    ? LiquidDesignSystem.Colors.accent.opacity(0.3)
                                    : Color.clear,
                                radius: repeatRule == option ? 8 : 0,
                                x: 0,
                                y: repeatRule == option ? 4 : 0
                            )
                    }
                    .buttonStyle(LiquidButtonStyle(variant: repeatRule == option ? .primary : .ghost))
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

