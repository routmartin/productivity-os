import SwiftUI

/// Activity block card with native active timer trigger (Spec AC-003).
public struct ScheduleActivityNodeView: View {
    public let node: ScheduleNode
    public var onToggleFocus: (() -> Void)?
    public var onTap: (() -> Void)?

    @State private var isPulsing = false

    public init(
        node: ScheduleNode,
        onToggleFocus: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.node = node
        self.onToggleFocus = onToggleFocus
        self.onTap = onTap
    }

    private var inFocus: Bool {
        node.inFocus ?? false
    }

    private var priorityColor: Color {
        switch node.priority {
        case "HIGH": return Color(hex: "EF4444")
        case "MEDIUM": return Color(hex: "F59E0B")
        default: return Color(hex: "3B82F6")
        }
    }

    public var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Header row: project name + priority pill + prominent duration badge
                HStack(spacing: 6) {
                    if let project = node.projectName {
                        Text(project)
                            .font(AppTypography.captionSmall)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.primary)
                    }

                    if let priority = node.priority {
                        Text(priority)
                            .font(AppTypography.captionSmall)
                            .fontWeight(.bold)
                            .foregroundStyle(priorityColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(priorityColor.opacity(0.12))
                            )
                    }

                    Spacer()

                    if let duration = node.durationMinutes {
                        HStack(spacing: 4) {
                            Image(systemName: "stopwatch.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(duration)m focus")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                        .foregroundStyle(inFocus ? AppColors.primary : Color(hex: "4338CA"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(
                            Capsule()
                                .fill(inFocus ? AppColors.primaryTint : Color(hex: "EEF2FF"))
                                .overlay(
                                    Capsule()
                                        .stroke(inFocus ? AppColors.primary.opacity(0.3) : Color(hex: "C7D2FE").opacity(0.6), lineWidth: 0.8)
                                )
                        )
                    }
                }

                // Title + Subtitle
                VStack(alignment: .leading, spacing: 3) {
                    Text(node.title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)

                    if let subtitle = node.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                // Execution Action Bar: High-visibility Scheduled Time + Focus Action
                HStack(alignment: .center) {
                    if inFocus {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isPulsing ? 1.3 : 0.8)
                                .opacity(isPulsing ? 1.0 : 0.5)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                        isPulsing = true
                                    }
                                }

                            Text("Active Focus")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.primary)

                            if let time = node.time {
                                Text("• \(time)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(AppColors.primary.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule()
                                .fill(AppColors.primaryTint)
                        )
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: "clock.badge.checkmark.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.primary)

                            Text(node.time ?? "09:00")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(AppColors.textPrimary)

                            if let duration = node.durationMinutes {
                                Text("(\(duration)m)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule()
                                .fill(Color(hex: "F3EFFF"))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: "DDD6FE"), lineWidth: 0.8)
                                )
                        )
                    }

                    Spacer()

                    // Quick start button
                    Button {
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        #endif
                        onToggleFocus?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: inFocus ? "pause.fill" : "play.fill")
                                .font(.system(size: 10, weight: .bold))

                            Text(inFocus ? "Pause" : "Start")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(inFocus ? .white : AppColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(inFocus ? AppColors.primary : AppColors.primaryTint)
                                .shadow(color: inFocus ? AppColors.primary.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(inFocus ? AppColors.primary : AppColors.surfaceBorder, lineWidth: inFocus ? 1.5 : 1)
                    )
                    .shadow(color: inFocus ? AppColors.primary.opacity(0.12) : Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }
}
