import SwiftUI

struct TaskFormHeader: View {
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text(LanguageManager.localized("new_task", comment: "New task header title"))
                .font(AppFonts.title())
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(action: {
                // Ensure dismiss is called on main thread
                DispatchQueue.main.async {
                    onDismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle()) // Make the entire button area tappable
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
}

#Preview {
    TaskFormHeader(onDismiss: {})
}