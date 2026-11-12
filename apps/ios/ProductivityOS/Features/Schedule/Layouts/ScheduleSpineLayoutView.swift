import SwiftUI

/// Central Spine layout: vertical chronological axis with bilateral node distribution (Spec AC-001).
public struct ScheduleSpineLayoutView: View {
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
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ForEach(viewModel.phases) { phase in
                phaseSection(phase: phase)
            }
        }
    }

    private func phaseSection(phase: SchedulePhase) -> some View {
        let phaseNodes = viewModel.nodes.filter { $0.phase == phase.id }

        return VStack(alignment: .leading, spacing: 10) {
            // Phase Header with + Add Action
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(phase.title)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textPrimary)

                        Text(phase.timeRange)
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Text(phase.subtitle)
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Button {
                    onAddStepInPhase(phase.id)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add")
                            .font(AppTypography.captionSmall)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppColors.primaryTint))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, AppSpacing.sm)

            // Timeline Nodes in this Phase
            VStack(spacing: 0) {
                ForEach(Array(phaseNodes.enumerated()), id: \.element.id) { index, node in
                    VStack(spacing: 0) {
                        renderNode(node: node)

                        // Outgoing edge to next node
                        if index < phaseNodes.count - 1 {
                            let nextNode = phaseNodes[index + 1]
                            let edge = viewModel.edges.first { $0.fromNodeId == node.id && $0.toNodeId == nextNode.id }
                            let isActive = edge?.active ?? (node.completed ?? false)
                            ScheduleEdgeView(active: isActive, height: 18)
                        }
                    }
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
        )
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
