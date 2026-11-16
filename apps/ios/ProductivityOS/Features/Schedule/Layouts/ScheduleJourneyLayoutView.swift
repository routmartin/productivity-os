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

    private var displayedPhases: [SchedulePhase] {
        viewModel.phases.filter { $0.id != .deepFocus }
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(displayedPhases.enumerated()), id: \.element.id) { phaseIndex, phase in
                journeyPhaseCard(phase: phase, phaseNumber: phaseIndex + 1)

                if phaseIndex < displayedPhases.count - 1 {
                    serpentinePhaseConnector(isReversed: phaseIndex % 2 == 1)
                        .padding(.vertical, 6)
                }
            }
        }
    }

    private func journeyPhaseCard(phase: SchedulePhase, phaseNumber: Int) -> some View {
        let phaseNodes = viewModel.nodes.filter { $0.phase == phase.id }
        let completedCount = phaseNodes.filter { $0.completed ?? false }.count
        let totalCount = phaseNodes.count

        return VStack(alignment: .leading, spacing: 12) {
            ScheduleShiftHeaderView(
                phase: phase,
                shiftNumber: phaseNumber,
                completedCount: completedCount,
                totalCount: totalCount,
                onAddStep: { onAddStepInPhase(phase.id) }
            )

            // Nodes inside this Phase
            if !phaseNodes.isEmpty {
                VStack(spacing: 8) {
                    ForEach(phaseNodes) { node in
                        renderNode(node: node)
                    }
                }
            } else {
                Button {
                    onAddStepInPhase(phase.id)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(phase.id.shiftTheme.accent)

                        Text("No steps scheduled · Tap to add your first step")
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textSecondary)

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .fill(AppColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    .foregroundStyle(phase.id.shiftTheme.border.opacity(0.8))
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func serpentinePhaseConnector(isReversed: Bool) -> some View {
        HStack {
            if isReversed {
                Spacer()
            }

            VStack(spacing: 2) {
                Circle()
                    .fill(AppColors.primary.opacity(0.6))
                    .frame(width: 4, height: 4)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, Color(hex: "C4B5FD")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: 16)

                Circle()
                    .fill(Color(hex: "C4B5FD"))
                    .frame(width: 4, height: 4)
            }
            .padding(.horizontal, 36)

            if !isReversed {
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func renderNode(node: ScheduleNode) -> some View {
        Group {
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
        .contextMenu {
            if node.type != .anchor {
                Button {
                    onSelectNode(node)
                } label: {
                    Label("Inspect & Edit Step", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    viewModel.deleteNode(node.id)
                } label: {
                    Label("Delete from Today", systemImage: "trash")
                }
            }
        }
    }
}
