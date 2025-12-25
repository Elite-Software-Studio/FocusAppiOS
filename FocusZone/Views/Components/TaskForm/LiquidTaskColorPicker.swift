import SwiftUI

struct LiquidTaskColorPicker: View {
    @Binding var selectedColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    private let quickColors: [Color] = [
        .pink, .orange, .yellow, .green, .teal, .blue, .purple
    ]
    
    @State private var showPickerSheet: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.lg) {
            // Header
            HStack {
                Text("What color?")
                    .font(LiquidDesignSystem.Typography.headlineSmall)
                    .foregroundStyle(LiquidDesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Button("More…") {
                    showPickerSheet = true
                }
                .font(LiquidDesignSystem.Typography.titleSmall)
                .foregroundStyle(LiquidDesignSystem.Colors.primary)
            }
            
            // Quick colors row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LiquidDesignSystem.Spacing.md) {
                    ForEach(quickColors.indices, id: \.self) { idx in
                        let color = quickColors[idx]
                        Button(action: {
                            withAnimation(LiquidDesignSystem.Animation.smooth) {
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
                        .animation(LiquidDesignSystem.Animation.smooth, value: selectedColor)
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
                    LiquidDesignSystem.Gradients.meshBackground(colorScheme)
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
                        .foregroundStyle(LiquidDesignSystem.Colors.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedColor = Color.pink
    
    LiquidTaskColorPicker(selectedColor: $selectedColor)
        .padding()
        .background(LiquidDesignSystem.Gradients.meshBackground(.light))
}

