import SwiftUI

/// Calm completion experience (docs/specs/ios/focus-experience.md §15).
/// Shows the actual focused duration, the completed task, and an optional
/// local reflection. No gamification of any kind.
public struct FocusCompletionView: View {
    public enum Reflection: String, CaseIterable, Identifiable {
        case great, good, difficult

        public var id: String { rawValue }

        var title: String {
            switch self {
            case .great: return "Great"
            case .good: return "Good"
            case .difficult: return "Difficult"
            }
        }

        var icon: String {
            switch self {
            case .great: return "face.smiling.inverse"
            case .good: return "face.dashed"
            case .difficult: return "face.exhaling.inverse"
            }
        }
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false
    @State private var reflection: Reflection?

    private let focusedDurationSeconds: TimeInterval
    private let taskTitle: String?
    private let projectName: String?
    private let onDone: () -> Void

    public init(
        focusedDurationSeconds: TimeInterval,
        taskTitle: String? = nil,
        projectName: String? = nil,
        onDone: @escaping () -> Void = {}
    ) {
        self.focusedDurationSeconds = focusedDurationSeconds
        self.taskTitle = taskTitle
        self.projectName = projectName
        self.onDone = onDone
    }

    /// Precise duration, e.g. "42m 18s" or "1h 04m 12s".
    static func formatDetailedDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60

        if h > 0 { return String(format: "%dh %02dm %02ds", h, m, s) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return "\(s)s"
    }

    public var body: some View {
        ZStack {
            AppColors.canvas.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Spacer()

                // Completion emblem — calm checkmark
                ZStack {
                    Circle()
                        .fill(AppColors.primaryTint)
                        .frame(width: 88, height: 88)

                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityHidden(true)

                VStack(spacing: AppSpacing.xs) {
                    Text("Well done")
                        .font(AppTypography.largeTitle)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("You stayed focused.")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textSecondary)

                    Text(Self.formatDetailedDuration(focusedDurationSeconds))
                        .font(AppTypography.heroTimer)
                        .foregroundStyle(AppColors.primary)
                        .padding(.top, AppSpacing.sm)
                }

                if let taskTitle {
                    VStack(spacing: 2) {
                        Text(taskTitle)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textPrimary)
                        if let projectName {
                            Text(projectName)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .multilineTextAlignment(.center)
                }

                Spacer()

                reflectionSection

                AppButton(title: "Done", style: .primary, action: onDone)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared || reduceMotion ? 0 : 12)
        .animation(reduceMotion ? nil : AppMotion.large, value: hasAppeared)
        .onAppear {
            // One success haptic for completion — never during timer updates.
            Haptics.success()
            hasAppeared = true
        }
    }

    // MARK: - Optional Reflection (local only — no backend contract yet)

    private var reflectionSection: some View {
        VStack(spacing: AppSpacing.sm) {
            SectionHeaderView(title: "How did it feel?")

            HStack(spacing: AppSpacing.sm) {
                ForEach(Reflection.allCases) { option in
                    reflectionChip(option)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("How did it feel?")
    }

    private func reflectionChip(_ option: Reflection) -> some View {
        let isSelected = reflection == option

        return Button {
            withAnimation(reduceMotion ? nil : AppMotion.micro) {
                reflection = isSelected ? nil : option
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: option.icon)
                    .font(.system(size: 22, weight: .medium))
                Text(option.title)
                    .font(AppTypography.captionSmall)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(isSelected ? AppColors.primaryTint : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(isSelected ? AppColors.primary : AppColors.surfaceBorder, lineWidth: isSelected ? 2 : 1)
            )
            .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    FocusCompletionView(
        focusedDurationSeconds: 42 * 60 + 18,
        taskTitle: "Finish authentication",
        projectName: "Productivity OS"
    ) {}
}
