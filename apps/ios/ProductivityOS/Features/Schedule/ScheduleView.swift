import SwiftUI

/// Top-level switcher within the Schedule screen between Routine and Deep Work blocks.
public enum ScheduleTab: String, CaseIterable, Identifiable, Sendable {
    case routine = "Routine"
    case deepWork = "Deep Work"
    public var id: String { rawValue }
}

/// Root Daily Schedule Link-Map view (Spec AC-001 through AC-009).
public struct ScheduleView: View {
    @State private var viewModel = ScheduleViewModel()
    @State private var selectedTab: ScheduleTab = .routine
    @State private var selectedNodeForDetail: ScheduleNode?
    @State private var isShowingAddStepSheet = false
    @State private var addStepTargetPhase: SchedulePhaseId = .morning
    @Namespace private var tabAnimation

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    // Screen Header
                    headerSection

                    // Top Tab Switcher: Routine vs Deep Work
                    scheduleTabBar

                    if selectedTab == .routine {
                        // Dedicated Journey Projection Layout (Morning, Afternoon, Bedtime)
                        ScheduleJourneyLayoutView(
                            viewModel: viewModel,
                            onSelectNode: { node in
                                selectedNodeForDetail = node
                            },
                            onAddStepInPhase: { phase in
                                addStepTargetPhase = phase
                                isShowingAddStepSheet = true
                            }
                        )
                    } else {
                        // Dedicated Deep Work Section (.deepFocus phase nodes)
                        deepWorkSection
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 100) // Clearance for floating bottom tab bar
            }
            .background(AppColors.canvas.ignoresSafeArea())
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .task {
                if case .idle = viewModel.loadState {
                    await viewModel.loadData()
                }
            }
            .sheet(item: $selectedNodeForDetail) { node in
                ScheduleNodeDetailSheet(
                    node: node,
                    onToggleHabit: {
                        viewModel.toggleHabit(node.id)
                        // Refresh inspection state
                        if let updated = viewModel.nodes.first(where: { $0.id == node.id }) {
                            selectedNodeForDetail = updated
                        }
                    },
                    onToggleFocus: {
                        if node.inFocus ?? false {
                            viewModel.stopFocus()
                        } else {
                            viewModel.startFocus(node.id)
                        }
                        if let updated = viewModel.nodes.first(where: { $0.id == node.id }) {
                            selectedNodeForDetail = updated
                        }
                    },
                    onDelete: {
                        viewModel.deleteNode(node.id)
                    },
                    onUpdate: { payload in
                        Task {
                            _ = try? await viewModel.updateStep(id: node.id, payload: payload)
                            if let updated = viewModel.nodes.first(where: { $0.id == node.id }) {
                                selectedNodeForDetail = updated
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $isShowingAddStepSheet) {
                ScheduleAddStepSheet(initialPhase: addStepTargetPhase) { payload in
                    Task {
                        await viewModel.addStep(payload)
                    }
                }
            }
        }
    }

    private var scheduleTabBar: some View {
        HStack(spacing: 2) {
            ForEach(ScheduleTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(AppMotion.spring) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab == .routine ? "sun.max.fill" : "brain.head.profile")
                            .font(.system(size: 13, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                .fill(AppColors.surface)
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                .matchedGeometryEffect(id: "active_schedule_tab", in: tabAnimation)
                        }
                    }
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(3)
        .background(AppColors.canvasSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    private var deepWorkSection: some View {
        let deepFocusNodes = viewModel.nodes.filter { $0.phase == .deepFocus }
        let phase = viewModel.phases.first(where: { $0.id == .deepFocus })
        let title = phase?.title ?? SchedulePhaseId.deepFocus.defaultTitle
        let subtitle = phase?.subtitle ?? SchedulePhaseId.deepFocus.defaultSubtitle
        let timeRange = phase?.timeRange ?? SchedulePhaseId.deepFocus.defaultTimeRange
        let completedCount = deepFocusNodes.filter { $0.completed ?? false }.count
        let totalCount = deepFocusNodes.count

        return VStack(alignment: .leading, spacing: 12) {
            ScheduleShiftHeaderView(
                phaseId: .deepFocus,
                title: title,
                subtitle: subtitle,
                timeRange: timeRange,
                shiftNumber: nil,
                completedCount: completedCount,
                totalCount: totalCount,
                onAddStep: {
                    addStepTargetPhase = .deepFocus
                    isShowingAddStepSheet = true
                }
            )

            // Nodes inside Deep Focus Phase
            if deepFocusNodes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundStyle(AppColors.primary.opacity(0.6))
                        .padding(.top, 8)

                    Text("No Deep Work Steps Scheduled")
                        .font(AppTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Add focused task blocks or recharge pauses to protect deep work.")
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        addStepTargetPhase = .deepFocus
                        isShowingAddStepSheet = true
                    } label: {
                        Text("Add Deep Work Step")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(AppColors.primary))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .stroke(AppColors.surfaceBorder, lineWidth: 1)
                        )
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(deepFocusNodes) { node in
                        renderNode(node: node)
                    }
                }
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
                    onTap: { selectedNodeForDetail = node }
                )
            case .habit:
                ScheduleHabitNodeView(
                    node: node,
                    onToggleCompletion: { viewModel.toggleHabit(node.id) },
                    onTap: { selectedNodeForDetail = node }
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
                    onTap: { selectedNodeForDetail = node }
                )
            case .recharge:
                ScheduleRechargeNodeView(
                    node: node,
                    onTap: { selectedNodeForDetail = node }
                )
            }
        }
        .contextMenu {
            if node.type != .anchor {
                Button {
                    selectedNodeForDetail = node
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

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(todayDateFormatted)
                    .font(AppTypography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primary)
                    .textCase(.uppercase)

                Text("Daily Link-Map")
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text(selectedTab == .routine ? "Morning-to-bedtime unified circadian trajectory" : "Dedicated deep focus & cognitive recovery blocks")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Button {
                addStepTargetPhase = selectedTab == .deepWork ? .deepFocus : .morning
                isShowingAddStepSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 42, height: 42)

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
    }

    private var todayDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}
