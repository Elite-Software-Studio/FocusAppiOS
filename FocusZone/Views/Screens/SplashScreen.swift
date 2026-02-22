import SwiftUI

struct SplashScreen: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.8),
                    Color.pink.opacity(0.6),
                    Color.orange.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background circles
            BackgroundCircles(isAnimating: isAnimating)
            
            VStack(spacing: 30) {
                // App icon/logo with animations
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)
                        .opacity(isAnimating ? 0.0 : 1.0)
                        .animation(
                            Animation.easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(0.5),
                            value: pulseScale
                        )
                    
                    // Main icon container
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        )
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotationAngle))
                        .overlay(
                            // Focus icon
                            Image(systemName: "target")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(.white)
                                .scaleEffect(scale)
                        )
                }
                
                // App title with staggered animation
                AppTitleView(isAnimating: isAnimating, opacity: opacity)
                
                // Loading indicator
                LoadingIndicator(isAnimating: isAnimating, opacity: opacity)
            }
            .offset(y: -50)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Main icon scale and rotation
        withAnimation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.3)) {
            scale = 1.0
        }
        
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Fade in text
        withAnimation(.easeOut(duration: 1.0).delay(0.8)) {
            opacity = 1.0
        }
        
        // Start background animations
        withAnimation(.easeInOut(duration: 1.0).delay(0.5)) {
            isAnimating = true
        }
        
        // Pulse effect
        withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
            pulseScale = 2.0
        }
    }
}

// MARK: - Supporting Components

struct BackgroundCircles: View {
    let isAnimating: Bool
    
    var body: some View {
        ForEach(0..<6) { index in
            let size = CGFloat(100 + index * 50)
            let offsetX = CGFloat(index % 2 == 0 ? -50 : 50)
            let offsetY = CGFloat(index % 3 == 0 ? -100 : 100)
            
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: size, height: size)
                .offset(x: offsetX, y: offsetY)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .opacity(isAnimating ? 0.3 : 0.1)
                .animation(
                    .easeInOut(duration: 2.0 + Double(index) * 0.3)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                    value: isAnimating
                )
        }
    }
}

struct AppTitleView: View {
    let isAnimating: Bool
    let opacity: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(Array("FocusZEN+".enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .font(AppFonts.largetitle()) // Using system font instead of AppFonts
                        .foregroundColor(.white)
                        .opacity(opacity)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1 + 1.0),
                            value: isAnimating
                        )
                }
            }
            
            Text(LanguageManager.localized("stay_focused_achieve_more", comment: "Splash screen tagline"))
                .font(AppFonts.subheadline()) // Using system font instead of AppFonts
                .foregroundColor(.white.opacity(0.8))
                .opacity(opacity)
                .offset(y: isAnimating ? 0 : 10)
                .animation(
                    .easeOut(duration: 0.8).delay(2.0),
                    value: isAnimating
                )
        }
    }
}

struct LoadingIndicator: View {
    let isAnimating: Bool
    let opacity: Double
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 8, height: 8)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2 + 2.5),
                            value: isAnimating
                        )
                }
            }
            
            Text(LanguageManager.localized("loading", comment: "Loading indicator text"))
                .font(.system(size: 12)) // Using system font instead of AppFonts
                .foregroundColor(.white.opacity(0.6))
                .opacity(opacity)
                .animation(
                    .easeOut(duration: 0.5).delay(2.5),
                    value: opacity
                )
        }
    }
}

#Preview {
    SplashScreen()
        .environmentObject(ThemeManager())
}
