import SwiftUI

// MARK: - Glass Surface Modifier

struct GlassSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    var cornerRadius: CGFloat = LiquidDesignSystem.CornerRadius.lg
    var padding: CGFloat = LiquidDesignSystem.Spacing.md
    var blur: CGFloat = LiquidDesignSystem.Blur.medium
    var elevation: LiquidDesignSystem.Elevation.Shadow = LiquidDesignSystem.Elevation.medium
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LiquidDesignSystem.Colors.adaptiveGlassBackground(colorScheme))
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.ultraThinMaterial)
                        )
                    
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LiquidDesignSystem.Gradients.glassGradient(colorScheme))
                    
                    // Border highlight
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LiquidDesignSystem.Colors.adaptiveGlassBorder(colorScheme),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: elevation.color,
                radius: elevation.radius,
                x: elevation.x,
                y: elevation.y
            )
    }
}

// MARK: - Liquid Card Modifier

struct LiquidCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    var cornerRadius: CGFloat = LiquidDesignSystem.CornerRadius.lg
    var padding: CGFloat = LiquidDesignSystem.Spacing.md
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LiquidDesignSystem.Colors.adaptiveSurface(colorScheme))
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
    }
}

// MARK: - Liquid Button Style

struct LiquidButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    var size: Size = .medium
    var variant: Variant = .primary
    var isFullWidth: Bool = false
    
    enum Size {
        case small, medium, large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 48
            case .large: return 56
            }
        }
        
        var font: Font {
            switch self {
            case .small: return LiquidDesignSystem.Typography.labelMedium
            case .medium: return LiquidDesignSystem.Typography.titleSmall
            case .large: return LiquidDesignSystem.Typography.titleMedium
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return LiquidDesignSystem.Spacing.md
            case .medium: return LiquidDesignSystem.Spacing.lg
            case .large: return LiquidDesignSystem.Spacing.xl
            }
        }
    }
    
    enum Variant {
        case primary, secondary, tertiary, ghost
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(foregroundColor(configuration: configuration))
            .frame(height: size.height)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, size.horizontalPadding)
            .background(background(configuration: configuration))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(LiquidDesignSystem.Animation.quick, value: configuration.isPressed)
    }
    
    @ViewBuilder
    private func background(configuration: Configuration) -> some View {
        Group {
            switch variant {
            case .primary:
                RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                    .fill(LiquidDesignSystem.Gradients.primaryGradient)
                    .shadow(
                        color: LiquidDesignSystem.Colors.primary.opacity(0.3),
                        radius: configuration.isPressed ? 8 : 12,
                        x: 0,
                        y: configuration.isPressed ? 2 : 4
                    )
                
            case .secondary:
                RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                    .fill(LiquidDesignSystem.Colors.adaptiveSurfaceSecondary(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                            .strokeBorder(
                                LiquidDesignSystem.Colors.adaptiveGlassBorder(colorScheme),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: configuration.isPressed ? 4 : 8,
                        x: 0,
                        y: configuration.isPressed ? 1 : 2
                    )
                
            case .tertiary:
                RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                            .strokeBorder(
                                LiquidDesignSystem.Colors.adaptiveGlassBorder(colorScheme),
                                lineWidth: 1
                            )
                    )
                
            case .ghost:
                EmptyView()
            }
        }
    }
    
    private func foregroundColor(configuration: Configuration) -> Color {
        switch variant {
        case .primary:
            return .white
        case .secondary, .tertiary:
            return LiquidDesignSystem.Colors.adaptiveTextPrimary(colorScheme)
        case .ghost:
            return LiquidDesignSystem.Colors.primary
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass surface styling
    func glassSurface(
        cornerRadius: CGFloat = LiquidDesignSystem.CornerRadius.lg,
        padding: CGFloat = LiquidDesignSystem.Spacing.md,
        blur: CGFloat = LiquidDesignSystem.Blur.medium,
        elevation: LiquidDesignSystem.Elevation.Shadow = LiquidDesignSystem.Elevation.medium
    ) -> some View {
        modifier(GlassSurfaceModifier(
            cornerRadius: cornerRadius,
            padding: padding,
            blur: blur,
            elevation: elevation
        ))
    }
    
    /// Apply liquid card styling
    func liquidCard(
        cornerRadius: CGFloat = LiquidDesignSystem.CornerRadius.lg,
        padding: CGFloat = LiquidDesignSystem.Spacing.md
    ) -> some View {
        modifier(LiquidCardModifier(
            cornerRadius: cornerRadius,
            padding: padding
        ))
    }
    
    /// Apply liquid button style
    func liquidButton(
        size: LiquidButtonStyle.Size = .medium,
        variant: LiquidButtonStyle.Variant = .primary,
        isFullWidth: Bool = false
    ) -> some View {
        buttonStyle(LiquidButtonStyle(
            size: size,
            variant: variant,
            isFullWidth: isFullWidth
        ))
    }
}

// MARK: - Liquid Loading Indicator

struct LiquidLoadingIndicator: View {
    @State private var isAnimating = false
    @Environment(\.colorScheme) var colorScheme
    
    var size: CGFloat = 40
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    LiquidDesignSystem.Colors.adaptiveGlassBackground(colorScheme),
                    lineWidth: 4
                )
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LiquidDesignSystem.Gradients.primaryGradient,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1.0).repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .frame(width: size, height: size)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Liquid Badge

struct LiquidBadge: View {
    @Environment(\.colorScheme) var colorScheme
    
    let text: String
    let color: Color
    
    init(_ text: String, color: Color = LiquidDesignSystem.Colors.primary) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(LiquidDesignSystem.Typography.labelSmall)
            .foregroundColor(color)
            .padding(.horizontal, LiquidDesignSystem.Spacing.sm)
            .padding(.vertical, LiquidDesignSystem.Spacing.xxs)
            .background(
                Capsule()
                    .fill(color.opacity(colorScheme == .dark ? 0.2 : 0.1))
            )
    }
}

// MARK: - Liquid Progress Bar

struct LiquidProgressBar: View {
    @Environment(\.colorScheme) var colorScheme
    
    let progress: Double // 0.0 to 1.0
    let height: CGFloat
    
    init(progress: Double, height: CGFloat = 8) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(LiquidDesignSystem.Colors.adaptiveSurfaceSecondary(colorScheme))
                
                // Progress fill
                Capsule()
                    .fill(LiquidDesignSystem.Gradients.primaryGradient)
                    .frame(width: geometry.size.width * progress)
                    .animation(LiquidDesignSystem.Animation.smooth, value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Liquid Divider

struct LiquidDivider: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(LiquidDesignSystem.Colors.adaptiveGlassBorder(colorScheme))
            .frame(height: 1)
            .opacity(0.5)
    }
}

// MARK: - Fluid Animation Modifier

struct FluidScaleModifier: ViewModifier {
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(LiquidDesignSystem.Animation.quick, value: isPressed)
    }
}

extension View {
    func fluidScale(isPressed: Bool) -> some View {
        modifier(FluidScaleModifier(isPressed: isPressed))
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.3)
                    .offset(x: phase * geometry.size.width - geometry.size.width * 0.15)
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .onAppear {
                phase = 2
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

