import SwiftUI

struct AppToggle: View {
    var title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(AppFonts.body())
                .foregroundColor(AppColors.textPrimary)
        }
        .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
    }
}
