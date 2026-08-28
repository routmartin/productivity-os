import SwiftUI

/// Main coordinator view with iOS 26 Liquid Glass tab bar.
public struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .today
    @State private var focusViewModel = FocusSessionViewModel()
    @State private var projectsViewModel = ProjectsViewModel()
    @State private var isShowingFocusSheet = false

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.today.rawValue, systemImage: AppTab.today.iconName, value: AppTab.today) {
                TodayView(
                    projectsViewModel: projectsViewModel,
                    onStartFocus: { task in
                        focusViewModel.selectedTask = task
                        isShowingFocusSheet = true
                    },
                    onSelectTask: { task in
                        focusViewModel.selectedTask = task
                        isShowingFocusSheet = true
                    }
                )
            }

            Tab(AppTab.focus.rawValue, systemImage: AppTab.focus.iconName, value: AppTab.focus, role: .search) {
                FocusPreparationView(
                    viewModel: focusViewModel,
                    onDismiss: {
                        selectedTab = .today
                    }
                )
            }

            Tab(AppTab.tasks.rawValue, systemImage: AppTab.tasks.iconName, value: AppTab.tasks) {
                TasksView(
                    projectsViewModel: projectsViewModel,
                    onSelectTask: { task in
                        focusViewModel.selectedTask = task
                        isShowingFocusSheet = true
                    }
                )
            }

            Tab(AppTab.me.rawValue, systemImage: AppTab.me.iconName, value: AppTab.me) {
                ProfileView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        #if os(iOS)
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
                onMinimize: {}
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
        .sheet(isPresented: $isShowingFocusSheet) {
            FocusPreparationView(
                viewModel: focusViewModel,
                onDismiss: {
                    isShowingFocusSheet = false
                }
            )
        }
        .sheet(
            isPresented: Binding(
                get: { focusViewModel.sessionState.state == .completed },
                set: { if !$0 { focusViewModel.resetToPreparing() } }
            )
        ) {
            FocusCompletionView(
                focusedDurationSeconds: focusViewModel.sessionState.elapsedSeconds(),
                taskTitle: focusViewModel.selectedTask?.title,
                projectName: focusViewModel.selectedTask?.projectName ?? "Productivity OS"
            ) {
                focusViewModel.resetToPreparing()
                isShowingFocusSheet = false
            }
        }
        .task {
            await focusViewModel.restoreActiveSession()
        }
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
