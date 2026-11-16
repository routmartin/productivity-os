import SwiftUI

/// Clock theme variations for the Mooas Flip Clock.
public enum MooasClockTheme: Sendable {
    case naturalBeech  // Authentic light beech wood, white barrel, ivory cards, graphite digits
    case darkWalnut    // Deep walnut wood, dark charcoal barrel & cards, candlelight cream digits
}

/// Size variant for the Mooas Flip Clock.
public enum MooasClockVariant: Sendable {
    case hero  // Full active focus desk instrument (~320pt wide)
    case mini  // Compact card / widget desk clock (~115pt wide)
}

/// Parser for timer display strings into two split-flap drum values with sublabels.
public struct MooasTimerComponents: Equatable, Sendable {
    public let leftValue: String
    public let rightValue: String
    public let leftSublabel: String
    public let rightSublabel: String

    public init(leftValue: String, rightValue: String, leftSublabel: String, rightSublabel: String) {
        self.leftValue = leftValue
        self.rightValue = rightValue
        self.leftSublabel = leftSublabel
        self.rightSublabel = rightSublabel
    }

    public static func parse(_ timerText: String) -> MooasTimerComponents {
        let trimmed = timerText.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Colon-separated format ("MM:SS" or "HH:MM:SS")
        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":").map(String.init)
            if parts.count == 2 {
                return MooasTimerComponents(
                    leftValue: parts[0],
                    rightValue: parts[1],
                    leftSublabel: "MIN",
                    rightSublabel: "SEC"
                )
            } else if parts.count >= 3 {
                // For sessions >= 1 hour, show HH : MM on the main drums
                return MooasTimerComponents(
                    leftValue: parts[0],
                    rightValue: parts[1],
                    leftSublabel: "HR",
                    rightSublabel: "MIN"
                )
            }
        }

        // 2. "Xh Ym" format (e.g. from TodayView stats)
        if trimmed.contains("h") || trimmed.contains("m") {
            var hours = 0
            var minutes = 0
            let scanner = Scanner(string: trimmed.lowercased())
            if let h = scanner.scanInt() {
                if scanner.scanString("h") != nil {
                    hours = h
                    if let m = scanner.scanInt() {
                        minutes = m
                    }
                } else if scanner.scanString("m") != nil {
                    minutes = h
                }
            }
            if hours > 0 {
                return MooasTimerComponents(
                    leftValue: String(format: "%02d", hours),
                    rightValue: String(format: "%02d", minutes),
                    leftSublabel: "HR",
                    rightSublabel: "MIN"
                )
            } else {
                return MooasTimerComponents(
                    leftValue: String(format: "%02d", minutes),
                    rightValue: "00",
                    leftSublabel: "MIN",
                    rightSublabel: "SEC"
                )
            }
        }

        // 3. Fallback for raw numbers or unexpected formats
        let digits = trimmed.filter(\.isNumber)
        if digits.count >= 4 {
            let left = String(digits.prefix(2))
            let right = String(digits.dropFirst(2).prefix(2))
            return MooasTimerComponents(leftValue: left, rightValue: right, leftSublabel: "MIN", rightSublabel: "SEC")
        } else if digits.count == 2 {
            return MooasTimerComponents(leftValue: digits, rightValue: "00", leftSublabel: "MIN", rightSublabel: "SEC")
        }

        return MooasTimerComponents(leftValue: "25", rightValue: "00", leftSublabel: "MIN", rightSublabel: "SEC")
    }
}

