import SwiftUI

/// Main coordinator view with custom bottom bar and Focus mode presentation
public struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .today
    @State private var focusViewModel = FocusSessionViewModel()
    @State private var isShowingFocusSheet = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main tab switch
            Group {
                switch selectedTab {
                case .today:
                    TodayView(
                        onStartFocus: { task in
                            focusViewModel.selectedTask = task
                            isShowingFocusSheet = true
                        },
                        onSelectTask: { task in
                            focusViewModel.selectedTask = task
                            isShowingFocusSheet = true
                        }
                    )
                case .focus:
                    FocusPreparationView(
                        viewModel: focusViewModel,
                        onDismiss: {
                            selectedTab = .today
                        }
                    )
                case .tasks:
                    TasksView(
                        onSelectTask: { task in
                            focusViewModel.selectedTask = task
                            isShowingFocusSheet = true
                        }
                    )
                case .me:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom bottom tab navigation (hidden during active focus session)
            if focusViewModel.sessionState.state != .running && focusViewModel.sessionState.state != .paused {
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        #if os(iOS)
        // Active / Paused full-screen Focus Environment
        .fullScreenCover(
            isPresented: Binding(
                get: {
                    focusViewModel.sessionState.state == .running || focusViewModel.sessionState.state == .paused
                },
                set: { isPresenting in
                    if !isPresenting && focusViewModel.sessionState.state != .completed {
                        focusViewModel.pauseFocus()
                    }
                }
            )
        ) {
            ActiveFocusView(
                viewModel: focusViewModel,
                onMinimize: {
                    // Minimize sheet while keeping timer running
                }
            )
        }
        #else
        .sheet(
            isPresented: Binding(
                get: {
                    focusViewModel.sessionState.state == .running || focusViewModel.sessionState.state == .paused
                },
                set: { isPresenting in
                    if !isPresenting && focusViewModel.sessionState.state != .completed {
                        focusViewModel.pauseFocus()
                    }
                }
            )
        ) {
            ActiveFocusView(
                viewModel: focusViewModel,
                onMinimize: {}
            )
        }
        #endif
        // Focus Preparation sheet
        .sheet(isPresented: $isShowingFocusSheet) {
            FocusPreparationView(
                viewModel: focusViewModel,
                onDismiss: {
                    isShowingFocusSheet = false
                }
            )
        }
        // Focus Completed calm screen
        .sheet(
            isPresented: Binding(
                get: { focusViewModel.sessionState.state == .completed },
                set: { if !$0 { focusViewModel.resetToPreparing() } }
            )
        ) {
            FocusCompletionView(
                focusedDurationSeconds: focusViewModel.sessionState.elapsedSeconds()
            ) {
                focusViewModel.resetToPreparing()
                isShowingFocusSheet = false
            }
        }
        // Restore an in-progress server session on launch.
        .task {
            await focusViewModel.restoreActiveSession()
        }
        // Timer accuracy across background/foreground comes from wall-clock
        // timestamps; foregrounding just re-renders with the current time.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                focusViewModel.refreshClock()
            }
        }
    }
}

#Preview {
    MainTabView()
}
