import SwiftUI

struct ProGate: View {
    let onUpgrade: () -> Void
    let onDismiss: () -> Void
    let currentTaskCount: Int
    let maxTasks: Int
    
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
                
                Text(LanguageManager.localized("upgrade_to_pro", comment: "Upgrade to Pro title"))
                    .font(AppFonts.title())
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(String(format: LanguageManager.localized("task_limit_reached", comment: "Task limit reached message"), maxTasks))
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Features list
            VStack(alignment: .leading, spacing: 12) {
                ForEach(ProFeatures.proFeaturesList, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        
                        Text(feature)
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: onUpgrade) {
                    HStack {
                        if subscriptionManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                        }
                        
                        Text(LanguageManager.localized("upgrade_now", comment: "Upgrade now button"))
                            .font(AppFonts.headline())
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(subscriptionManager.isLoading)
                
                Button(action: onDismiss) {
                    Text(LanguageManager.localized("maybe_later", comment: "Maybe later button"))
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ProGate(
        onUpgrade: {},
        onDismiss: {},
        currentTaskCount: 3,
        maxTasks: 3
    )
}
