import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    @State private var animateContent = false
    @EnvironmentObject var languageManager: LanguageManager
    
    private let totalPages = 3
        
    var body: some View {
        ZStack {
            // Beautiful gradient background inspired by the serene landscape
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.8),
                    Color.blue.opacity(0.6),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section with logo and category
                VStack(spacing: 16) {
                    Spacer()
                    
                    // Page content
                    TabView(selection: $currentPage) {
                        // Screen 1: Welcome & Introduction
                        OnboardingScreen1()
                            .tag(0)
                        
                        // Screen 2: Key Features
                        OnboardingScreen2()
                            .tag(1)
                        
                        // Screen 3: Get Started
                        OnboardingScreen3(onComplete: completeOnboarding)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 500)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.orange : Color.orange.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        // Previous button (hidden on first page)
                        if currentPage > 0 &&
                            currentPage < totalPages - 1  {
                            Button(action: previousPage) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text(LanguageManager.localized("previous", comment: "Previous button text"))
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                                .frame(height: 50)
                                .padding(.horizontal, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white)
                                        .shadow(radius: 1)
                                )
                            }
                        }
                        
                        // Next button (hidden on last page)
                        if currentPage < totalPages - 1 {
                            Button(action: nextPage) {
                                HStack {
                                    Text(LanguageManager.localized("next", comment: "Next button text"))
                                    Image(systemName: "chevron.right")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(height: 50)
                                .padding(.horizontal, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.orange)
                                        .shadow(radius: 1)
                                )
                            }
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    
                    // Skip button (always visible)
                    Button(action: completeOnboarding) {
                                                           Text(LanguageManager.localized("skip", comment: "Skip button text"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.white)
                    }
                    .padding(.top, 20)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    
                    Spacer()
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animateContent = true
                }
            }
            .animation(.easeInOut(duration: 0.5), value: currentPage)
        }
    }
    
    private func nextPage() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage = min(currentPage + 1, totalPages - 1)
        }
    }
    
    private func previousPage() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage = max(currentPage - 1, 0)
        }
    }
        
    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            hasSeenOnboarding = true
        }
    }
}

// MARK: - Onboarding Screen 1: Welcome & Introduction
struct OnboardingScreen1: View {
    var body: some View {
        VStack(spacing: 30) {
            // Main title
                                   Text(LanguageManager.localized("transform_your_productivity", comment: "Onboarding main title"))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Description
                                   Text(LanguageManager.localized("onboarding_description_1", comment: "Onboarding description text"))
                .font(AppFonts.headline())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .lineLimit(6)
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(.orange)
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Onboarding Screen 2: Key Features
struct OnboardingScreen2: View {
    var body: some View {
        VStack(spacing: 25) {
            // Title
                                   Text(LanguageManager.localized("powerful_features", comment: "Powerful features title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)                .padding(.top, 20)
            
            // Features grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                FeatureCard(icon: "brain.head.profile", title: LanguageManager.localized("ai_assistant", comment: "AI Assistant feature"), color: .blue)
                FeatureCard(icon: "chart.line.uptrend.xyaxis", title: LanguageManager.localized("analytics", comment: "Analytics feature"), color: .green)
                FeatureCard(icon: "timer", title: LanguageManager.localized("smart_timers", comment: "Smart Timers feature"), color: .orange)
                FeatureCard(icon: "arrow.triangle.2.circlepath", title: LanguageManager.localized("break_suggestions", comment: "Break Suggestions feature"), color: .pink)
                FeatureCard(icon: "folder.badge.plus", title: LanguageManager.localized("focus_modes", comment: "Focus Modes feature"), color: .brown)
                FeatureCard(icon: "icloud.fill", title: LanguageManager.localized("cloud_sync", comment: "Cloud Sync feature"), color: .purple)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Onboarding Screen 3: Get Started
struct OnboardingScreen3: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Title
                                   Text(LanguageManager.localized("ready_to_focus", comment: "Ready to focus title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            // Description
                                   Text(LanguageManager.localized("onboarding_description_3", comment: "Onboarding final description"))
                .font(AppFonts.headline())
                .foregroundColor(.white)                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .lineLimit(5)
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(.orange)
            }
            .padding(.top, 20)
            Spacer()
            // Beautiful Slider Get Started Button
            SliderGetStartedButton(
                backgroundColor: Color.green,
                onComplete: onComplete
            )
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(AppFonts.headline())
                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Slider Get Started Button
struct SliderGetStartedButton: View {
    let backgroundColor: Color
    let onComplete: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showCompletion = false
    
    private let buttonHeight: CGFloat = 60
    private let maxDragDistance: CGFloat = 250
    
    var body: some View {
        ZStack {
            // Background track
            RoundedRectangle(cornerRadius: buttonHeight / 2)
                .fill(Color.white.opacity(0.3))
                .frame(height: buttonHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: buttonHeight / 2)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
            
            // Progress track
            HStack {
                RoundedRectangle(cornerRadius: buttonHeight / 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [backgroundColor, backgroundColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(60, dragOffset + buttonHeight / 2), height: buttonHeight)
                
                Spacer()
            }
            
            // Slider handle
            HStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: buttonHeight - 8, height: buttonHeight - 8)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    if showCompletion {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .foregroundColor(backgroundColor)
                            .fontWeight(.bold)
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.title2)
                            .foregroundColor(backgroundColor)
                            .fontWeight(.bold)
                    }
                }
                .offset(x: dragOffset - 120)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let translation = value.translation
                            dragOffset = min(maxDragDistance, max(0, translation.width))
                        }
                        .onEnded { value in
                            isDragging = false
                            
                            if dragOffset >= maxDragDistance * 0.7 {
                                // Complete the slide
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    dragOffset = maxDragDistance
                                    showCompletion = true
                                }
                                
                                // Trigger completion after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    onComplete()
                                }
                            } else {
                                // Reset to start
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                
                Spacer()
            }
            
            // Text overlay
            HStack {
                Spacer()
                Text(showCompletion ? LanguageManager.localized("welcome", comment: "Welcome message") : LanguageManager.localized("slide_to_get_started", comment: "Slide to get started instruction"))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.7))
                    .opacity(showCompletion ? 1 : (dragOffset > 50 ? 0 : 1))
                    .animation(.easeInOut(duration: 0.3), value: showCompletion)
                
                Spacer()
            }
            .padding(.leading, 20)
            .allowsHitTesting(false)
        }
        .frame(height: buttonHeight)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(LanguageManager.shared)
}
