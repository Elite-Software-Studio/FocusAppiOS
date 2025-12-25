import SwiftUI

/// Modern text field with Liquid design
struct LiquidTextField: View {
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    
    let title: String
    @Binding var text: String
    let placeholder: String
    var icon: String? = nil
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.xs) {
            // Label
            if !title.isEmpty {
                Text(title)
                    .font(LiquidDesignSystem.Typography.labelMedium)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextSecondary(colorScheme))
            }
            
            // Input field
            HStack(spacing: LiquidDesignSystem.Spacing.sm) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(LiquidDesignSystem.Typography.bodyMedium)
                        .foregroundColor(
                            isFocused
                                ? LiquidDesignSystem.Colors.primary
                                : LiquidDesignSystem.Colors.adaptiveTextTertiary(colorScheme)
                        )
                        .animation(LiquidDesignSystem.Animation.quick, value: isFocused)
                }
                
                // Text input
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(LiquidDesignSystem.Typography.bodyLarge)
                        .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextPrimary(colorScheme))
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .font(LiquidDesignSystem.Typography.bodyLarge)
                        .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextPrimary(colorScheme))
                        .focused($isFocused)
                }
            }
            .padding(LiquidDesignSystem.Spacing.md)
            .background(
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                        .fill(
                            LiquidDesignSystem.Colors.adaptiveSurfaceSecondary(colorScheme)
                                .opacity(isFocused ? 1.0 : 0.8)
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: LiquidDesignSystem.CornerRadius.md)
                        .strokeBorder(
                            isFocused
                                ? LiquidDesignSystem.Colors.primary
                                : LiquidDesignSystem.Colors.adaptiveGlassBorder(colorScheme),
                            lineWidth: isFocused ? 2 : 1
                        )
                }
            )
            .animation(LiquidDesignSystem.Animation.quick, value: isFocused)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        LiquidTextField(
            title: "Email",
            text: .constant(""),
            placeholder: "Enter your email",
            icon: "envelope"
        )
        
        LiquidTextField(
            title: "Password",
            text: .constant(""),
            placeholder: "Enter your password",
            icon: "lock",
            isSecure: true
        )
        
        LiquidTextField(
            title: "Task Name",
            text: .constant("Morning Meeting"),
            placeholder: "Enter task name",
            icon: "pencil"
        )
    }
    .padding()
    .background(LiquidDesignSystem.Gradients.meshBackground(.light))
}

