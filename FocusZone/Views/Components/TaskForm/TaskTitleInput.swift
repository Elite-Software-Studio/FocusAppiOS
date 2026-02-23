import SwiftUI

struct TaskTitleInput: View {
    @Binding var taskTitle: String
    @Binding var selectedColor: Color
    @Binding var duration: Int
    @State private var showingPreviewTasks: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.pink)
                    .font(.system(size: 20))
                TextField(LanguageManager.localized("task_title", comment: "Task title input placeholder"), text: $taskTitle)
                    .font(AppFonts.headline())
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: taskTitle) { newValue in
                        showingPreviewTasks = newValue.isEmpty
                    }
                    .onAppear {
                        showingPreviewTasks = taskTitle.isEmpty
                    }
            }
            .padding(.bottom, 8)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
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
    @State var title = ""
    @State var color = Color.pink
    @State var duration = 15
    
    return TaskTitleInput(
        taskTitle: $title,
        selectedColor: $color,
        duration: $duration
    )
}