/// Authentic, battery-efficient Mooas Automatic Mini Flip Clock component.
/// Modeled faithfully after the physical Mooas split-flap desk clock:
/// - Twin split-flap cylindrical drums with fanned leaf edges and top clips.
/// - Mechanical split-flap motion with horizontal equator card seam.
/// - White barrel drum with side axle brackets and circular pivot hubs.
/// - Natural beech wood rectangular pedestal block base with soft rounded bevels and contact shadow.
/// - Bold, high-contrast mechanical typography.
public struct MooasFlipClockView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let timerText: String
    private let progress: Double
    private let isPaused: Bool
    private let variant: MooasClockVariant
    private let theme: MooasClockTheme
    private let onTap: (() -> Void)?

    public init(
        timerText: String,
        progress: Double = 0.0,
        isPaused: Bool = false,
        variant: MooasClockVariant = .hero,
        theme: MooasClockTheme = .naturalBeech,
        onTap: (() -> Void)? = nil
    ) {
        self.timerText = timerText
        self.progress = max(0.0, min(1.0, progress))
        self.isPaused = isPaused
        self.variant = variant
        self.theme = theme
        self.onTap = onTap
    }

    private var parsed: MooasTimerComponents {
        MooasTimerComponents.parse(timerText)
    }

    private var isMini: Bool {
        variant == .mini
    }

    // Proportional dimensions based on variant
    private var drumWidth: CGFloat { isMini ? 42 : 124 }
    private var drumHeight: CGFloat { isMini ? 48 : 136 }
    private var drumSpacing: CGFloat { isMini ? 3 : 10 }
    private var pedestalWidth: CGFloat { isMini ? 110 : 318 }
    private var pedestalHeight: CGFloat { isMini ? 14 : 36 }
    private var bracketArmWidth: CGFloat { isMini ? 8 : 22 }

    public var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 0) {
                // Upper Section: Barrel Drums and Side Axle Brackets
                ZStack(alignment: .bottom) {
                    // Side Brackets & Central Axle
                    axleBracketsView
                        .frame(width: pedestalWidth, height: drumHeight + (isMini ? 4 : 10))

                    // Twin Mechanical Drums (Left: Minutes/Hours, Right: Seconds/Minutes)
                    HStack(spacing: drumSpacing) {
                        MooasDrumCardView(
                            value: parsed.leftValue,
                            sublabel: parsed.leftSublabel,
                            width: drumWidth,
                            height: drumHeight,
                            isMini: isMini,
                            theme: theme,
                            isPaused: isPaused
                        )

                        MooasDrumCardView(
                            value: parsed.rightValue,
                            sublabel: parsed.rightSublabel,
                            width: drumWidth,
                            height: drumHeight,
                            isMini: isMini,
                            theme: theme,
                            isPaused: isPaused
                        )
                    }
                    .offset(y: isMini ? -2 : -6)
                }

                // Lower Section: Natural Solid Beech Wood Pedestal Base
                woodPedestalView
            }
            .frame(width: pedestalWidth)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mooas flip clock timer")
        .accessibilityValue("\(timerText)\(isPaused ? ", paused" : "")")
        .accessibilityHint(onTap != nil ? "Double tap to pause or resume focus session" : "")
    }

    // MARK: - Axle Brackets & Side Hardware

    private var axleBracketsView: some View {
        ZStack {
            // Under-drum stabilizer mounting feet
            HStack(spacing: drumWidth * 0.7) {
                stabilizerFoot
                stabilizerFoot
            }
            .offset(y: isMini ? 2 : 4)

            // Outer molded white bracket hubs
            HStack {
                sideBracketArm(isLeft: true)
                Spacer()
                sideBracketArm(isLeft: false)
            }
        }
    }

    private var stabilizerFoot: some View {
        RoundedRectangle(cornerRadius: isMini ? 1 : 2)
            .fill(Color(hex: "DFDAD0"))
            .frame(width: isMini ? 8 : 20, height: isMini ? 4 : 8)
    }

    private func sideBracketArm(isLeft: Bool) -> some View {
        let hubDiameter: CGFloat = isMini ? 12 : 32
        let pinDiameter: CGFloat = isMini ? 4 : 10

        return ZStack(alignment: isLeft ? .leading : .trailing) {
            // Angled molded support strut
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: isMini ? 1.5 : 4)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FFFFFF"), Color(hex: "EFECE6")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: bracketArmWidth, height: drumHeight * 0.55)
                    .overlay(
                        RoundedRectangle(cornerRadius: isMini ? 1.5 : 4)
                            .stroke(Color(hex: "E0DBD1"), lineWidth: 0.5)
                    )
            }

            // Circular axle pivot hub cap
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "FFFFFF"), Color(hex: "ECE8DF")],
                        center: .center,
                        startRadius: 1,
                        endRadius: hubDiameter / 2
                    )
                )
                .frame(width: hubDiameter, height: hubDiameter)
                .overlay(
                    Circle().stroke(Color(hex: "DAD4C8"), lineWidth: 0.75)
                )
                .overlay(
                    // Center metallic pivot pin
                    Circle()
                        .fill(Color(hex: "C2BCB0"))
                        .frame(width: pinDiameter, height: pinDiameter)
                )
                .shadow(color: Color.black.opacity(0.08), radius: isMini ? 1 : 3, x: isLeft ? -1 : 1, y: 1)
                .offset(y: -(drumHeight * 0.08))
        }
        .frame(width: bracketArmWidth)
    }

    // MARK: - Solid Beech Wood Pedestal

    private var woodPedestalView: some View {
        let cornerRadius: CGFloat = isMini ? 3.5 : 8
        let topBevelHeight: CGFloat = isMini ? 3 : 7

        return VStack(spacing: 0) {
            // Discreet Progress Inlay Bar (along the top lip of the wood base)
            if progress > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.08))
                            .frame(height: isMini ? 1.5 : 2.5)

                        Capsule()
                            .fill(AppColors.cozyAccent)
                            .frame(width: max(4, geo.size.width * CGFloat(progress)), height: isMini ? 1.5 : 2.5)
                    }
                }
                .frame(height: isMini ? 1.5 : 2.5)
                .padding(.horizontal, isMini ? 6 : 14)
                .offset(y: isMini ? 1 : 2)
                .zIndex(2)
            }

            // The 3D Wood Pedestal Block
            ZStack(alignment: .top) {
                // Main wood block body
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: theme == .naturalBeech
                                ? [AppColors.woodPedestalLight, AppColors.woodPedestalBevel]
                                : [AppColors.woodPedestalDark, Color(hex: "302318")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        // Subtle top chamfer bevel highlight
                        VStack {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.35), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: topBevelHeight)
                            Spacer()
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                theme == .naturalBeech ? Color(hex: "B58757").opacity(0.5) : Color(hex: "271C13"),
                                lineWidth: 0.5
                            )
                    )

                // Muted "mooas" authentic engraved brand logo centered on front face
               
            }
            .frame(width: pedestalWidth, height: pedestalHeight)
            // Realistic ground drop shadow on desk surface
            .shadow(
                color: Color.black.opacity(isMini ? 0.12 : 0.22),
                radius: isMini ? 4 : 12,
                x: 0,
                y: isMini ? 2 : 7
            )
        }
    }
}

