import SwiftUI

// MARK: - Liquid Design System
// A modern, glassmorphic design system for Focus Zone

/// Centralized design tokens and styles for the Liquid/Glass design system
struct LiquidDesignSystem {
    
    // MARK: - Colors
    
    struct Colors {
        // Primary Palette
        static let primary = Color(hex: "#4A90E2") ?? .blue
        static let primaryLight = Color(hex: "#6BA4E7") ?? .blue
        static let primaryDark = Color(hex: "#357ABD") ?? .blue
        
        // Neutrals
        static let background = Color(hex: "#F8F9FA") ?? Color(.systemBackground)
        static let backgroundDark = Color(hex: "#0A0B0D") ?? Color(.systemBackground)
        
        static let surface = Color(hex: "#FFFFFF") ?? Color(.secondarySystemBackground)
        static let surfaceDark = Color(hex: "#1C1D1F") ?? Color(.secondarySystemBackground)
        
        static let surfaceSecondary = Color(hex: "#F5F6F7") ?? Color(.tertiarySystemBackground)
        static let surfaceSecondaryDark = Color(hex: "#2A2B2D") ?? Color(.tertiarySystemBackground)
        
        // Text
        static let textPrimary = Color(hex: "#1A1B1E") ?? Color(.label)
        static let textPrimaryDark = Color(hex: "#FFFFFF") ?? Color(.label)
        
        static let textSecondary = Color(hex: "#6B7280") ?? Color(.secondaryLabel)
        static let textSecondaryDark = Color(hex: "#9CA3AF") ?? Color(.secondaryLabel)
        
        static let textTertiary = Color(hex: "#9CA3AF") ?? Color(.tertiaryLabel)
        static let textTertiaryDark = Color(hex: "#6B7280") ?? Color(.tertiaryLabel)
        
        // Accents
        static let success = Color(hex: "#10B981") ?? .green
        static let warning = Color(hex: "#F59E0B") ?? .orange
        static let error = Color(hex: "#EF4444") ?? .red
        static let info = Color(hex: "#3B82F6") ?? .blue
        static let  accent = Color(hex: "#F59E0B") ?? .blue
        
        // Glass Effects
        static let glassBackground = Color.white.opacity(0.15)
        static let glassBackgroundDark = Color.white.opacity(0.05)
        
        static let glassBorder = Color.white.opacity(0.2)
        static let glassBorderDark = Color.white.opacity(0.1)
        
        // Adaptive colors that respond to color scheme
        static func adaptiveBackground(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? backgroundDark : background
        }
        
        static func adaptiveSurface(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? surfaceDark : surface
        }
        
        static func adaptiveSurfaceSecondary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? surfaceSecondaryDark : surfaceSecondary
        }
        
        static func adaptiveTextPrimary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? textPrimaryDark : textPrimary
        }
        
        static func adaptiveTextSecondary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? textSecondaryDark : textSecondary
        }
        
        static func adaptiveTextTertiary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? textTertiaryDark : textTertiary
        }
        
        static func adaptiveGlassBackground(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? glassBackgroundDark : glassBackground
        }
        
        static func adaptiveGlassBorder(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? glassBorderDark : glassBorder
        }
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Display
        static let displayLarge = Font.system(size: 57, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 45, weight: .semibold, design: .rounded)
        static let displaySmall = Font.system(size: 36, weight: .semibold, design: .rounded)
        
        // Headline
        static let headlineLarge = Font.system(size: 32, weight: .bold, design: .rounded)
        static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let headlineFont = Font.system(size: 18, weight: .semibold, design: .rounded)
        
        static let subheadlineFont = Font.system(size: 16, weight: .semibold, design: .rounded)
        
        // Title
        static let titleLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let titleMedium = Font.system(size: 18, weight: .medium, design: .rounded)
        static let titleSmall = Font.system(size: 16, weight: .medium, design: .rounded)
        
        // Body
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        static let bodyFont  = Font.system(size: 14, weight: .regular, design: .default)
        
        // Label
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)
        
        // Caption
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        static let captionBold = Font.system(size: 11, weight: .semibold, design: .default)
        static let captionFont = Font.system(size: 11, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999
    }
    
    // MARK: - Elevation / Shadows
    
    struct Elevation {
        static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
        
        static let low = Shadow(
            color: Color.black.opacity(0.04),
            radius: 2,
            x: 0,
            y: 1
        )
        
        static let medium = Shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let high = Shadow(
            color: Color.black.opacity(0.12),
            radius: 16,
            x: 0,
            y: 8
        )
        
        static let dramatic = Shadow(
            color: Color.black.opacity(0.16),
            radius: 24,
            x: 0,
            y: 12
        )
        
        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Blur
    
    struct Blur {
        static let light: CGFloat = 10
        static let medium: CGFloat = 20
        static let heavy: CGFloat = 40
        static let extreme: CGFloat = 60
    }
    
    // MARK: - Animation
    
    struct Animation {
        static let quick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let gentle = SwiftUI.Animation.spring(response: 0.7, dampingFraction: 0.9)
        static let fluid = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.75)
        
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.3)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.4)
    }
    
    // MARK: - Opacity
    
    struct Opacity {
        static let invisible: Double = 0
        static let subtle: Double = 0.05
        static let light: Double = 0.1
        static let soft: Double = 0.2
        static let medium: Double = 0.4
        static let strong: Double = 0.6
        static let heavy: Double = 0.8
        static let full: Double = 1.0
    }
}

// MARK: - Liquid Gradients

extension LiquidDesignSystem {
    struct Gradients {
        // Primary gradients
        static let primaryGradient = LinearGradient(
            colors: [
                LiquidDesignSystem.Colors.primary,
                LiquidDesignSystem.Colors.primaryLight
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let primarySubtle = LinearGradient(
            colors: [
                LiquidDesignSystem.Colors.primary.opacity(0.1),
                LiquidDesignSystem.Colors.primaryLight.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Glass gradients
        static func glassGradient(_ colorScheme: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25),
                    Color.white.opacity(colorScheme == .dark ? 0.04 : 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // Mesh gradients for backgrounds
        static func meshBackground(_ colorScheme: ColorScheme) -> LinearGradient {
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [
                        Color(hex: "#0A0B0D") ?? .black,
                        Color(hex: "#151618") ?? .black,
                        Color(hex: "#0A0B0D") ?? .black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color(hex: "#F8F9FA") ?? .white,
                        Color(hex: "#FFFFFF") ?? .white,
                        Color(hex: "#F5F6F7") ?? .white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Color Extension for View Helpers

extension LiquidDesignSystem.Colors {
    /// Adaptive mesh gradient background that responds to color scheme
    static var meshGradientBackground: some View {
        MeshGradientBackgroundView()
    }
}

// MARK: - Helper Views

private struct MeshGradientBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        LiquidDesignSystem.Gradients.meshBackground(colorScheme)
    }
}

