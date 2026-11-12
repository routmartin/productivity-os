import SwiftUI

/// Top summary banner displaying bedtime projection status & daily habit progress (Spec AC-004).
public struct ScheduleBedtimeBanner: View {
    public let isOverflowing: Bool
    public let overflowMinutes: Int
    public let targetBedtime: String
    public let projectedBedtime: String
    public let habitProgressPercent: Int
    public let completedHabits: Int
    public let totalHabits: Int

    public init(
        isOverflowing: Bool,
        overflowMinutes: Int,
        targetBedtime: String,
        projectedBedtime: String,
        habitProgressPercent: Int,
        completedHabits: Int,
        totalHabits: Int
    ) {
        self.isOverflowing = isOverflowing
        self.overflowMinutes = overflowMinutes
        self.targetBedtime = targetBedtime
        self.projectedBedtime = projectedBedtime
        self.habitProgressPercent = habitProgressPercent
        self.completedHabits = completedHabits
        self.totalHabits = totalHabits
    }

    public var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(alignment: .center) {
                // Bedtime Projection Indicator
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(isOverflowing ? AppColors.warning.opacity(0.15) : AppColors.success.opacity(0.15))
                            .frame(width: 32, height: 32)

                        Image(systemName: isOverflowing ? "exclamationmark.triangle.fill" : "moon.stars.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isOverflowing ? AppColors.warning : AppColors.success)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isOverflowing ? "Bedtime Shifts: \(projectedBedtime)" : "Bedtime Target: \(targetBedtime)")
                            .font(AppTypography.headline)
                            .monospacedDigit()
                            .foregroundStyle(AppColors.textPrimary)

                        Text(isOverflowing ? "+\(overflowMinutes)m past target (\(targetBedtime))" : "On track for optimal 8h recovery sleep")
                            .font(AppTypography.captionSmall)
                            .monospacedDigit()
                            .foregroundStyle(isOverflowing ? AppColors.warning : AppColors.textSecondary)
                    }
                }

                Spacer()

                // Warning / On-Track Badge
                if isOverflowing {
                    Text("+\(overflowMinutes)m")
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(AppColors.warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppColors.warning.opacity(0.12))
                        )
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                        Text("On Track")
                            .font(AppTypography.captionSmall)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(AppColors.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppColors.success.opacity(0.12))
                    )
                }
            }

            // Habit Progress Bar
            VStack(spacing: 4) {
                HStack {
                    Text("Habit Momentum")
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.textSecondary)

                    Spacer()

                    Text("\(completedHabits)/\(totalHabits) completed (\(habitProgressPercent)%)")
                        .font(AppTypography.captionSmall)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.primary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "E8E2F2"))
                            .frame(height: 6)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, Color(hex: "9F7AEA")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(habitProgressPercent) / 100)), height: 6)
                            .animation(AppMotion.standard, value: habitProgressPercent)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(isOverflowing ? AppColors.warning.opacity(0.3) : AppColors.surfaceBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}
