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
                // Header row: project name + priority pill + duration
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
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text("\(duration)m")
                                .font(AppTypography.captionSmall)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(AppColors.textSecondary)
                    }
                }

                // Title + Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)

                    if let subtitle = node.subtitle {
                        Text(subtitle)
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                // Execution Action Bar
                HStack {
                    HStack(spacing: 6) {
                        if inFocus {
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

                            Text("In Progress")
                                .font(AppTypography.captionSmall)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.primary)
                        } else {
                            Text("Scheduled: \(node.time ?? "09:00")")
                                .font(AppTypography.captionSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
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
                                .font(AppTypography.captionSmall)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(inFocus ? .white : AppColors.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(inFocus ? AppColors.primary : AppColors.primaryTint)
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
