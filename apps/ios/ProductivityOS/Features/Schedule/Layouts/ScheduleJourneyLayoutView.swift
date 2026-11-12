import SwiftUI

/// Serpentine Journey layout: 4-phase narrative S-flow with fluid illuminated curves (Spec AC-001).
public struct ScheduleJourneyLayoutView: View {
    @Bindable public var viewModel: ScheduleViewModel
    public var onSelectNode: (ScheduleNode) -> Void
    public var onAddStepInPhase: (SchedulePhaseId) -> Void

    public init(
        viewModel: ScheduleViewModel,
        onSelectNode: @escaping (ScheduleNode) -> Void,
        onAddStepInPhase: @escaping (SchedulePhaseId) -> Void
    ) {
        self.viewModel = viewModel
        self.onSelectNode = onSelectNode
        self.onAddStepInPhase = onAddStepInPhase
    }

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ForEach(Array(viewModel.phases.enumerated()), id: \.element.id) { phaseIndex, phase in
                VStack(spacing: 0) {
                    journeyPhaseCard(phase: phase, phaseNumber: phaseIndex + 1)

                    if phaseIndex < viewModel.phases.count - 1 {
                        serpentinePhaseConnector(isReversed: phaseIndex % 2 == 1)
                    }
                }
            }
        }
    }

    private func journeyPhaseCard(phase: SchedulePhase, phaseNumber: Int) -> some View {
        let phaseNodes = viewModel.nodes.filter { $0.phase == phase.id }
        let completedCount = phaseNodes.filter { $0.completed ?? false }.count
        let totalCount = phaseNodes.count

        return VStack(alignment: .leading, spacing: 12) {
            // Journey Phase Header
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 26, height: 26)

                        Text("\(phaseNumber)")
                            .font(AppTypography.captionSmall)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase.title)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textPrimary)

                        Text(phase.subtitle)
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                Spacer()

                Button {
                    onAddStepInPhase(phase.id)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.primary)
                }
                .buttonStyle(.plain)
            }

            // Phase Progress Pill
            HStack {
                Text(phase.timeRange)
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()

                if totalCount > 0 {
                    Text("\(completedCount)/\(totalCount) completed")
                        .font(AppTypography.captionSmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color(hex: "F3EFFF")))

            // Nodes inside this Phase
            VStack(spacing: 8) {
                ForEach(phaseNodes) { node in
                    renderNode(node: node)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .stroke(AppColors.surfaceBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
        )
    }

    private func serpentinePhaseConnector(isReversed: Bool) -> some View {
        HStack {
            if isReversed {
                Spacer()
            }

            VStack(spacing: 2) {
                Circle()
                    .fill(AppColors.primary.opacity(0.6))
                    .frame(width: 6, height: 6)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, Color(hex: "C4B5FD")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: 28)

                Circle()
                    .fill(Color(hex: "C4B5FD"))
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 36)

            if !isReversed {
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func renderNode(node: ScheduleNode) -> some View {
        switch node.type {
        case .anchor:
            ScheduleAnchorNodeView(
                node: node,
                isOverflowing: viewModel.isOverflowing,
                onTap: { onSelectNode(node) }
            )
        case .habit:
            ScheduleHabitNodeView(
                node: node,
                onToggleCompletion: { viewModel.toggleHabit(node.id) },
                onTap: { onSelectNode(node) }
            )
        case .task:
            ScheduleActivityNodeView(
                node: node,
                onToggleFocus: {
                    if node.inFocus ?? false {
                        viewModel.stopFocus()
                    } else {
                        viewModel.startFocus(node.id)
                    }
                },
                onTap: { onSelectNode(node) }
            )
        case .recharge:
            ScheduleRechargeNodeView(
                node: node,
                onTap: { onSelectNode(node) }
            )
        }
    }
}
