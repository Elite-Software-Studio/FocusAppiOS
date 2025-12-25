import SwiftUI

/// Modern Floating Action Button with Liquid design
struct LiquidFloatingActionButton: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed: Bool = false
    
    let action: () -> Void
    let icon: String
    let size: CGFloat
    
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
        Button(action: action) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LiquidDesignSystem.Colors.primary.opacity(0.3),
                                LiquidDesignSystem.Colors.primary.opacity(0)
                            ],
                            center: .center,
                            startRadius: size / 3,
                            endRadius: size / 2 + 10
                        )
                    )
                    .frame(width: size + 20, height: size + 20)
                    .blur(radius: 10)
                    .opacity(isPressed ? 0.5 : 1.0)
                
                // Main button
                Circle()
                    .fill(LiquidDesignSystem.Gradients.primaryGradient)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color.white.opacity(0.3),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: LiquidDesignSystem.Colors.primary.opacity(0.4),
                        radius: isPressed ? 12 : 20,
                        x: 0,
                        y: isPressed ? 4 : 8
                    )
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(FloatingButtonPressStyle(isPressed: $isPressed))
    }
}

/// Custom button style for press feedback
struct FloatingButtonPressStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(LiquidDesignSystem.Animation.quick, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LiquidDesignSystem.Gradients.meshBackground(.light)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                LiquidFloatingActionButton {
                    print("FAB tapped")
                }
                .padding(20)
            }
        }
    }
}

