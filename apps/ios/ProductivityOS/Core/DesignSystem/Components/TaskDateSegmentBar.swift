import SwiftUI

/// Fluid pill segmented control for task temporal segments.
/// Solves native `UISegmentedControl` truncation bugs by using content-adaptive
/// intrinsic sizing and smooth spring animations.
public struct TaskDateSegmentBar: View {
    @Binding public var selectedSegment: TasksViewModel.DateSegmentFilter
    public let counts: [TasksViewModel.DateSegmentFilter: Int]
    @Namespace private var animation

    public init(
        selectedSegment: Binding<TasksViewModel.DateSegmentFilter>,
        counts: [TasksViewModel.DateSegmentFilter: Int]
    ) {
        self._selectedSegment = selectedSegment
        self.counts = counts
    }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(TasksViewModel.DateSegmentFilter.allCases) { segment in
                let isSelected = selectedSegment == segment
                let count = counts[segment] ?? 0

                Button {
                    withAnimation(AppMotion.spring) {
                        selectedSegment = segment
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(segment.title)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text("\(count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                isSelected
                                    ? AppColors.primary.opacity(0.12)
                                    : AppColors.canvasSecondary
                            )
                            .foregroundStyle(isSelected ? AppColors.primary : AppColors.textTertiary)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                .fill(AppColors.surface)
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                .matchedGeometryEffect(id: "active_segment_pill", in: animation)
                        }
                    }
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(segment.title), \(count) tasks")
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(3)
        .background(AppColors.canvasSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }
}

#Preview {
    VStack(spacing: 16) {
        TaskDateSegmentBar(
            selectedSegment: .constant(.today),
            counts: [.today: 2, .upcoming: 0, .backlog: 1, .all: 3]
        )
        TaskDateSegmentBar(
            selectedSegment: .constant(.upcoming),
            counts: [.today: 2, .upcoming: 12, .backlog: 5, .all: 19]
        )
    }
    .padding()
    .background(AppColors.canvas)
}
