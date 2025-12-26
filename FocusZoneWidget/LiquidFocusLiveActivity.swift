import ActivityKit
import WidgetKit
import SwiftUI

/// Liquid-styled Live Activity for FocusZone
/// Uses glass surfaces, smooth gradients, and the liquid design system
struct LiquidFocusZoneWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusZoneWidgetAttributes.self) { context in
            // Lock screen/banner UI with liquid design
            LiquidFocusLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Regions
                
                DynamicIslandExpandedRegion(.leading) {
                    LiquidDynamicIslandLeading(context: context)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    LiquidDynamicIslandTrailing(context: context)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    LiquidDynamicIslandCenter(context: context)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    LiquidDynamicIslandBottom(context: context)
                }
            } compactLeading: {
                // MARK: - Compact Leading
                HStack(spacing: 4) {
                    Image(systemName: context.state.currentPhase.icon)
                        .font(.caption2)
                        .foregroundStyle(.white)
                    
                    if context.state.isActive {
                        Circle()
                            .fill(LiquidWidgetDesign.Colors.success)
                            .frame(width: 4, height: 4)
                    }
                }
            } compactTrailing: {
                // MARK: - Compact Trailing
                Text(formatTimeRemaining(context.state.timeRemaining))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            } minimal: {
                // MARK: - Minimal
                HStack(spacing: 3) {
                    Image(systemName: context.state.currentPhase.icon)
                        .font(.caption2)
                        .foregroundStyle(.white)
                    
                    if context.state.isActive {
                        Circle()
                            .fill(LiquidWidgetDesign.Colors.success)
                            .frame(width: 3, height: 3)
                    }
                }
            }
        }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let totalMinutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
        } else {
            return seconds == 0 ? "\(totalMinutes)m" : "\(totalMinutes):\(String(format: "%02d", seconds))"
        }
    }
}

// MARK: - Dynamic Island Components

struct LiquidDynamicIslandLeading: View {
    let context: ActivityViewContext<FocusZoneWidgetAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: context.state.currentPhase.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1)
                
                Text(context.state.currentPhase.displayName)
                    .font(LiquidWidgetDesign.Typography.captionFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.9))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Text("\(Int(context.state.progress * 100))%")
                .font(LiquidWidgetDesign.Typography.caption2Font)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

struct LiquidDynamicIslandTrailing: View {
    let context: ActivityViewContext<FocusZoneWidgetAttributes>
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(formatTimeRemaining(context.state.timeRemaining))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 1)
            
            Text("remaining")
                .font(LiquidWidgetDesign.Typography.caption2Font)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.8))
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let totalMinutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
        } else {
            return seconds == 0 ? "\(totalMinutes)m" : "\(totalMinutes):\(String(format: "%02d", seconds))"
        }
    }
}

struct LiquidDynamicIslandCenter: View {
    let context: ActivityViewContext<FocusZoneWidgetAttributes>
    
    var body: some View {
        VStack(spacing: 10) {
            Text(context.state.taskTitle)
                .font(LiquidWidgetDesign.Typography.headlineFont)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.3), radius: 1)
            
            // Liquid progress bar
            LiquidProgressBar(progress: context.state.progress, width: 200)
        }
    }
}

struct LiquidDynamicIslandBottom: View {
    let context: ActivityViewContext<FocusZoneWidgetAttributes>
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 6, height: 6)
                
                Text("Session \(context.state.completedSessions + 1) of \(context.state.totalSessions)")
                    .font(LiquidWidgetDesign.Typography.caption2Font)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            Spacer()
            
            LiquidStatusBadge(isActive: context.state.isActive)
        }
    }
}

// MARK: - Main Lock Screen View