/// An individual mechanical split-flap cylindrical drum showing two digits.
public struct MooasDrumCardView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let value: String
    private let sublabel: String?
    private let width: CGFloat
    private let height: CGFloat
    private let isMini: Bool
    private let theme: MooasClockTheme
    private let isPaused: Bool

    // Flip animation states
    @State private var displayedValue: String
    @State private var previousValue: String
    @State private var flipProgress: Double = 0.0
    @State private var isFlipping: Bool = false
    @State private var activeFlipId: UUID = UUID()

    public init(
        value: String,
        sublabel: String? = nil,
        width: CGFloat,
        height: CGFloat,
        isMini: Bool,
        theme: MooasClockTheme,
        isPaused: Bool
    ) {
        self.value = value
        self.sublabel = sublabel
        self.width = width
        self.height = height
        self.isMini = isMini
        self.theme = theme
        self.isPaused = isPaused
        self._displayedValue = State(initialValue: value)
        self._previousValue = State(initialValue: value)
    }

    private var seamHeight: CGFloat { isMini ? 1.0 : 1.5 }
    private var halfHeight: CGFloat { (height - seamHeight) / 2 }
    private var cornerRadius: CGFloat { isMini ? 3.0 : 7.0 }

    public var body: some View {
        ZStack {
            // Background Cylindrical Fanned-Leaf Drum Stack
            drumLeafStackBackground

            // The Split-Flap Cards Assembly (Stationary Base)
            VStack(spacing: seamHeight) {
                // Top Flap Container (Stationary)
                // When flipping: shows the target (displayedValue) underneath the falling flap
                // When at rest: shows the current displayedValue
                MooasCardHalfView(
                    digit: displayedValue,
                    isTop: true,
                    sublabel: nil,
                    width: width,
                    height: height,
                    halfHeight: halfHeight,
                    cornerRadius: cornerRadius,
                    theme: theme,
                    isMini: isMini
                )

                // Bottom Flap Container (Stationary)
                // When flipping: shows the previousValue until the new flap lands
                // When at rest: shows the current displayedValue
                MooasCardHalfView(
                    digit: isFlipping ? previousValue : displayedValue,
                    isTop: false,
                    sublabel: sublabel,
                    width: width,
                    height: height,
                    halfHeight: halfHeight,
                    cornerRadius: cornerRadius,
                    theme: theme,
                    isMini: isMini
                )
            }
            .frame(width: width, height: height)

            // Overlaid 3D Flipping Flap (Animatable frame-by-frame)
            if isFlipping {
                MooasFlipFlapView(
                    progress: flipProgress,
                    oldDigit: previousValue,
                    newDigit: displayedValue,
                    sublabel: sublabel,
                    width: width,
                    height: height,
                    halfHeight: halfHeight,
                    seamHeight: seamHeight,
                    cornerRadius: cornerRadius,
                    theme: theme,
                    isMini: isMini
                )
                .zIndex(1)
            }

            // Top Retaining Mechanical Clips (holding top card until flap)
            topRetainingClips
                .zIndex(2)
        }
        .frame(width: width, height: height)
        .opacity(isPaused ? 0.75 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isPaused)
        .onChange(of: value) { oldValue, newValue in
            guard oldValue != newValue else { return }
            if reduceMotion {
                displayedValue = newValue
                previousValue = newValue
                isFlipping = false
                flipProgress = 0.0
            } else {
                triggerFlip(from: displayedValue, to: newValue)
            }
        }
    }

    private func triggerFlip(from old: String, to new: String) {
        let flipId = UUID()
        activeFlipId = flipId
        previousValue = old
        displayedValue = new
        flipProgress = 0.0
        isFlipping = true

        withAnimation(.easeInOut(duration: 0.30)) {
            flipProgress = 1.0
        } completion: {
            guard activeFlipId == flipId else { return }
            previousValue = new
            isFlipping = false
            flipProgress = 0.0
        }
    }

    // MARK: - Cylindrical Fanned-Leaf Drum Stack

    private var drumLeafStackBackground: some View {
        let fannedLipHeight: CGFloat = isMini ? 4 : 10

        return VStack(spacing: 0) {
            // Top cylindrical leaf fan
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(theme == .naturalBeech ? Color(hex: "E6E2D8") : Color(hex: "201E1D"))
                    .frame(width: width, height: fannedLipHeight)

                // Leaf ridges (subtle horizontal notched lines)
                VStack(spacing: isMini ? 1.0 : 2.0) {
                    ForEach(0..<(isMini ? 2 : 3), id: \.self) { _ in
                        Rectangle()
                            .fill(Color.black.opacity(0.08))
                            .frame(height: 0.5)
                    }
                }
                .padding(.bottom, 1)
            }

            Spacer()

            // Bottom cylindrical leaf fan
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(theme == .naturalBeech ? Color(hex: "D9D4C8") : Color(hex: "1C1A19"))
                    .frame(width: width, height: fannedLipHeight)

                VStack(spacing: isMini ? 1.0 : 2.0) {
                    ForEach(0..<(isMini ? 2 : 3), id: \.self) { _ in
                        Rectangle()
                            .fill(Color.black.opacity(0.08))
                            .frame(height: 0.5)
                    }
                }
                .padding(.top, 1)
            }
        }
        .frame(width: width, height: height + (isMini ? 4 : 12))
    }

    // MARK: - Top Retaining Clips

    private var topRetainingClips: some View {
        let clipWidth: CGFloat = isMini ? 4 : 10
        let clipHeight: CGFloat = isMini ? 3 : 8

        return VStack {
            HStack {
                retainingClip(width: clipWidth, height: clipHeight)
                    .padding(.leading, isMini ? 2 : 6)
                Spacer()
                retainingClip(width: clipWidth, height: clipHeight)
                    .padding(.trailing, isMini ? 2 : 6)
            }
            .offset(y: -(isMini ? 1 : 2))
            Spacer()
        }
    }

    private func retainingClip(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: isMini ? 0.75 : 1.5)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "FFFFFF"), Color(hex: "E8E4DC")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: isMini ? 0.75 : 1.5)
                    .stroke(Color(hex: "D8D4CC"), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

/// A precision-split card half (top or bottom) for split-flap drum displays.
/// Cuts a single tall digit block precisely at the horizontal equator seam.
public struct MooasCardHalfView: View {
    public let digit: String
    public let isTop: Bool
    public let sublabel: String?
    public let width: CGFloat
    public let height: CGFloat
    public let halfHeight: CGFloat
    public let cornerRadius: CGFloat
    public let theme: MooasClockTheme
    public let isMini: Bool

    public init(
        digit: String,
        isTop: Bool,
        sublabel: String? = nil,
        width: CGFloat,
        height: CGFloat,
        halfHeight: CGFloat,
        cornerRadius: CGFloat,
        theme: MooasClockTheme,
        isMini: Bool
    ) {
        self.digit = digit
        self.isTop = isTop
        self.sublabel = sublabel
        self.width = width
        self.height = height
        self.halfHeight = halfHeight
        self.cornerRadius = cornerRadius
        self.theme = theme
        self.isMini = isMini
    }

    private var cardBackground: Color {
        theme == .naturalBeech ? AppColors.flapCardLight : AppColors.flapCardDark
    }

    private var cardBorder: Color {
        theme == .naturalBeech ? AppColors.flapCardBorder : Color(hex: "383431")
    }

    private var digitColor: Color {
        theme == .naturalBeech ? AppColors.flapTextDark : AppColors.flapTextLight
    }

    private var digitFont: Font {
        .system(
            size: isMini ? 28 : 78,
            weight: .bold,
            design: .rounded
        ).monospacedDigit()
    }

    public var body: some View {
        ZStack {
            // Card Half Shape (rounded outer corners, flat equator edge)
            cardHalfShape

            // Digit Text Container (Centered at the equator seam line)
            // Top card: offset down by halfHeight / 2 -> center is at bottom edge (equator)
            // Bottom card: offset up by halfHeight / 2 -> center is at top edge (equator)
            Text(digit)
                .font(digitFont)
                .foregroundStyle(digitColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: width, height: halfHeight * 2, alignment: .center)
                .offset(y: isTop ? halfHeight / 2 : -halfHeight / 2)

            // Corner Sublabel (e.g. "MIN", "SEC", "HR")
            if !isTop, let sublabel, !sublabel.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Text(sublabel)
                            .font(.system(size: isMini ? 6 : 8, weight: .bold, design: .rounded))
                            .foregroundStyle(digitColor.opacity(0.40))
                            .padding(.leading, isMini ? 3 : 7)
                            .padding(.bottom, isMini ? 2 : 5)
                        Spacer()
                    }
                }
            }
        }
        .frame(width: width, height: halfHeight)
        .clipped()
    }

    private var cardHalfShape: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: isTop ? cornerRadius : 0,
            bottomLeadingRadius: isTop ? 0 : cornerRadius,
            bottomTrailingRadius: isTop ? 0 : cornerRadius,
            topTrailingRadius: isTop ? cornerRadius : 0
        )
        .fill(
            LinearGradient(
                colors: isTop
                    ? (theme == .naturalBeech
                        ? [Color(hex: "FFFFFF"), cardBackground]
                        : [Color(hex: "2E2B29"), cardBackground])
                    : (theme == .naturalBeech
                        ? [Color(hex: "F2EFE8"), cardBackground]
                        : [Color(hex: "1F1C1B"), cardBackground]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: isTop ? cornerRadius : 0,
                bottomLeadingRadius: isTop ? 0 : cornerRadius,
                bottomTrailingRadius: isTop ? 0 : cornerRadius,
                topTrailingRadius: isTop ? cornerRadius : 0
            )
            .stroke(cardBorder, lineWidth: 0.5)
        )
    }
}

