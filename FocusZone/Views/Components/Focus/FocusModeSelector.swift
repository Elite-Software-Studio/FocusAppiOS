//
//  FocusModeSelector.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import SwiftUI

struct FocusModeSelector: View {
    @Binding var selectedMode: FocusMode
    let availableModes = FocusMode.allCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Focus Intensity")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
            
            ForEach(availableModes, id: \.self) { mode in
                FocusModeCard(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    onSelect: { selectedMode = mode }
                )
            }
        }
    }
}
