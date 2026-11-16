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
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "86EFAC").opacity(0.5), lineWidth: 1)
                        )

                    Image(systemName: iconName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: "16A34A"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Row 1: Title
                    Text(node.title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)

                    // Row 2: Subtitle (Full-width clean description)
                    if let subtitle = node.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }

                    // Row 3: Metadata Row (Scheduled Time + Recovery duration)
                    if node.time != nil || node.durationMinutes != nil {
                        HStack(spacing: 6) {
                            if let time = node.time {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(time)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .monospacedDigit()
                                }
                                .foregroundStyle(Color(hex: "15803D"))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "F0FDF4"))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color(hex: "BBF7D0"), lineWidth: 0.8)
                                        )
                                )
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                            }

                            if let duration = node.durationMinutes {
                                HStack(spacing: 4) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("\(duration)m recovery")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .monospacedDigit()
                                }
                                .foregroundStyle(Color(hex: "14532D"))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "DCFCE7"))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color(hex: "86EFAC"), lineWidth: 0.8)
                                        )
                                )
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                            }

                            Spacer()
                        }
                        .padding(.top, 2)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(Color(hex: "FAFCFA"))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(Color(hex: "86EFAC").opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
