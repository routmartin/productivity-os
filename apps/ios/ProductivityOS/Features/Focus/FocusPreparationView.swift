import SwiftUI

/// Focus Preparation View matching `1. FOCUS PREPARATION` in `focsu-flow.png`
public struct FocusPreparationView: View {
    @Bindable var viewModel: FocusSessionViewModel
    private let onDismiss: () -> Void
    
    public init(
        viewModel: FocusSessionViewModel,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Top close button
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.top, AppSpacing.xs)
                
                // Hero Header with subtle illustration
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ready to focus?")
                        .font(AppTypography.largeTitle)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("You're about to protect your most valuable time.")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // MARK: - Selected Task Card & Metadata
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("SELECTED TASK")
                        .font(AppTypography.sectionHeader)
                        .foregroundStyle(AppColors.primary)
                    
                    if let task = viewModel.selectedTask {
                        TaskRowView(
                            title: task.title,
                            projectName: task.projectName ?? "Productivity OS",
                            priority: task.priority ?? .high,
                            iconName: "flag.fill"
                        )
                    }
                    
                    // Metadata Rows
                    VStack(spacing: 0) {
                        metadataRow(
                            icon: "hourglass",
                            label: "Estimated Focus Time",
                            value: viewModel.selectedTask?.formattedDuration ?? "1h 30m"
                        )
                        
                        Divider().background(AppColors.surfaceBorder)
                        
                        metadataRow(
                            icon: "folder",
                            label: "Project",
                            value: viewModel.selectedTask?.projectName ?? "Productivity OS"
                        )
                    }
                    .appCardStyle(cornerRadius: AppRadius.md)
                }
                
                // MARK: - Focus Duration Selector Chips
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("FOCUS DURATION")
                        .font(AppTypography.sectionHeader)
                        .foregroundStyle(AppColors.primary)
                    
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(FocusDuration.allCases) { duration in
                            let isSelected = viewModel.selectedDuration == duration
                            
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.selectedDuration = duration
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(duration.title)
                                        .font(AppTypography.headline)
                                        .foregroundStyle(isSelected ? AppColors.primary : AppColors.textPrimary)
                                    
                                    Text(duration.subtitle)
                                        .font(AppTypography.captionSmall)
                                        .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 72)
                                .background(isSelected ? AppColors.primaryTint : AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                        .stroke(isSelected ? AppColors.primary : AppColors.surfaceBorder, lineWidth: isSelected ? 2 : 1)
                                )
                                .overlay(alignment: .topTrailing) {
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(AppColors.primary)
                                            .padding(6)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // MARK: - Tip Card with Toggle
                HStack(spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                            Text("Tip")
                                .font(AppTypography.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.primary)
                        }
                        
                        Text("Turn on Do Not Disturb to minimize distractions and stay in the zone.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewModel.isDoNotDisturbEnabled)
                        .labelsHidden()
                        .tint(AppColors.primary)
                }
                .padding(AppSpacing.md)
                .appCardStyle(cornerRadius: AppRadius.lg)
                
                // MARK: - Server sync feedback
                if let syncError = viewModel.syncErrorMessage {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "FF6B4A"))
                        Text(syncError)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                    }
                    .padding(AppSpacing.sm)
                    .appCardStyle(cornerRadius: AppRadius.md)
                }

                // MARK: - Primary Action Button
                AppButton(title: "Start Focus", icon: "play.fill", style: .primary) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        viewModel.startFocus()
                    }
                }
                .padding(.top, AppSpacing.sm)
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.canvas.ignoresSafeArea())
    }
    
    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.primary)
                .frame(width: 24)
            
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.textSecondary)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
    }
}

#Preview {
    FocusPreparationView(viewModel: FocusSessionViewModel())
}
