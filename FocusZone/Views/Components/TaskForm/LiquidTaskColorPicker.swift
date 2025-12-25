import SwiftUI

struct LiquidTaskColorPicker: View {
    @Binding var selectedColor: Color
    
    private let quickColors: [Color] = [
        .pink, .orange, .yellow, .green, .teal, .blue, .purple
    ]
    
    @State private var showPickerSheet: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.lg) {
            // Header
            HStack {
                Text("What color?")
                    .font(LiquidDesignSystem.Typography.headlineFont)
                    .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Button("More…") {
                    showPickerSheet = true
                }
                .font(LiquidDesignSystem.Typography.subheadlineFont)
                .foregroundStyle(LiquidDesignSystem.Colors.accent)
            }
            
            // Quick colors row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LiquidDesignSystem.Spacing.md) {
                    ForEach(quickColors.indices, id: \.self) { idx in
                        let color = quickColors[idx]
                        Button(action: {
                            withAnimation(LiquidDesignSystem.Animation.spring) {
                                selectedColor = color
                            }
                        }) {
                            ZStack {
                                // Base circle
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [color.opacity(0.8), color],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                
                                // Selection indicator
                                if selectedColor == color {
                                    Circle()
                                        .stroke(.white, lineWidth: 3)
                                        .frame(width: 44, height: 44)
                                    
                                    Circle()
                                        .stroke(color, lineWidth: 3)
                                        .frame(width: 52, height: 52)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                        .animation(LiquidDesignSystem.Animation.spring, value: selectedColor)
                    }
                }
                .padding(.vertical, LiquidDesignSystem.Spacing.sm)
                .padding(.horizontal, LiquidDesignSystem.Spacing.md)
            }
            .glassSurface()
        }
        .sheet(isPresented: $showPickerSheet) {
            NavigationView {
                ZStack {
                    LiquidDesignSystem.Colors.meshGradientBackground
                        .ignoresSafeArea()
                    
                    VStack(spacing: LiquidDesignSystem.Spacing.xl) {
                        ColorPicker(
                            "Pick a color",
                            selection: $selectedColor,
                            supportsOpacity: false
                        )
                        .padding(LiquidDesignSystem.Spacing.lg)
                        .glassSurface()
                        .padding(LiquidDesignSystem.Spacing.lg)
                        
                        Spacer()
                    }
                }
                .navigationTitle("Color")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            showPickerSheet = false
                        }
                        .foregroundStyle(LiquidDesignSystem.Colors.accent)
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedColor = Color.pink
    
    return LiquidTaskColorPicker(selectedColor: $selectedColor)
        .padding()
        .background(LiquidDesignSystem.Colors.meshGradientBackground)
}

