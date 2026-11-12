import SwiftUI

/// Habit node with interactive checkbox toggle and streak counter (Spec AC-002, AC-005).
public struct ScheduleHabitNodeView: View {
    public let node: ScheduleNode
    public var onToggleCompletion: (() -> Void)?
    public var onTap: (() -> Void)?

    public init(
        node: ScheduleNode,
        onToggleCompletion: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.node = node
        self.onToggleCompletion = onToggleCompletion
        self.onTap = onTap
    }

    private var isCompleted: Bool {
        node.completed ?? false
    }

    private var streakCount: Int {
        node.streak ?? 0
    }

    public var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Interactive Checkbox Button
                Button {
                    #if os(iOS)
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(isCompleted ? .warning : .success)
                    #endif
                    onToggleCompletion?()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(isCompleted ? AppColors.success : Color(hex: "CBD5E1"), lineWidth: 2)
                            .frame(width: 28, height: 28)

                        if isCompleted {
                            Circle()
                                .fill(AppColors.success)
                                .frame(width: 28, height: 28)

                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Icon / Avatar
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(isCompleted ? AppColors.success.opacity(0.12) : AppColors.primaryTint)
                        .frame(width: 36, height: 36)

                    Image(systemName: node.icon ?? "drop.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(isCompleted ? AppColors.success : AppColors.primary)
                }

                // Details
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(node.title)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textPrimary)
                            .strikethrough(isCompleted, color: AppColors.textSecondary)

                        Spacer()

                        // Streak flame badge
                        if streakCount > 0 {
                            HStack(spacing: 3) {
                                Text("🔥")
                                    .font(.system(size: 11))
                                Text("\(streakCount)d")
                                    .font(AppTypography.captionSmall)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(Color(hex: "EA580C"))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "FFEDD5"))
                            )
                        }
                    }

                    HStack(spacing: 6) {
                        if let time = node.time {
                            Text(time)
                                .font(AppTypography.captionSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        if let duration = node.durationMinutes {
                            Text("• \(duration)m")
                                .font(AppTypography.captionSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        if let subtitle = node.subtitle {
                            Text("• \(subtitle)")
                                .font(AppTypography.captionSmall)
                                .foregroundStyle(AppColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(isCompleted ? Color(hex: "F7FBF8") : AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(isCompleted ? AppColors.success.opacity(0.3) : AppColors.surfaceBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
