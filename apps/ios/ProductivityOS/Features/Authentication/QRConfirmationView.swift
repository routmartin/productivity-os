import SwiftUI

public struct QRConfirmationView: View {
    let onContinue: () -> Void
    let onCancel: () -> Void
    let isLoading: Bool
    
    public init(isLoading: Bool, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.isLoading = isLoading
        self.onContinue = onContinue
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Branding/Icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "iphone.badge.plus")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
            }
            
            VStack(spacing: AppSpacing.md) {
                Text("Connect to Productivity OS?")
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text("You're signing in to this iPhone with your Productivity OS account.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }
            
            Spacer()
            
            VStack(spacing: AppSpacing.md) {
                AppButton(
                    title: isLoading ? "Connecting..." : "Continue",
                    style: .primary
                ) {
                    onContinue()
                }
                .disabled(isLoading)
                
                Button("Cancel") {
                    onCancel()
                }
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.vertical, AppSpacing.sm)
                .disabled(isLoading)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.canvas.ignoresSafeArea())
    }
}

#Preview {
    QRConfirmationView(isLoading: false, onContinue: {}, onCancel: {})
}
