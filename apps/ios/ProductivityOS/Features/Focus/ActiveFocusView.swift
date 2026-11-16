import SwiftUI

/// Active Focus Hero View redesigned as an authentic, battery-efficient,
/// cozy Mooas Automatic Mini Flip Clock desk timer instrument.
public struct ActiveFocusView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var hasAppeared = false
    @State private var isAmbientDimmed = false
    @State private var inactivityTask: Task<Void, Never>?

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

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var currentTaskTitle: String {
        viewModel.selectedTask?.title ?? "Deep Focus Session"
    }

    private var currentProjectName: String? {
        guard let task = viewModel.selectedTask else { return nil }
        return projectsViewModel.projectName(for: task)
    }

    public var body: some View {
        ZStack {
            // Cozy dark espresso/charcoal desk canvas
            AppColors.cozyCanvasDark
                .ignoresSafeArea()

            // Main adaptive container
            Group {
                if isLandscape {
                    landscapeDeskLayout
                } else {
                    portraitDeskLayout
                }
            }
            .padding(.horizontal, isLandscape ? AppSpacing.md : AppSpacing.lg)
            .padding(.vertical, AppSpacing.xs)

            // Ambient Low-Power Dimming Overlay (OLED Battery Saver)
            if isAmbientDimmed {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        // Direct background tap wakes up from ambient dimmed mode
        .simultaneousGesture(
            TapGesture().onEnded {
                wakeUpAndResetTimer()
            }
        )
        // Connected Preparation -> Active entrance
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.97)
        .animation(reduceMotion ? nil : AppMotion.large, value: hasAppeared)
        .animation(.easeInOut(duration: 0.8), value: isAmbientDimmed)
        .onAppear {
            hasAppeared = true
            resetInactivityTimer()
        }
        .onDisappear {
            inactivityTask?.cancel()
        }
        .onChange(of: viewModel.sessionState.state) { _, newState in
            if newState == .running {
                resetInactivityTimer()
            } else {
                wakeUpAndResetTimer()
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitDeskLayout: some View {
        VStack(spacing: AppSpacing.sm) {
            // Top Navigation Bar
            topBar
                .opacity(isAmbientDimmed ? 0.2 : 1.0)

            // Mode Badge Pill & Sync Feedback
            VStack(spacing: 6) {
                modeBadgePill

                if let syncError = viewModel.syncErrorMessage {
                    syncBanner(message: syncError)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .opacity(isAmbientDimmed ? 0.25 : 1.0)

            Spacer(minLength: 8)

            // Clean Header: Task Title & Project
            taskHeaderView
                .opacity(isAmbientDimmed ? 0.45 : 1.0)

            Spacer(minLength: 12)

            // Hero Mooas Flip Clock Instrument
            FocusClockView(
                progress: viewModel.timerProgress,
                timerText: viewModel.timerDisplayText,
                taskTitle: currentTaskTitle,
                projectName: currentProjectName,
                durationLabel: viewModel.selectedDuration.subtitle,
                isPaused: isPaused,
                variant: .hero,
                onTap: {
                    togglePause()
                }
            )

            // Warm Philosophy Subtitle
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.cozyAccent)
                Text(isPaused ? "Paused — tap clock to resume" : "Protect your focus. Build the future.")
                    .font(AppTypography.caption)
                    .foregroundStyle(isPaused ? AppColors.cozyAccent : Color.white.opacity(0.65))
            }
            .padding(.top, 4)
            .opacity(isAmbientDimmed ? 0.3 : 1.0)

            Spacer(minLength: 16)

            // Control Buttons (+5m, Pause/Resume, Complete, Stop)
            if viewModel.isCompleting {
                ProgressView()
                    .tint(AppColors.cozyAccent)
                    .frame(height: 80)
                    .accessibilityLabel("Saving your session")
            } else {
                controlButtonsRow
                    .opacity(isAmbientDimmed ? 0.25 : 1.0)
            }

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Landscape Desk Layout (Desk Stand / MagSafe StandBy)

    private var landscapeDeskLayout: some View {
        HStack(spacing: AppSpacing.xl) {
            // Left: Dedicated Mooas Desk Clock
            VStack {
                Spacer()
                FocusClockView(
                    progress: viewModel.timerProgress,
                    timerText: viewModel.timerDisplayText,
                    taskTitle: currentTaskTitle,
                    projectName: currentProjectName,
                    durationLabel: viewModel.selectedDuration.subtitle,
                    isPaused: isPaused,
                    variant: .hero,
                    onTap: {
                        togglePause()
                    }
                )
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right: Clean Info & Controls
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Top close button & mode pill
                HStack {
                    modeBadgePill
                    Spacer()
                    closeButton
                }

                if let syncError = viewModel.syncErrorMessage {
                    syncBanner(message: syncError)
                }

                Spacer()

                // Task title & project
                VStack(alignment: .leading, spacing: 4) {
                    if let project = currentProjectName {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(AppColors.cozyAccent)
                                .frame(width: 6, height: 6)
                            Text(project)
                                .font(AppTypography.caption)
                                .foregroundStyle(Color.white.opacity(0.7))
                        }
                    }

                    Text(currentTaskTitle)
                        .font(AppTypography.title)
                        .foregroundStyle(AppColors.flapTextLight)
                        .lineLimit(2)
                }

                Spacer()

                // Control buttons row
                if viewModel.isCompleting {
                    ProgressView().tint(AppColors.cozyAccent)
                } else {
                    controlButtonsRow
                }

                Spacer()
            }
            .frame(maxWidth: 320)
            .opacity(isAmbientDimmed ? 0.3 : 1.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            Spacer()

            Text("FOCUS")
                .font(AppTypography.sectionHeader)
                .foregroundStyle(Color.white.opacity(0.75))
                .tracking(2.0)

            Spacer()

            closeButton
        }
    }

    private var closeButton: some View {
        Button(action: {
            wakeUpAndResetTimer()
            onDismiss()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())
        }
        .accessibilityLabel("Dismiss focus screen")
    }

    private var taskHeaderView: some View {
        VStack(spacing: 6) {
            if let project = currentProjectName {
                HStack(spacing: 5) {
                    Circle()
                        .fill(AppColors.cozyAccent)
                        .frame(width: 6, height: 6)
                    Text(project)
                        .font(AppTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
            }

            Text(currentTaskTitle)
                .font(AppTypography.title)
                .foregroundStyle(AppColors.flapTextLight)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var modeBadgePill: some View {
        HStack(spacing: 6) {
            if isPaused {
                Image(systemName: "pause.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.cozyAccent)
                Text("Paused")
                    .font(AppTypography.captionSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.cozyAccent)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.cozyAccent)
                Text("Deep work")
                    .font(AppTypography.captionSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
        .accessibilityLabel(isPaused ? "Session paused" : "Focus session running")
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
                wakeUpAndResetTimer()
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

    // MARK: - Control Buttons Row

    private var controlButtonsRow: some View {
        HStack(spacing: AppSpacing.lg) {
            // 1. Quick Bump (+5 min)
            controlAction(
                icon: "plus",
                label: "+5m",
                isPrimary: false,
                accentColor: AppColors.cozyAccent
            ) {
                wakeUpAndResetTimer()
                viewModel.addMinutes(5)
            }
            .accessibilityLabel("Add 5 minutes to timer")

            // 2. Pause / Resume Button
            if isPaused {
                controlAction(
                    icon: "play.fill",
                    label: "Resume",
                    isPrimary: true,
                    accentColor: AppColors.cozyAccent
                ) {
                    togglePause()
                }
            } else {
                controlAction(
                    icon: "pause.fill",
                    label: "Pause",
                    isPrimary: false,
                    accentColor: .white
                ) {
                    togglePause()
                }
            }

            // 3. Complete Button
            controlAction(
                icon: "flag.fill",
                label: "Complete",
                isPrimary: false,
                accentColor: AppColors.success
            ) {
                wakeUpAndResetTimer()
                viewModel.completeFocus()
            }

            // 4. Cancel / Stop Button
            controlAction(
                icon: "square.fill",
                label: "Stop",
                isPrimary: false,
                accentColor: Color.white.opacity(0.6)
            ) {
                wakeUpAndResetTimer()
                viewModel.cancelFocus()
            }
        }
    }

    private func controlAction(
        icon: String,
        label: String,
        isPrimary: Bool,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            isPrimary
                                ? AnyShapeStyle(AppColors.cozyAccent)
                                : AnyShapeStyle(Color.white.opacity(0.12))
                        )
                        .frame(width: 54, height: 54)
                        .overlay(
                            Circle()
                                .stroke(isPrimary ? Color.clear : Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(
                            color: isPrimary ? AppColors.cozyAccent.opacity(0.4) : .clear,
                            radius: 8,
                            x: 0,
                            y: 3
                        )

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isPrimary ? .white : accentColor)
                }

                Text(label)
                    .font(AppTypography.captionSmall)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white.opacity(0.85))
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Interaction & Ambient Helpers

    private func togglePause() {
        wakeUpAndResetTimer()
        Haptics.light()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if isPaused {
                viewModel.resumeFocus()
            } else {
                viewModel.pauseFocus()
            }
        }
    }

    private func wakeUpAndResetTimer() {
        if isAmbientDimmed {
            withAnimation(.easeInOut(duration: 0.4)) {
                isAmbientDimmed = false
            }
        }
        resetInactivityTimer()
    }

    private func resetInactivityTimer() {
        inactivityTask?.cancel()
        // Only auto-dim during active running focus
        guard viewModel.sessionState.state == .running else { return }
        inactivityTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 25_000_000_000) // 25s inactivity
            guard !Task.isCancelled else { return }
            guard viewModel.sessionState.state == .running else { return }
            withAnimation(.easeInOut(duration: 1.0)) {
                isAmbientDimmed = true
            }
        }
    }
}

#Preview("Running Focus - Portrait") {
    ActiveFocusView(
        viewModel: FocusSessionViewModel(
            state: SampleData.makeRunningFocusState()
        )
    )
}

#Preview("Paused Focus - Portrait") {
    ActiveFocusView(
        viewModel: FocusSessionViewModel(
            state: SampleData.makePausedFocusState()
        )
    )
}
