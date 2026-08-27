import SwiftUI

/// Reusable button styles matching the approved Liquid Glass design reference
public struct AppButton: View {
    public enum Style {
        case primary
        case secondary
        case focusControl(isPrimary: Bool)
    }
    
    private let title: String
    private let icon: String?
    private let style: Style
    private let action: () -> Void
    
    public init(
        title: String,
        icon: String? = nil,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Group {
                if #available(iOS 26.0, macOS 26.0, *) {
                    HStack(spacing: AppSpacing.xs) {
                        if let icon {
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .bold))
                        }
                        Text(title)
                            .font(AppTypography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppRadius.pill))
                } else {
                    HStack(spacing: AppSpacing.xs) {
                        if let icon {
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .bold))
                        }
                        Text(title)
                            .font(AppTypography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.pill))
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Subtle spring press animation for interactive buttons
public struct ScaleButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        AppButton(title: "Start Focus", icon: "play.fill", style: .primary) {}
        AppButton(title: "Choose Another", style: .secondary) {}
    }
    .padding()
    .background(AppColors.canvas)
}
