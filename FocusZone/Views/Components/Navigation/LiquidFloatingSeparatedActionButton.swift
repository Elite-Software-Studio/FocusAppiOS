import SwiftUI

/// Floating separated action button (FAB) inspired by modern app designs
/// Visually separated from the tab bar with elevation and glass effects
struct LiquidFloatingSeparatedActionButton: View {
    let action: () -> Void
    let icon: String
    let size: CGFloat
    
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    init(
        icon: String = "plus",
        size: CGFloat = 60,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            isPressed = true
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }) {
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        LiquidDesignSystem.Gradients.primaryGradient.opacity(0.3)
                    )
                    .frame(width: size + 8, height: size + 8)
                    .blur(radius: 8)
                    .opacity(isPressed ? 0.8 : 1.0)
                
                // Main button surface
                Circle()
                    .fill(LiquidDesignSystem.Gradients.primaryGradient)
                    .frame(width: size, height: size)
                
                // Glass overlay for depth
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .shadow(
            color: LiquidDesignSystem.Colors.primary.opacity(colorScheme == .dark ? 0.6 : 0.4),
            radius: isPressed ? 15 : 20,
            x: 0,
            y: isPressed ? 8 : 12
        )
        .animation(LiquidDesignSystem.Animation.quickSpring, value: isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LiquidDesignSystem.Gradients.meshBackground(.light)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            LiquidFloatingSeparatedActionButton {
                print("Action button tapped!")
            }
            .padding(.bottom, 100)
        }
    }
}

