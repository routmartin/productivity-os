import SwiftUI

/// Calming recharge and recovery pause node
public struct ScheduleRechargeNodeView: View {
    public let node: ScheduleNode
    public var onTap: (() -> Void)?

    public init(node: ScheduleNode, onTap: (() -> Void)? = nil) {
        self.node = node
        self.onTap = onTap
    }

    private var iconName: String {
        switch node.rechargeKind {
        case "nutrition": return "fork.knife"
        case "walk": return "figure.walk"
        case "winddown": return "cup.and.saucer.fill"
        default: return "leaf.fill"
        }
    }

    public var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "F0FDF4"))
                        .frame(width: 34, height: 34)

                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "16A34A"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(node.title)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textPrimary)

                        Spacer()

                        if let duration = node.durationMinutes {
                            Text("\(duration)m break")
                                .font(AppTypography.captionSmall)
                                .fontWeight(.medium)
                                .foregroundStyle(Color(hex: "16A34A"))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color(hex: "DCFCE7")))
                        }
                    }

                    if let subtitle = node.subtitle {
                        Text(subtitle)
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(AppSpacing.sm)
            .padding(.horizontal, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(Color(hex: "FAFCFA"))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(Color(hex: "86EFAC").opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
