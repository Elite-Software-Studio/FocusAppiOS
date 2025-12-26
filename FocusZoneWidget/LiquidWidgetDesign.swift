import SwiftUI

/// Lightweight design tokens for Widget Extension (no complex dependencies)
/// This is a simplified subset of LiquidDesignSystem that can be used in widget extensions
enum LiquidWidgetDesign {
    
    // MARK: - Colors
    enum Colors {
        static let primary = Color(red: 0.4, green: 0.6, blue: 1.0) // Blue accent
        static let primaryLight = Color(red: 0.5, green: 0.7, blue: 1.0)
        
        static let success = Color.green
        static let warning = Color.orange
        
        // Glass backgrounds
        static func glassBackground(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.1)
                : Color.white.opacity(0.5)
        }
        
        static func glassBorder(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.2)
                : Color.white.opacity(0.3)
        }
        
        // Text colors
        static func textPrimary(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? .white : Color(white: 0.1)
        }
        
        static func textSecondary(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.7)
                : Color(white: 0.4)
        }
        
        // Gradients
        static let focusGradient = LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.6, blue: 1.0),
                Color(red: 0.5, green: 0.7, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.02, green: 0.02, blue: 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.96, blue: 0.98),
                        Color(red: 0.92, green: 0.94, blue: 0.97)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    // MARK: - Typography
    enum Typography {
        static let largeTitleFont = Font.system(size: 28, weight: .bold, design: .rounded)
        static let titleFont = Font.system(size: 24, weight: .bold, design: .rounded)
        static let headlineFont = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let bodyFont = Font.system(size: 15, weight: .regular, design: .rounded)
        static let captionFont = Font.system(size: 12, weight: .medium, design: .rounded)
        static let caption2Font = Font.system(size: 10, weight: .medium, design: .rounded)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
    
    // MARK: - Shadows
    enum Shadow {
        static let small = Color.black.opacity(0.1)
        static let medium = Color.black.opacity(0.15)
        static let large = Color.black.opacity(0.2)
    }
}

/// Glass surface modifier for widgets
struct WidgetGlassSurface: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: LiquidWidgetDesign.CornerRadius.lg)
                    .fill(LiquidWidgetDesign.Colors.glassBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LiquidWidgetDesign.CornerRadius.lg)
                    .strokeBorder(
                        LiquidWidgetDesign.Colors.glassBorder(for: colorScheme),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: LiquidWidgetDesign.Shadow.small,
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

extension View {
    func widgetGlassSurface() -> some View {
        modifier(WidgetGlassSurface())
    }
}

