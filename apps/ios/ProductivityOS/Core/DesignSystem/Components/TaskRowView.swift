import SwiftUI

/// Task row component matching the approved visual design in `today.png`
public struct TaskRowView: View {
    private let position: Int?
    private let title: String
    private let projectName: String?
    private let priority: TaskPriority
    private let iconName: String
    private let action: () -> Void
    
    public init(
        position: Int? = nil,
        title: String,
        projectName: String? = "Productivity OS",
        priority: TaskPriority = .medium,
        iconName: String = "flag.fill",
        action: @escaping () -> Void = {}
    ) {
        self.position = position
        self.title = title
        self.projectName = projectName
        self.priority = priority
        self.iconName = iconName
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                // Position number (e.g. "01")
                if let position {
                    Text(String(format: "%02d", position))
                        .font(AppTypography.numberBadge)
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 26, alignment: .leading)
                }
                
                // Icon square
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(AppColors.primaryTint)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
                
                // Title and project
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.numberBadge)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let projectName {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 6, height: 6)
                            Text(projectName)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                Spacer(minLength: AppSpacing.xs)

                // Priority pill
                PriorityBadge(priority: priority)
                    .layoutPriority(0)
                    .fixedSize()

                // Trailing chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
                    .fixedSize()
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm + 2)
            .appCardStyle(cornerRadius: AppRadius.lg)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Priority badge pill component
public struct PriorityBadge: View {
    public let priority: TaskPriority
    
    public init(priority: TaskPriority) {
        self.priority = priority
    }
    
    public var body: some View {
        Text(priority.title)
            .font(AppTypography.captionSmall)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(priority.backgroundColor)
            .foregroundStyle(priority.foregroundColor)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        TaskRowView(position: 1, title: "Finish authentication", priority: .high, iconName: "flag.fill")
        TaskRowView(position: 2, title: "Review API implementation", priority: .medium, iconName: "curlybraces")
        TaskRowView(position: 3, title: "Build task dashboard", priority: .low, iconName: "square.grid.2x2.fill")
    }
    .padding()
    .background(AppColors.canvas)
}
