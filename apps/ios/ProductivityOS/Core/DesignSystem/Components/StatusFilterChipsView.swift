import SwiftUI

/// Horizontal scrollable container displaying lifecycle status filter chips with reactive counts.
/// Mirrors the web filter chips behavior (`FilterChips.vue`).
public struct StatusFilterChipsView: View {
    @Binding public var selectedFilter: TasksViewModel.TaskStatusFilter
    public let counts: [TasksViewModel.TaskStatusFilter: Int]

    public init(
        selectedFilter: Binding<TasksViewModel.TaskStatusFilter>,
        counts: [TasksViewModel.TaskStatusFilter: Int]
    ) {
        self._selectedFilter = selectedFilter
        self.counts = counts
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(TasksViewModel.TaskStatusFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    let count = counts[filter] ?? 0

                    Button {
                        withAnimation(AppMotion.micro) {
                            selectedFilter = filter
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(filter.title)
                                .font(AppTypography.captionSmall)
                                .fontWeight(.semibold)

                            Text("(\(count))")
                                .font(AppTypography.captionSmall)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, AppSpacing.sm)
                        .frame(height: 32)
                        .background(isSelected ? AppColors.primaryTint : AppColors.surface)
                        .foregroundStyle(isSelected ? AppColors.primary : AppColors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                .stroke(isSelected ? AppColors.primary : AppColors.surfaceBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(filter.title), \(count) tasks")
                    .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
                }
            }
        }
    }
}

#Preview {
    StatusFilterChipsView(
        selectedFilter: .constant(.active),
        counts: [.all: 8, .active: 5, .completed: 2, .cancelled: 1]
    )
    .padding()
    .background(AppColors.canvas)
}
