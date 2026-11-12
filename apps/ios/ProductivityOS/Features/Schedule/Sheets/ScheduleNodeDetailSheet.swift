import SwiftUI

/// Full inspection sheet for a selected schedule node (Spec AC-006, AC-008).
public struct ScheduleNodeDetailSheet: View {
    public let node: ScheduleNode
    public var onToggleHabit: (() -> Void)?
    public var onToggleFocus: (() -> Void)?
    public var onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    public init(
        node: ScheduleNode,
        onToggleHabit: (() -> Void)? = nil,
        onToggleFocus: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.node = node
        self.onToggleHabit = onToggleHabit
        self.onToggleFocus = onToggleFocus
        self.onDelete = onDelete
    }

    private var isAnchor: Bool {
        node.type == .anchor
    }

    private var isCompletedHabit: Bool {
        node.completed ?? false
    }

    private var inFocus: Bool {
        node.inFocus ?? false
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header Tag & Title
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(node.phase.defaultTitle.uppercased())
                                .font(AppTypography.captionSmall)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(AppColors.primaryTint))

                            Spacer()

                            if let time = node.time ?? node.targetTime {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 11))
                                    Text(time)
                                        .font(AppTypography.captionSmall)
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(AppColors.textSecondary)
                            }
                        }

                        Text(node.title)
                            .font(AppTypography.title)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.textPrimary)

                        if let subtitle = node.subtitle {
                            Text(subtitle)
                                .font(AppTypography.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }

                    Divider()

                    // Execution Primary Control Section
                    if node.type == .habit {
                        habitExecutionCard
                    } else if node.type == .task {
                        activityExecutionCard
                    } else if node.type == .anchor {
                        anchorCircadianCard
                    }

                    // 14-Day Consistency Matrix (for habits)
                    if node.type == .habit, let history = node.history, !history.isEmpty {
                        consistencyMatrixSection(history: history)
                    }

                    // Protocol Notes Section
                    if let notes = node.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Protocol Notes")
                                .font(AppTypography.headline)
                                .foregroundStyle(AppColors.textPrimary)

                            Text(notes)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                                .padding(AppSpacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: AppRadius.sm)
                                        .fill(Color(hex: "F8F7FB"))
                                )
                        }
                    }

                    // Metadata Card
                    metadataAttributesCard

                    // Destructive Delete Button (Protected for anchors)
                    if !isAnchor {
                        Button(role: .destructive) {
                            onDelete?()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete from Today")
                            }
                            .font(AppTypography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(hex: "EF4444"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .fill(Color(hex: "FEF2F2"))
                            )
                        }
                        .padding(.top, AppSpacing.sm)
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.canvas.ignoresSafeArea())
            .navigationTitle("Step Inspection")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Subcomponents

    private var habitExecutionCard: some View {
        HStack(spacing: 16) {
            Button {
                #if os(iOS)
                let feedback = UINotificationFeedbackGenerator()
                feedback.notificationOccurred(isCompletedHabit ? .warning : .success)
                #endif
                onToggleHabit?()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isCompletedHabit ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(isCompletedHabit ? AppColors.success : AppColors.primary)

                    Text(isCompletedHabit ? "Completed Today" : "Mark as Complete")
                        .font(AppTypography.headline)
                        .foregroundStyle(isCompletedHabit ? AppColors.success : AppColors.textPrimary)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(isCompletedHabit ? Color(hex: "F0FDF4") : AppColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(isCompletedHabit ? AppColors.success.opacity(0.3) : AppColors.surfaceBorder, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            if let streak = node.streak {
                VStack(spacing: 2) {
                    Text("🔥 \(streak)")
                        .font(AppTypography.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: "EA580C"))

                    Text("Day Streak")
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(Color(hex: "FFF7ED"))
                )
            }
        }
    }

    private var activityExecutionCard: some View {
        Button {
            onToggleFocus?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: inFocus ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(inFocus ? .white : AppColors.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(inFocus ? "Activity in Progress" : "Start Activity Block")
                        .font(AppTypography.headline)
                        .foregroundStyle(inFocus ? .white : AppColors.textPrimary)

                    Text(inFocus ? "Tracking natively on schedule canvas" : "Estimated \(node.durationMinutes ?? 60) minutes focus")
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(inFocus ? Color.white.opacity(0.8) : AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(inFocus ? AppColors.primary : AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(inFocus ? AppColors.primary : AppColors.surfaceBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var anchorCircadianCard: some View {
        HStack(spacing: 12) {
            Image(systemName: node.anchorKind == "wake" ? "sun.and.horizon.fill" : "bed.double.fill")
                .font(.system(size: 24))
                .foregroundStyle(AppColors.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(node.anchorKind == "wake" ? "Circadian Morning Baseline" : "Circadian Bedtime Sanctuary")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Text(node.anchorKind == "wake" ? "Anchors cortisol spike & resets biological clock." : "Protects deep sleep recovery & prevents sleep debt.")
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color(hex: "F5F3FF"))
        )
    }

    private func consistencyMatrixSection(history: [HabitStreakDay]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("14-Day Consistency Matrix")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text("Last 14 days")
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(history) { day in
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(day.completed ? AppColors.success : Color(hex: "E2E8F0"))
                                .frame(height: 32)

                            if day.completed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }

                        Text(String(day.date.suffix(2)))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.surfaceBorder, lineWidth: 1)
                )
        )
    }

    private var metadataAttributesCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Phase")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text(node.phase.defaultTitle)
                    .font(AppTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)
            }

            if let duration = node.durationMinutes {
                HStack {
                    Text("Duration")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Text("\(duration) minutes")
                        .font(AppTypography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.textPrimary)
                }
            }

            if let priority = node.priority {
                HStack {
                    Text("Priority")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Text(priority)
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.surfaceBorder, lineWidth: 1)
                )
        )
    }
}
