import SwiftUI

/// Reusable Loading / Empty / Error state presentation for API-backed screens.
/// Uses the approved DesignSystem; avoids replacing whole screens with error pages.
public struct APIStateView: View {
    public enum Kind {
        case loading(message: String)
        case empty(icon: String, title: String, subtitle: String?)
        case error(message: String)
    }

    private let kind: Kind
    private let onRetry: (() -> Void)?

    public init(kind: Kind, onRetry: (() -> Void)? = nil) {
        self.kind = kind
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: AppSpacing.sm) {
            switch kind {
            case .loading(let message):
                ProgressView()
                    .tint(AppColors.primary)
                Text(message)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

            case .empty(let icon, let title, let subtitle):
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(AppColors.textTertiary)
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

            case .error(let message):
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(hex: "FF6B4A"))
                Text(message)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                if let onRetry {
                    AppButton(title: "Retry", style: .secondary, action: onRetry)
                        .frame(height: 40)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
    }
}

#Preview("Loading") {
    APIStateView(kind: .loading(message: "Loading tasks..."))
}

#Preview("Empty") {
    APIStateView(kind: .empty(icon: "tray", title: "No tasks yet", subtitle: "Create your first task to get started."))
}

#Preview("Error") {
    APIStateView(kind: .error(message: "Could not reach the server."), onRetry: {})
}
