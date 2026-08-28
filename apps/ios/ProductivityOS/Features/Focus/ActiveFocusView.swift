import SwiftUI

/// Active Focus Hero View matching `focsu-flow.png` (Running & Paused states)
public struct ActiveFocusView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false
    @Bindable var viewModel: FocusSessionViewModel
    private let projectsViewModel: ProjectsViewModel
    private let onMinimize: () -> Void
    private let onDismiss: () -> Void

    public init(
        viewModel: FocusSessionViewModel,
        projectsViewModel: ProjectsViewModel = ProjectsViewModel(),
        onMinimize: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.projectsViewModel = projectsViewModel
        self.onMinimize = onMinimize
        self.onDismiss = onDismiss
    }

    private var isPaused: Bool {
        viewModel.sessionState.state == .paused
    }

    public var body: some View {
        ZStack {
            // Deep navy focus canvas
            AppColors.focusCanvas
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                // MARK: - Top Navigation Bar
                topBar

                // Mode Badge Pill
                modeBadgePill

                // Server sync feedback (never blocks the local timer)
                if let syncError = viewModel.syncErrorMessage {
                    syncBanner(message: syncError)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                Spacer()

                // MARK: - Focus Title (above timer)
                VStack(spacing: 4) {
                    Text(viewModel.selectedTask?.title ?? "Finish authentication")
                        .font(AppTypography.title)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.horizontal, AppSpacing.lg)
    
                Spacer(minLength: 8)
                
                // MARK: - Hero Focus Clock
                FocusClockView(
                    progress: viewModel.timerProgress,
                    timerText: viewModel.timerDisplayText,
                    taskTitle: viewModel.selectedTask?.title ?? "Finish authentication",
                    projectName: viewModel.selectedTask.map { projectsViewModel.projectName(for: $0) } ?? nil,
                    durationLabel: viewModel.selectedDuration.subtitle,
                    isPaused: isPaused,
                    variant: .hero
                )
                
                // Philosophy Subtitle
                HStack(spacing: 6) {
                    Image(systemName: "leaf")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.primary)
                    Text("Protect your focus. Build the future.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.top, 4)
                
                Spacer(minLength: 8)
                
                // MARK: - Control Buttons (Pause/Resume, Stop, Complete)
                if viewModel.isCompleting {
                    // Completion is being confirmed with the backend.
                    ProgressView()
                        .tint(.white.opacity(0.8))
                        .frame(height: 90)
                        .accessibilityLabel("Saving your session")
                } else {
                    controlButtonsRow
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.xs)
            // Connected Preparation -> Active entrance (spec §9, 300-500ms).
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.96)
            .animation(reduceMotion ? nil : AppMotion.large, value: hasAppeared)
            .onAppear {
                hasAppeared = true
            }
            .animation(reduceMotion ? nil : AppMotion.standard, value: viewModel.syncErrorMessage != nil)
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            
            Spacer()
            
            Text("FOCUS")
                .font(AppTypography.sectionHeader)
                .foregroundStyle(.white)
                .tracking(1.5)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(AppColors.focusControlBackground)
                    .clipShape(Circle())
            }
        }
    }
    
    private func syncBanner(message: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 12, weight: .semibold))
            Text(message)
                .font(AppTypography.captionSmall)
                .multilineTextAlignment(.leading)
            Spacer()
            Button("Retry") {
                viewModel.retrySync()
            }
            .font(AppTypography.captionSmall)
            .fontWeight(.bold)
            .accessibilityLabel("Retry saving session")
        }
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    private var modeBadgePill: some View {
        HStack(spacing: 6) {
            if isPaused {
                Image(systemName: "pause.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("Paused")
                    .font(AppTypography.captionSmall)
                    .fontWeight(.bold)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                Text("Deep work mode")
                    .font(AppTypography.captionSmall)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .foregroundStyle(.white)
        .clipShape(Capsule())
        .accessibilityLabel(isPaused ? "Session paused" : "Focus session running")
    }
    
    private var controlButtonsRow: some View {
        HStack(spacing: AppSpacing.xl) {
            // 1. Pause / Resume Button
            if isPaused {
                controlAction(
                    icon: "play.fill",
                    label: "Resume",
                    isPrimary: true
                ) {
                    Haptics.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.resumeFocus()
                    }
                }
            } else {
                controlAction(
                    icon: "pause.fill",
                    label: "Pause",
                    isPrimary: false
                ) {
                    Haptics.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.pauseFocus()
                    }
                }
            }

            // 2. Stop Button
            controlAction(
                icon: "square.fill",
                label: "Stop",
                isPrimary: false
            ) {
                viewModel.cancelFocus()
            }

            // 3. Complete Button
            controlAction(
                icon: "flag.fill",
                label: "Complete",
                isPrimary: false
            ) {
                viewModel.completeFocus()
            }
        }
    }
    
    private func controlAction(
        icon: String,
        label: String,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isPrimary ? AnyShapeStyle(AppColors.primaryGradient) : AnyShapeStyle(AppColors.focusControlBackground))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(isPrimary ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: isPrimary ? AppColors.primary.opacity(0.5) : .clear, radius: 12, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    

}

#Preview("Running Focus") {
    ActiveFocusView(
        viewModel: FocusSessionViewModel(
            state: SampleData.makeRunningFocusState()
        )
    )
}

#Preview("Paused Focus") {
    ActiveFocusView(
        viewModel: FocusSessionViewModel(
            state: SampleData.makePausedFocusState()
        )
    )
}

