import SwiftUI

/// Root Daily Schedule Link-Map view (Spec AC-001 through AC-009).
public struct ScheduleView: View {
    @State private var viewModel = ScheduleViewModel()
    @State private var selectedNodeForDetail: ScheduleNode?
    @State private var isShowingAddStepSheet = false
    @State private var addStepTargetPhase: SchedulePhaseId = .morning

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    // Screen Header
                    headerSection

                    // Bedtime Warning Banner
                    ScheduleBedtimeBanner(
                        isOverflowing: viewModel.isOverflowing,
                        overflowMinutes: viewModel.overflowMinutes,
                        targetBedtime: viewModel.targetBedtime,
                        projectedBedtime: viewModel.projectedBedtime,
                        habitProgressPercent: viewModel.habitProgressPercent,
                        completedHabits: viewModel.completedHabitsCount,
                        totalHabits: viewModel.totalHabitsCount
                    )

                    // View Switcher (Spine | Journey | Matrix)
                    ScheduleViewSwitcher(
                        activeLayout: Binding(
                            get: { viewModel.activeLayout },
                            set: { viewModel.setLayout($0) }
                        )
                    )
                    .padding(.vertical, 2)

                    // Active Projection Layout
                    switch viewModel.activeLayout {
                    case .spine:
                        ScheduleSpineLayoutView(
                            viewModel: viewModel,
                            onSelectNode: { node in
                                selectedNodeForDetail = node
                            },
                            onAddStepInPhase: { phase in
                                addStepTargetPhase = phase
                                isShowingAddStepSheet = true
                            }
                        )
                    case .journey:
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
                    case .matrix:
                        ScheduleMatrixLayoutView(
                            viewModel: viewModel,
                            onSelectNode: { node in
                                selectedNodeForDetail = node
                            },
                            onAddStepInPhase: { phase in
                                addStepTargetPhase = phase
                                isShowingAddStepSheet = true
                            }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 100) // Padding for custom bottom tab bar
            }
            .background(AppColors.canvas.ignoresSafeArea())
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

                Text("Morning-to-bedtime unified circadian trajectory")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Button {
                addStepTargetPhase = .morning
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
