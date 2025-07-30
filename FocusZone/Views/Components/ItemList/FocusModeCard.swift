//
//  FocusModeCard.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import SwiftUI

struct FocusModeCard: View {
    let mode: FocusMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Mode icon
                Image(systemName: mode.iconName )
                    .font(.title2)
                    .foregroundColor(mode.color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(AppFonts.subheadline())
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(mode.description)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(mode.color)
                        .font(.title3)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? mode.color.opacity(0.1) : AppColors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? mode.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
#Preview {
    FocusModeCard(mode: .deepWork, isSelected: false, onSelect: {})
}
