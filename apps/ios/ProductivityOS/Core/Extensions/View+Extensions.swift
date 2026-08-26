import SwiftUI

extension View {
    /// Applies standard soft card surface styling with subtle border and elevation
    func appCardStyle(
        backgroundColor: Color = AppColors.surface,
        borderColor: Color = AppColors.surfaceBorder,
        cornerRadius: CGFloat = AppRadius.xl,
        shadowColor: Color = Color.black.opacity(0.04),
        shadowRadius: CGFloat = 12,
        shadowY: CGFloat = 4
    ) -> some View {
        self
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
    
    /// Applies deep focus glass card styling
    func focusCardStyle(
        backgroundColor: Color = AppColors.focusSurface,
        borderColor: Color = AppColors.focusSurfaceBorder,
        cornerRadius: CGFloat = AppRadius.lg
    ) -> some View {
        self
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}
