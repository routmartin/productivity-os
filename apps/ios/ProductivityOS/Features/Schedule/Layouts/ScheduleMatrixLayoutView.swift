import SwiftUI

/// Swimlane Matrix layout: 4-phase column canvas with 3 horizontal swimlanes (Spec AC-001).
public struct ScheduleMatrixLayoutView: View {
    @Bindable public var viewModel: ScheduleViewModel
    public var onSelectNode: (ScheduleNode) -> Void
    public var onAddStepInPhase: (SchedulePhaseId) -> Void

    @State private var activePhaseIndex: Int = 0

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
        VStack(spacing: AppSpacing.md) {
            // Horizontal Phase Picker Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.phases.enumerated()), id: \.element.id) { index, phase in
                        let isSelected = activePhaseIndex == index

                        Button {
                            withAnimation(AppMotion.standard) {
                                activePhaseIndex = index
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(phase.title)
                                    .font(AppTypography.caption)
                                    .fontWeight(isSelected ? .bold : .medium)

                                Text(phase.timeRange)
                                    .font(AppTypography.captionSmall)
                                    .opacity(isSelected ? 0.9 : 0.6)
                            }
                            .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(isSelected ? AppColors.primary : AppColors.surface)
                                    .overlay(
                                        Capsule().stroke(isSelected ? AppColors.primary : AppColors.surfaceBorder, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Active Phase Swimlane Container
            if viewModel.phases.indices.contains(activePhaseIndex) {
                let currentPhase = viewModel.phases[activePhaseIndex]
                phaseSwimlanes(phase: currentPhase)
            }
        }
    }

    private func phaseSwimlanes(phase: SchedulePhase) -> some View {
        let phaseNodes = viewModel.nodes.filter { $0.phase == phase.id }
        let habitNodes = phaseNodes.filter { $0.type == .habit }
        let taskNodes = phaseNodes.filter { $0.type == .task }
        let anchorRecoveryNodes = phaseNodes.filter { $0.type == .anchor || $0.type == .recharge }

        return VStack(alignment: .leading, spacing: 14) {
            // Phase Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(phase.title)
                        .font(AppTypography.title)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(phase.subtitle)
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Button {
                    onAddStepInPhase(phase.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Step")
                    }
                    .font(AppTypography.captionSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(AppColors.primaryTint))
                }
                .buttonStyle(.plain)
            }

            // Swimlane 1: Habits & Rituals
            swimlaneSection(
                title: "HABITS & RITUALS",
                icon: "sparkles",
                color: AppColors.primary,
                nodes: habitNodes
            )

            // Swimlane 2: Focus Activities
            swimlaneSection(
                title: "FOCUS ACTIVITIES",
                icon: "target",
                color: Color(hex: "F59E0B"),
                nodes: taskNodes
            )

            // Swimlane 3: Anchors & Recovery
            swimlaneSection(
                title: "ANCHORS & RECOVERY",
                icon: "leaf.fill",
                color: Color(hex: "10B981"),
                nodes: anchorRecoveryNodes
            )
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .stroke(AppColors.surfaceBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    private func swimlaneSection(
        title: String,
        icon: String,
        color: Color,
        nodes: [ScheduleNode]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)

                Text(title)
                    .font(AppTypography.sectionHeader)
                    .foregroundStyle(color)

                Spacer()

                Text("\(nodes.count)")
                    .font(AppTypography.captionSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(hex: "F1F5F9")))
            }

            if nodes.isEmpty {
                Text("No items in this swimlane")
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(Color(hex: "F8F9FA"))
                    )
            } else {
                VStack(spacing: 6) {
                    ForEach(nodes) { node in
                        renderNode(node: node)
                    }
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color(hex: "FBFBFE"))
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
