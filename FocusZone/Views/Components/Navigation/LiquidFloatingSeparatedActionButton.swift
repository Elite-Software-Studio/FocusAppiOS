import SwiftUI
import UIKit

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
                // Outer glow halo (lighter)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LiquidDesignSystem.Colors.primary.opacity(0.3),
                                LiquidDesignSystem.Colors.primary.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.3,
                            endRadius: size * 0.6
                        )
                    )
                    .frame(width: size + 16, height: size + 16)
                    .blur(radius: 10)
                    .opacity(isPressed ? 0.7 : 1.0)
                
                // Base glass surface with lighter material
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: size, height: size)
                
                // Colored tint layer (more transparent)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LiquidDesignSystem.Colors.primary.opacity(0.85),
                                LiquidDesignSystem.Colors.primary.opacity(0.6)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )
                    .frame(width: size, height: size)
                
                // Glass highlight (top-left shine, lighter)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.15),
                                Color.clear
                            ],
                            center: .init(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: size * 0.6
                        )
                    )
                    .frame(width: size, height: size)
                
                // Subtle inner shadow for depth (lighter)
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: size - 2, height: size - 2)
                
                // Icon with enhanced shadow
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    .shadow(color: LiquidDesignSystem.Colors.primary.opacity(0.5), radius: 8, x: 0, y: 0)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.92 : 1.0)
        // Primary colored shadow for glow (lighter)
        .shadow(
            color: LiquidDesignSystem.Colors.primary.opacity(colorScheme == .dark ? 0.5 : 0.35),
            radius: isPressed ? 16 : 22,
            x: 0,
            y: isPressed ? 8 : 12
        )
        // Dark shadow for depth (lighter)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.18),
            radius: isPressed ? 10 : 18,
            x: 0,
            y: isPressed ? 6 : 10
        )
        // Subtle highlight shadow (from above, lighter)
        .shadow(
            color: Color.white.opacity(colorScheme == .dark ? 0.03 : 0.08),
            radius: 4,
            x: 0,
            y: -2
        )
        .animation(LiquidDesignSystem.Animation.quick, value: isPressed)
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

