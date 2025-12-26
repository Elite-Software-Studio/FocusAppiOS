import SwiftUI

struct LiquidTaskTitleInput: View {
    @Binding var taskTitle: String
    @Binding var selectedColor: Color
    @Binding var duration: Int
    @State private var showingPreviewTasks: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.md) {
            // Input field with glass surface
            HStack(spacing: LiquidDesignSystem.Spacing.sm) {
                // Icon
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(LiquidDesignSystem.Colors.primary)
                    .font(.title3)
                
                // Text field
                TextField(
                    NSLocalizedString("task_title", comment: "Task title input placeholder"),
                    text: $taskTitle
                )
                .font(LiquidDesignSystem.Typography.titleMedium)
                .foregroundStyle(LiquidDesignSystem.Colors.textPrimary)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .onChange(of: taskTitle) { _, newValue in
                    showingPreviewTasks = newValue.isEmpty
                }
                .onAppear {
                    showingPreviewTasks = taskTitle.isEmpty
                }
            }
            .padding(LiquidDesignSystem.Spacing.lg)
            .glassSurface()
            
            // Preview tasks when title is empty
            if showingPreviewTasks {
                TaskPreviewGrid(
                    taskTitle: $taskTitle,
                    selectedColor: $selectedColor,
                    duration: $duration,
                    showingPreviewTasks: $showingPreviewTasks
                )
            }
        }
    }
}

#Preview {
    @Previewable @State var title = ""
    @Previewable @State var color = Color.pink
    @Previewable @State var duration = 15
    
    return LiquidTaskTitleInput(
        taskTitle: $title,
        selectedColor: $color,
        duration: $duration
    )
    .padding()
    .background(LiquidDesignSystem.Colors.meshGradientBackground)
}

