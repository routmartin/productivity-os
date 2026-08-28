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
                    projectsViewModel: projectsViewModel,
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
        .tabBarMinimizeIfSupported()
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
                projectsViewModel: projectsViewModel,
                onMinimize: {},
                onDismiss: {
                    focusViewModel.cancelFocus()
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
                projectsViewModel: projectsViewModel,
                onMinimize: {},
                onDismiss: {
                    focusViewModel.cancelFocus()
                }
            )
        }
        #endif
        .sheet(isPresented: $isShowingFocusSheet) {
            FocusPreparationView(
                viewModel: focusViewModel,
                projectsViewModel: projectsViewModel,
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
                projectName: focusViewModel.selectedTask.map { projectsViewModel.projectName(for: $0) } ?? nil
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

/// Availability-safe wrapper for `tabBarMinimizeBehavior`, which is only
/// declared on macOS 26+. Keeps the iOS behavior identical.
private extension View {
    @ViewBuilder
    func tabBarMinimizeIfSupported() -> some View {
        if #available(macOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}
