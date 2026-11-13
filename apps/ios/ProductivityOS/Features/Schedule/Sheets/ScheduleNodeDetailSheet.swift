import SwiftUI

/// Full inspection sheet for a selected schedule node (Spec AC-006, AC-008, AC-010).
public struct ScheduleNodeDetailSheet: View {
    @State private var currentNode: ScheduleNode
    @State private var isShowingEditSheet = false

    public var onToggleHabit: (() -> Void)?
    public var onToggleFocus: (() -> Void)?
    public var onDelete: (() -> Void)?
    public var onUpdate: ((UpdateStepPayload) -> Void)?
    @Environment(\.dismiss) private var dismiss

    public var node: ScheduleNode {
        currentNode
    }

    public init(
        node: ScheduleNode,
        onToggleHabit: (() -> Void)? = nil,
        onToggleFocus: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onUpdate: ((UpdateStepPayload) -> Void)? = nil
    ) {
        self._currentNode = State(initialValue: node)
        self.onToggleHabit = onToggleHabit
        self.onToggleFocus = onToggleFocus
        self.onDelete = onDelete
        self.onUpdate = onUpdate
    }

    private var isAnchor: Bool {
        currentNode.type == .anchor || currentNode.anchorKind != nil || currentNode.id.hasPrefix("anchor-")
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
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(time)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .monospacedDigit()
                                }
                                .foregroundStyle(AppColors.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(AppColors.primaryTint))
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

                    // Prominent Hero Time & Duration Block
                    timeAndDurationHeroCard

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

                    // Edit Step Button (Protected for anchors)
                    if !isAnchor && onUpdate != nil {
                        Button {
                            isShowingEditSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "pencil")
                                Text("Edit Step Details")
                            }
                            .font(AppTypography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .fill(AppColors.primary)
                            )
                        }
                        .padding(.top, AppSpacing.sm)
                    }

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
                        .padding(.top, AppSpacing.xs)
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
                if !isAnchor && onUpdate != nil {
                    #if os(iOS)
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Edit") {
                            isShowingEditSheet = true
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.primary)
                    }
                    #else
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Edit") {
                            isShowingEditSheet = true
                        }
                    }
                    #endif
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $isShowingEditSheet) {
                ScheduleEditStepSheet(node: currentNode) { payload in
                    applyUpdatePayload(payload)
                    onUpdate?(payload)
                }
            }
        }
    }

    private func applyUpdatePayload(_ payload: UpdateStepPayload) {
        var updated = currentNode
        updated.title = payload.title
        if let sub = payload.subtitle { updated.subtitle = sub }
        if let phase = payload.phaseId { updated.phase = phase }
        if let time = payload.timeSlot {
            updated.time = time
            if updated.type == .habit { updated.targetTime = time }
        }
        if let duration = payload.durationMinutes {
            updated.durationMinutes = duration
            if updated.type == .task { updated.totalMinutes = duration }
        }
        if let notes = payload.notes { updated.notes = notes }
        if let icon = payload.iconName, updated.type == .habit { updated.icon = icon }
        currentNode = updated
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

    // MARK: - Time & Duration Hero Block

    @ViewBuilder
    private var timeAndDurationHeroCard: some View {
        let startTime = node.time ?? node.targetTime
        let duration = node.durationMinutes
        let calculatedEnd = (startTime != nil && duration != nil) ? calculateEndTime(startTime: startTime!, durationMinutes: duration!) : nil
        let endTime = calculatedEnd ?? node.projectedTime

        if startTime != nil || duration != nil {
            VStack(spacing: 14) {
                // Top Header Row
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.badge.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppColors.primary)

                        Text("TIME & DURATION")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primary)
                            .tracking(0.6)
                    }

                    Spacer()

                    if let duration {
                        HStack(spacing: 4) {
                            Image(systemName: "hourglass")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(duration) min")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppColors.primaryTint))
                    }
                }

                // Center Hero Time Row
                if let startTime, let endTime {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("START")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.textTertiary)
                                .tracking(0.5)

                            Text(startTime)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(AppColors.textPrimary)
                        }

                        Spacer()

                        VStack(spacing: 3) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppColors.primary)

                            if let duration {
                                Text(formatDuration(duration))
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, 8)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(node.type == .anchor ? "PROJECTED" : "END")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.textTertiary)
                                .tracking(0.5)

                            Text(endTime)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }
                    .padding(.vertical, 2)

                    // Visual Duration Timeline Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "F1F5F9"))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "818CF8"), AppColors.primary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geo.size.width * min(1.0, Double(duration ?? 30) / 120.0), 28), height: 8)
                        }
                    }
                    .frame(height: 8)

                    // Timeline footer labels
                    HStack {
                        Text(startTime)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(AppColors.textSecondary)

                        Spacer()

                        if let duration {
                            Text("\(duration) minute allocated window")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        Spacer()

                        Text(endTime)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(AppColors.textSecondary)
                    }
                } else if let startTime {
                    // Start time only (e.g. Wake anchor)
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("SCHEDULED MILESTONE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.textTertiary)
                                .tracking(0.5)

                            Text(startTime)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(AppColors.textPrimary)
                        }

                        Spacer()

                        Image(systemName: node.anchorKind == "wake" ? "sun.horizon.fill" : "clock.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(AppColors.primary.opacity(0.8))
                    }
                } else if let duration {
                    // Duration only
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("ESTIMATED DURATION")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.textTertiary)
                                .tracking(0.5)

                            Text("\(duration) min")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(AppColors.textPrimary)
                        }

                        Spacer()

                        Image(systemName: "timer")
                            .font(.system(size: 32))
                            .foregroundStyle(AppColors.primary.opacity(0.8))
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(AppColors.surfaceBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    private func calculateEndTime(startTime: String, durationMinutes: Int) -> String? {
        let clean = startTime.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = clean.components(separatedBy: ":")
        guard parts.count >= 2,
              let startHours = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let startMins = Int(parts[1].prefix(2).trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        let totalStartMinutes = (startHours * 60) + startMins
        let totalEndMinutes = (totalStartMinutes + durationMinutes) % (24 * 60)
        let endHours = totalEndMinutes / 60
        let endMins = totalEndMinutes % 60
        return String(format: "%02d:%02d", endHours, endMins)
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let remaining = minutes % 60
            return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
        }
        return "\(minutes)m"
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

            if let time = node.time ?? node.targetTime {
                HStack {
                    Text("Scheduled Time")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Text(time)
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(AppColors.textPrimary)
                }
            }

            if let duration = node.durationMinutes {
                HStack {
                    Text("Duration")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Text("\(duration) minutes")
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                        .monospacedDigit()
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
