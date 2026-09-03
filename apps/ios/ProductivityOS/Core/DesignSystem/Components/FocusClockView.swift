import SwiftUI

/// Reusable circular clipping / ring clock matching `focsu-flow.png` and `today.png`.
/// The ring and the digits are two presentations of the same session state:
/// both values arrive already computed from `FocusSessionState` timestamps.
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

    public init(
        progress: Double,
        timerText: String,
        taskTitle: String? = nil,
        projectName: String? = nil,
        durationLabel: String? = nil,
        isPaused: Bool = false,
        variant: SizeVariant = .hero
    ) {
        self.progress = max(0.0, min(1.0, progress))
        self.timerText = timerText
        self.taskTitle = taskTitle
        self.projectName = projectName
        self.durationLabel = durationLabel
        self.isPaused = isPaused
        self.variant = variant
    }

    /// Linear glide between timestamp-derived values keeps the ring smooth
    /// without making the animation the source of truth.
    private var progressAnimation: Animation? {
        reduceMotion ? nil : AppMotion.ringTick
    }

    public var body: some View {
        switch variant {
        case .mini:
            miniClockView
        case .hero:
            heroClockView
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Focus timer")
                .accessibilityValue("\(timerText). \(taskTitle ?? "")")
                .accessibilityHint(isPaused ? "Session is paused" : "")
        }
    }

    // MARK: - Mini Clock (Today Screen Card)
    private var miniClockView: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(AppColors.primary.opacity(0.12), lineWidth: 8)

            // Progress arc
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    AppColors.primary,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(progressAnimation, value: progress)

            // Center content
            VStack(spacing: 2) {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primary)

                Text(timerText)
                    .font(AppTypography.miniTimer)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text("focused today")
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Hero Clock (Active & Paused Focus Screen)
    private var heroClockView: some View {
        ZStack {
            // Ticks background circle
            ClockTicksView()
                .frame(width: 290, height: 290)
                .opacity(0.4)

            // Unfilled track
            Circle()
                .stroke(AppColors.focusRingTrack, lineWidth: 22)
                .frame(width: 260, height: 260)

            // Outer glow while actively focusing — opacity animates so it
            // never pops in/out at tick boundaries.
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    AppColors.primary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 30, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: 8)
                .opacity(!isPaused && progress > 0.01 ? 1 : 0)
                .animation(reduceMotion ? nil : AppMotion.standard, value: isPaused)
                .animation(progressAnimation, value: progress)

            // Active Progress arc
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    isPaused ? AnyShapeStyle(Color(hex: "9B7BF7")) : AnyShapeStyle(AppColors.focusRingGradient),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 260, height: 260)
                .animation(progressAnimation, value: progress)
                .animation(reduceMotion ? nil : AppMotion.standard, value: isPaused)

            // Center info
            VStack(spacing: AppSpacing.lg,) {
                

                if let projectName {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 6, height: 6)
                        Text(projectName)
                            .font(AppTypography.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                // Big Hero Timer digits
                Text(timerText)
                    .font(AppTypography.heroTimer)
                    .foregroundStyle(.white)
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .animation(reduceMotion ? nil : AppMotion.standard, value: timerText)
   
                // Duration Mode Pill
                if let durationLabel {
                    HStack(spacing: 4) {
                        Image(systemName: "infinity")
                            .font(.system(size: 11, weight: .bold))
                        Text(durationLabel)
                            .font(AppTypography.captionSmall)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .foregroundStyle(.white.opacity(0.85))
                    .clipShape(Capsule())
                    
                }
            }
            .frame(width: 210)
        }
        .frame(width: 300, height: 300)
    }
}

/// Circular ticks decoration for the hero focus clock
private struct ClockTicksView: View {
    let tickCount = 60

    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            Path { path in
                for i in 0..<tickCount {
                    let angle = Double(i) * (2 * Double.pi / Double(tickCount))
                    let isMajor = i % 5 == 0
                    let innerRadius = radius - (isMajor ? 8 : 4)

                    let startX = center.x + CGFloat(cos(angle)) * innerRadius
                    let startY = center.y + CGFloat(sin(angle)) * innerRadius
                    let endX = center.x + CGFloat(cos(angle)) * radius
                    let endY = center.y + CGFloat(sin(angle)) * radius

                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
            }
            .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
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
    .background(AppColors.canvas)
}

#Preview("Hero Clock Running") {
    FocusClockView(
        progress: 0.45,
        timerText: "42:18",
        taskTitle: "Finish authentication",
        projectName: "Productivity OS",
        durationLabel: "Unlimited",
        isPaused: false,
        variant: .hero
    )
    .padding(40)
    .background(AppColors.focusCanvas)
}
