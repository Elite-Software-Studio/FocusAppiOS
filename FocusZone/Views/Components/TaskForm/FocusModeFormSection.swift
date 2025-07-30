//
//  FocusModeFormSection.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//
//
//  FocusModeFormSection.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import SwiftUI

struct FocusModeFormSection: View {
    @Binding var isEnabled: Bool
    @Binding var selectedMode: FocusMode?
    let taskType: TaskType?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Focus Mode")
                    .font(AppFonts.headline())
                    .foregroundColor(.gray)
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .tint(.purple)
            }

            if isEnabled {
                // Binding fallback to suggestedFocusMode if selectedMode is nil
                FocusModeSelector(selectedMode: Binding(
                    get: { (selectedMode ?? suggestedFocusMode)! },
                    set: { selectedMode = $0 }
                ))

                if let suggested = suggestedFocusMode {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Suggested: \(suggested.displayName) for \(taskType?.displayName ?? "this task")")
                            .font(AppFonts.caption())
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private var suggestedFocusMode: FocusMode? {
        switch taskType {
        case .work: return .workMode
        case .study: return .deepWork
        case .exercise, .meal, .sleep: return .lightFocus
        default: return .lightFocus
        }
    }
}

#Preview {
    FocusModeFormSection(
        isEnabled: .constant(true),
        selectedMode: .constant(.workMode),
        taskType: .exercise
    )
}
