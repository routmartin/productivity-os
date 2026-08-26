import SwiftUI

/// Reusable soft elevated card container
public struct AppCard<Content: View>: View {
    private let content: Content
    private let backgroundColor: Color
    private let borderColor: Color
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    
    public init(
        backgroundColor: Color = AppColors.surface,
        borderColor: Color = AppColors.surfaceBorder,
        cornerRadius: CGFloat = AppRadius.lg,
        padding: CGFloat = AppSpacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    public var body: some View {
        content
            .padding(padding)
            .appCardStyle(
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                cornerRadius: cornerRadius
            )
    }
}

#Preview {
    AppCard {
        Text("Sample Card Content")
            .font(AppTypography.headline)
            .foregroundStyle(AppColors.textPrimary)
    }
    .padding()
    .background(AppColors.canvas)
}