/// Animatable 3D split-flap transition component.
/// Driven frame-by-frame by SwiftUI animation engine using Animatable protocol.
public struct MooasFlipFlapView: View, Animatable {
    public var progress: Double // 0.0 -> 1.0
    public let oldDigit: String
    public let newDigit: String
    public let sublabel: String?
    public let width: CGFloat
    public let height: CGFloat
    public let halfHeight: CGFloat
    public let seamHeight: CGFloat
    public let cornerRadius: CGFloat
    public let theme: MooasClockTheme
    public let isMini: Bool

    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    public var body: some View {
        VStack(spacing: seamHeight) {
            // Top Flap Container (falling forward from 0° down to -90°)
            ZStack {
                if progress < 0.5 {
                    MooasCardHalfView(
                        digit: oldDigit,
                        isTop: true,
                        sublabel: nil,
                        width: width,
                        height: height,
                        halfHeight: halfHeight,
                        cornerRadius: cornerRadius,
                        theme: theme,
                        isMini: isMini
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: cornerRadius,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: cornerRadius
                        )
                        .fill(Color.black.opacity(progress * 0.55))
                    )
                    .rotation3DEffect(
                        .degrees(-progress * 180),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .bottom,
                        perspective: 0.35
                    )
                }
            }
            .frame(width: width, height: halfHeight)

            // Bottom Flap Container (landing flat from 90° down to 0°)
            ZStack {
                if progress >= 0.5 {
                    MooasCardHalfView(
                        digit: newDigit,
                        isTop: false,
                        sublabel: sublabel,
                        width: width,
                        height: height,
                        halfHeight: halfHeight,
                        cornerRadius: cornerRadius,
                        theme: theme,
                        isMini: isMini
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: cornerRadius,
                            bottomTrailingRadius: cornerRadius,
                            topTrailingRadius: 0
                        )
                        .fill(Color.black.opacity((1.0 - progress) * 0.55))
                    )
                    .rotation3DEffect(
                        .degrees((1.0 - progress) * 180),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .top,
                        perspective: 0.35
                    )
                }
            }
            .frame(width: width, height: halfHeight)
        }
        .frame(width: width, height: height)
    }
}

#Preview("Mooas Hero - Natural Beech") {
    MooasFlipClockView(
        timerText: "25:00",
        progress: 0.35,
        variant: .hero,
        theme: .naturalBeech
    )
    .padding(40)
    .background(AppColors.cozyCanvasDark)
}

#Preview("Mooas Mini - Natural Beech") {
    MooasFlipClockView(
        timerText: "2h 18m",
        progress: 0.75,
        variant: .mini,
        theme: .naturalBeech
    )
    .padding(20)
    .background(AppColors.cozyCanvasLight)
}
