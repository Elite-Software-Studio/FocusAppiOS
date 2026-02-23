import SwiftUI

struct TaskIconPicker: View {
    @Binding var selectedIcon: String
    
    let icons = ["🖥️", "📚", "🎨", "🎮", "🏋️‍♀️", "💼", "🍽️", "🌙", "🧘", "⏰"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(LanguageManager.localized("what_type_of_task", comment: "What type of task question"))
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
            }
            
            // Break up the complex expression into simpler parts
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(icons, id: \.self) { icon in
                    IconButton(
                        icon: icon,
                        isSelected: selectedIcon == icon,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedIcon = icon
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Component

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundGradient)
                    .frame(width: 56, height: 56)
                
                // Icon text
                Text(icon)
                    .font(.system(size: 24))
                
                // Selection indicator
                if isSelected {
                    Circle()
                        .stroke(AppColors.accent, lineWidth: 3)
                        .frame(width: 60, height: 60)
                        .scaleEffect(1.1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var backgroundGradient: LinearGradient {
        if isSelected {
            return LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.accent.opacity(0.2),
                    AppColors.accent.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.card,
                    AppColors.card
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

#Preview {
    @State var selectedIcon: String = "🖥️"
    
    return VStack {
        TaskIconPicker(selectedIcon: $selectedIcon)
        
        Text("Selected: \(selectedIcon)")
            .padding()
    }
    .padding()
    .background(AppColors.background)
}
