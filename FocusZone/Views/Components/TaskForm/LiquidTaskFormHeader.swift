import SwiftUI

struct LiquidTaskFormHeader: View {
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text(NSLocalizedString("new_task", comment: "New task header title"))
                .font(LiquidDesignSystem.Typography.headlineLarge)
                .foregroundStyle(LiquidDesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Button(action: {
                DispatchQueue.main.async {
                    onDismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(LiquidDesignSystem.Colors.glassBackground)
                    )
            }
            .buttonStyle(LiquidButtonStyle(variant: .ghost))
        }
        .padding(.horizontal, LiquidDesignSystem.Spacing.lg)
        .padding(.top, LiquidDesignSystem.Spacing.lg)
        .padding(.bottom, LiquidDesignSystem.Spacing.xl)
    }
}

#Preview {
    LiquidTaskFormHeader(onDismiss: {})
        .background(LiquidDesignSystem.Gradients.meshBackground(.light))
}

