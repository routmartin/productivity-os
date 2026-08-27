// Create the QRConfirmationView SwiftUI view that matches its usage in LoginView.swift
import SwiftUI

/// Modal confirmation after scanning a QR code, allowing the user to continue with authentication or cancel.
public struct QRConfirmationView: View {
    let isLoading: Bool
    let onContinue: () -> Void
    let onCancel: () -> Void

    public init(
        isLoading: Bool,
        onContinue: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.isLoading = isLoading
        self.onContinue = onContinue
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "qrcode")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .padding(.top, 16)

            Text("Continue login on this device?")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .tint(AppColors.primary)
                    .padding()
            }

            HStack(spacing: 16) {
                AppButton(title: "Cancel", style: .secondary) {
                    onCancel()
                }
                .disabled(isLoading)

                AppButton(title: "Continue", style: .primary) {
                    onContinue()
                }
                .disabled(isLoading)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xl)
        .padding(.top, AppSpacing.lg)
        .background(AppColors.canvas.ignoresSafeArea())
    }
}

#Preview {
    QRConfirmationView(isLoading: false, onContinue: {}, onCancel: {})
}