struct LiquidFocusLiveActivityView: View {
    let context: ActivityViewContext<FocusZoneWidgetAttributes>
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // App badge
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption2)
                            .foregroundStyle(LiquidWidgetDesign.Colors.primary)
                        
                        Text("FocusZone")
                            .font(LiquidWidgetDesign.Typography.captionFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(LiquidWidgetDesign.Colors.textSecondary(for: colorScheme))
                    }
                    
                    // Task title
                    Text(context.state.taskTitle)
                        .font(LiquidWidgetDesign.Typography.titleFont)
                        .fontWeight(.bold)
                        .foregroundStyle(LiquidWidgetDesign.Colors.textPrimary(for: colorScheme))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Time display
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTimeRemaining(context.state.timeRemaining))
                        .font(LiquidWidgetDesign.Typography.largeTitleFont)
                        .fontWeight(.bold)
                        .foregroundStyle(LiquidWidgetDesign.Colors.primary)
                    
                    Text("remaining")
                        .font(LiquidWidgetDesign.Typography.captionFont)
                        .fontWeight(.medium)
                        .foregroundStyle(LiquidWidgetDesign.Colors.textSecondary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
            }
            .padding(LiquidWidgetDesign.Spacing.lg)
            
            Divider()
                .overlay(LiquidWidgetDesign.Colors.glassBorder(for: colorScheme))
            
            // Progress section
            VStack(spacing: LiquidWidgetDesign.Spacing.md) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: context.state.currentPhase.icon)
                            .font(.subheadline)
                            .foregroundStyle(LiquidWidgetDesign.Colors.primary)
                        
                        Text(context.state.currentPhase.displayName)
                            .font(LiquidWidgetDesign.Typography.bodyFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(LiquidWidgetDesign.Colors.textPrimary(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    Text("\(Int(context.state.progress * 100))%")
                        .font(LiquidWidgetDesign.Typography.bodyFont)
                        .fontWeight(.bold)
                        .foregroundStyle(LiquidWidgetDesign.Colors.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(LiquidWidgetDesign.Colors.glassBackground(for: colorScheme))
                        )
                }
                
                // Liquid progress bar (full width)
                LiquidProgressBar(
                    progress: context.state.progress,
                    width: UIScreen.main.bounds.width - (LiquidWidgetDesign.Spacing.lg * 2)
                )
            }
            .padding(LiquidWidgetDesign.Spacing.lg)
            
            Divider()
                .overlay(LiquidWidgetDesign.Colors.glassBorder(for: colorScheme))
            
            // Footer
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(LiquidWidgetDesign.Colors.textSecondary(for: colorScheme).opacity(0.5))
                        .frame(width: 6, height: 6)
                    
                    Text("Session \(context.state.completedSessions + 1) of \(context.state.totalSessions)")
                        .font(LiquidWidgetDesign.Typography.captionFont)
                        .fontWeight(.medium)
                        .foregroundStyle(LiquidWidgetDesign.Colors.textSecondary(for: colorScheme))
                }
                
                Spacer()
                
                LiquidStatusBadge(isActive: context.state.isActive)
            }
            .padding(LiquidWidgetDesign.Spacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: LiquidWidgetDesign.CornerRadius.xl)
                .fill(LiquidWidgetDesign.Colors.backgroundGradient(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LiquidWidgetDesign.CornerRadius.xl)
                .strokeBorder(
                    LiquidWidgetDesign.Colors.glassBorder(for: colorScheme),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: LiquidWidgetDesign.Shadow.large,
            radius: 12,
            x: 0,
            y: 6
        )
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let totalMinutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
        } else {
            return seconds == 0 ? "\(totalMinutes)m" : "\(totalMinutes):\(String(format: "%02d", seconds))"
        }
    }
}

// MARK: - Reusable Components

struct LiquidProgressBar: View {
    let progress: Double
    let width: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background track
            RoundedRectangle(cornerRadius: LiquidWidgetDesign.CornerRadius.sm)
                .fill(.white.opacity(0.15))
                .frame(width: width, height: 8)
            
            // Progress fill with gradient
            RoundedRectangle(cornerRadius: LiquidWidgetDesign.CornerRadius.sm)
                .fill(LiquidWidgetDesign.Colors.focusGradient)
                .frame(width: max(0, width * progress), height: 8)
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}

struct LiquidStatusBadge: View {
    let isActive: Bool
    
    private var statusColor: Color {
        isActive ? LiquidWidgetDesign.Colors.success : LiquidWidgetDesign.Colors.warning
    }
    
    private var statusText: String {
        isActive ? "Active" : "Paused"
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .shadow(color: statusColor.opacity(0.5), radius: 2)
            
            Text(statusText)
                .font(LiquidWidgetDesign.Typography.captionFont)
                .fontWeight(.semibold)
                .foregroundStyle(statusColor)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
        .overlay(
            Capsule()
                .strokeBorder(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}


