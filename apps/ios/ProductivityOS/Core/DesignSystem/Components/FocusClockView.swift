import SwiftUI

/// Reusable focus clock instrument matching the Mooas Automatic Mini Flip Clock aesthetic.
/// Replaces heavy continuous GPU blurs and 60fps canvas redraws with a clean,
/// energy-efficient mechanical split-flap desk instrument.
public struct FocusClockView: View {
    public enum SizeVariant {
        case mini
        case hero
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let progress: Double // 0.0 to 1.0
    private let timerText: String
    private let taskTitle: String?
    private let projectName: String?
    private let durationLabel: String?
    private let isPaused: Bool
    private let variant: SizeVariant
    private let onTap: (() -> Void)?

    public init(
        progress: Double,
        timerText: String,
        taskTitle: String? = nil,
        projectName: String? = nil,
        durationLabel: String? = nil,
        isPaused: Bool = false,
        variant: SizeVariant = .hero,
        onTap: (() -> Void)? = nil
    ) {
        self.progress = max(0.0, min(1.0, progress))
        self.timerText = timerText
        self.taskTitle = taskTitle
        self.projectName = projectName
        self.durationLabel = durationLabel
        self.isPaused = isPaused
        self.variant = variant
        self.onTap = onTap
    }

    public var body: some View {
        switch variant {
        case .mini:
            miniClockView
        case .hero:
            heroClockView
        }
    }

    // MARK: - Mini Clock (Today Screen Card / Compact Widget)
    private var miniClockView: some View {
        MooasFlipClockView(
            timerText: timerText,
            progress: progress,
            isPaused: isPaused,
            variant: .mini,
            theme: .naturalBeech,
            onTap: onTap
        )
    }

    // MARK: - Hero Clock (Active & Paused Focus Screen)
    private var heroClockView: some View {
        VStack(spacing: AppSpacing.md) {
            // Authentic Mooas Flip Clock Instrument
            MooasFlipClockView(
                timerText: timerText,
                progress: progress,
                isPaused: isPaused,
                variant: .hero,
                theme: .naturalBeech,
                onTap: onTap
            )

            // Duration Mode Pill
            if let durationLabel {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                        .font(.system(size: 11, weight: .semibold))
                    Text(durationLabel)
                        .font(AppTypography.captionSmall)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.12))
                .foregroundStyle(.white.opacity(0.9))
                .clipShape(Capsule())
            }
        }
    }
}

#Preview("Mini Clock") {
    FocusClockView(
        progress: 0.65,
        timerText: "2h 18m",
        variant: .mini
    )
    .padding()
    .background(AppColors.cozyCanvasLight)
}

#Preview("Hero Clock Running") {
    FocusClockView(
        progress: 0.45,
        timerText: "25:00",
        taskTitle: "Finish authentication",
        projectName: "Productivity OS",
        durationLabel: "Deep work",
        isPaused: false,
        variant: .hero
    )
    .padding(40)
    .background(AppColors.cozyCanvasDark)
}
