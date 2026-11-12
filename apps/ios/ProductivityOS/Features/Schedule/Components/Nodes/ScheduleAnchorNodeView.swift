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

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 6) {
                        Text(node.title)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textPrimary)

                        Spacer()

                        if isWake {
                            HStack(spacing: 4) {
                                Image(systemName: "sunrise.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text(node.time ?? "06:30")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                            }
                            .foregroundStyle(Color(hex: "C2410C"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4.5)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "FFF7ED"))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(hex: "FDBA74"), lineWidth: 1)
                                    )
                            )
                        } else {
                            if isOverflowing, let projected = node.projectedTime {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(projected)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .monospacedDigit()
                                    if let overflow = node.overflowMinutes, overflow > 0 {
                                        Text("(+\(overflow)m)")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .monospacedDigit()
                                    }
                                }
                                .foregroundStyle(Color(hex: "B45309"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4.5)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "FEF3C7"))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color(hex: "FCD34D"), lineWidth: 1)
                                        )
                                )
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "moon.fill")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(node.targetTime ?? "22:30")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .monospacedDigit()
                                    Text("Target")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .padding(.leading, 1)
                                }
                                .foregroundStyle(Color(hex: "4338CA"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4.5)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "EEF2FF"))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color(hex: "C7D2FE"), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }

                    if let subtitle = node.subtitle, !subtitle.isEmpty {
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
