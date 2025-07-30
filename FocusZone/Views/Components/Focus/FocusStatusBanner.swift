//
//  FocusStatusBanner.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import SwiftUI

struct FocusStatusBanner: View {
    let mode: FocusMode?
    let blockedNotifications: Int
    @State private var pulseAnimation = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Focus indicator
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple.opacity(0.8), .blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: pulseAnimation)
                
                Image(systemName: "moon.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 14))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(mode?.displayName ?? "Focus") Active")
                    .font(AppFonts.subheadline())
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                if blockedNotifications > 0 {
                    Text("\(blockedNotifications) distractions blocked")
                        .font(AppFonts.caption())
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Button("Settings") {
                // Open Focus settings
            }
            .font(AppFonts.caption())
            .foregroundColor(AppColors.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            pulseAnimation = true
            
        }
    }
}

#Preview {
    FocusStatusBanner(mode: .lightFocus, blockedNotifications: 1)
}
