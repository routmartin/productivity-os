import SwiftUI

/// Circadian Anchor milestone node (Wake Up or Bedtime Target)
public struct ScheduleAnchorNodeView: View {
    public let node: ScheduleNode
    public let isOverflowing: Bool
    public var onTap: (() -> Void)?

    public init(
        node: ScheduleNode,
        isOverflowing: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.node = node
        self.isOverflowing = isOverflowing
        self.onTap = onTap
    }

    private var isWake: Bool {
        node.anchorKind == "wake"
    }

    public var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Milestone Icon
                ZStack {
                    Circle()
                        .fill(isWake ? Color(hex: "FFF7ED") : (isOverflowing ? Color(hex: "FEF3C7") : Color(hex: "EEF2FF")))
                        .frame(width: 42, height: 42)

                    Image(systemName: isWake ? "sun.max.fill" : "moon.stars.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isWake ? Color(hex: "EA580C") : (isOverflowing ? AppColors.warning : Color(hex: "4F46E5")))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(node.title)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textPrimary)

                        Spacer()

                        if isWake {
                            Text(node.time ?? "06:30")
                                .font(AppTypography.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(hex: "EA580C"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color(hex: "FFF7ED")))
                        } else {
                            if isOverflowing, let projected = node.projectedTime {
                                Text("\(projected) (+\(node.overflowMinutes ?? 0)m)")
                                    .font(AppTypography.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppColors.warning)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color(hex: "FEF3C7")))
                            } else {
                                Text(node.targetTime ?? "22:30")
                                    .font(AppTypography.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color(hex: "4F46E5"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color(hex: "EEF2FF")))
                            }
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
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(
                                isWake ? Color(hex: "FDBA74").opacity(0.4) : (isOverflowing ? AppColors.warning.opacity(0.4) : Color(hex: "C7D2FE").opacity(0.4)),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
