import SwiftUI

/// Circadian theme colors and iconography for schedule shifts.
public struct ScheduleShiftTheme: Sendable, Equatable {
    public let icon: String
    public let accentHex: String
    public let backgroundHex: String
    public let borderHex: String

    public var accent: Color { Color(hex: accentHex) }
    public var background: Color { Color(hex: backgroundHex) }
    public var border: Color { Color(hex: borderHex) }

    public init(icon: String, accentHex: String, backgroundHex: String, borderHex: String) {
        self.icon = icon
        self.accentHex = accentHex
        self.backgroundHex = backgroundHex
        self.borderHex = borderHex
    }

    public static func theme(for phaseId: SchedulePhaseId) -> ScheduleShiftTheme {
        switch phaseId {
        case .morning:
            return ScheduleShiftTheme(
                icon: "sun.max.fill",
                accentHex: "EA580C",
                backgroundHex: "FFF7ED",
                borderHex: "FDBA74"
            )
        case .afternoon:
            return ScheduleShiftTheme(
                icon: "bolt.fill",
                accentHex: "2563EB",
                backgroundHex: "EFF6FF",
                borderHex: "93C5FD"
            )
        case .bedtime:
            return ScheduleShiftTheme(
                icon: "moon.stars.fill",
                accentHex: "6366F1",
                backgroundHex: "EEF2FF",
                borderHex: "C7D2FE"
            )
        case .deepFocus:
            return ScheduleShiftTheme(
                icon: "brain.head.profile",
                accentHex: "7C3AED",
                backgroundHex: "F5F3FF",
                borderHex: "DDD6FE"
            )
        }
    }
}

extension SchedulePhaseId {
    public var shiftTheme: ScheduleShiftTheme {
        ScheduleShiftTheme.theme(for: self)
    }
}

/// Prominent, beautifully styled shift header section anchor for each phase in the daily schedule.
public struct ScheduleShiftHeaderView: View {
    public let phaseId: SchedulePhaseId
    public let title: String
    public let subtitle: String
    public let timeRange: String
    public let shiftNumber: Int?
    public let completedCount: Int
    public let totalCount: Int
    public var onAddStep: () -> Void

    public init(
        phaseId: SchedulePhaseId,
        title: String,
        subtitle: String,
        timeRange: String,
        shiftNumber: Int? = nil,
        completedCount: Int = 0,
        totalCount: Int = 0,
        onAddStep: @escaping () -> Void
    ) {
        self.phaseId = phaseId
        self.title = title
        self.subtitle = subtitle
        self.timeRange = timeRange
        self.shiftNumber = shiftNumber
        self.completedCount = completedCount
        self.totalCount = totalCount
        self.onAddStep = onAddStep
    }

    public init(
        phase: SchedulePhase,
        shiftNumber: Int? = nil,
        completedCount: Int = 0,
        totalCount: Int = 0,
        onAddStep: @escaping () -> Void
    ) {
        self.init(
            phaseId: phase.id,
            title: phase.title,
            subtitle: phase.subtitle,
            timeRange: phase.timeRange,
            shiftNumber: shiftNumber,
            completedCount: completedCount,
            totalCount: totalCount,
            onAddStep: onAddStep
        )
    }

    private var theme: ScheduleShiftTheme {
        phaseId.shiftTheme
    }

    public var kickerText: String {
        if let shiftNumber {
            if timeRange.isEmpty {
                return String(format: "SHIFT %02d", shiftNumber)
            }
            return String(format: "SHIFT %02d · %@", shiftNumber, timeRange)
        } else {
            if timeRange.isEmpty {
                return "DEEP FOCUS"
            }
            return "DEEP FOCUS · \(timeRange)"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Row 1: Prominent Eyebrow Pill + Add Step Action
            HStack(alignment: .center) {
                // Eyebrow Pill
                HStack(spacing: 5) {
                    Image(systemName: theme.icon)
                        .font(.system(size: 11, weight: .bold))

                    Text(kickerText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .tracking(0.5)
                        .textCase(.uppercase)
                }
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(theme.background)
                        .overlay(
                            Capsule().stroke(theme.border, lineWidth: 1)
                        )
                )

                Spacer()

                // + Add Step Action
                Button {
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    #endif
                    onAddStep()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))

                        Text("Add Step")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(theme.background)
                            .overlay(
                                Capsule().stroke(theme.border.opacity(0.8), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add step to \(title)")
            }

            // Row 2: Visual Accent Anchor + Major Section Title
            HStack(alignment: .center, spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.accent)
                    .frame(width: 3.5, height: 22)

                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()
            }

            // Row 3: Subtitle Description & Themed Progress Badge
            if !subtitle.isEmpty || totalCount > 0 {
                HStack(alignment: .center, spacing: 8) {
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }

                    Spacer(minLength: 6)

                    if totalCount > 0 {
                        if completedCount == totalCount {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .heavy))
                                Text("\(completedCount)/\(totalCount) completed")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(Color(hex: "059669"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "ECFDF5"))
                                    .overlay(Capsule().stroke(Color(hex: "A7F3D0"), lineWidth: 0.8))
                            )
                        } else {
                            HStack(spacing: 4) {
                                Text("\(completedCount)/\(totalCount) completed")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                            }
                            .foregroundStyle(theme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule()
                                    .fill(theme.background)
                                    .overlay(Capsule().stroke(theme.border.opacity(0.8), lineWidth: 0.8))
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }
}
