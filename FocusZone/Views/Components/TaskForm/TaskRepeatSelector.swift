import SwiftUI

struct TaskRepeatSelector: View {
    @Binding var repeatRule: RepeatRule
    
    let repeatOptions = RepeatRule.allCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(LanguageManager.localized("how_often", comment: "How often question for repeat selection"))
                    .font(AppFonts.headline())
                    .foregroundColor(.gray)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(repeatOptions, id: \.self) { option in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            repeatRule = option
                        }
                    }) {
                        Text(option.displayName)
                            .font(AppFonts.caption())
                            .foregroundColor(repeatRule == option ? .white : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(repeatRule == option ? Color.pink : Color.gray.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

#Preview {
    @State var repeatRule = RepeatRule.none
    
    return TaskRepeatSelector(repeatRule: $repeatRule)
}
