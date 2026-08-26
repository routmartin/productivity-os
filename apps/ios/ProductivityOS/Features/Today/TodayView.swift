import SwiftUI

/// Today View matching `today.png` approved visual reference
public struct TodayView: View {
    @State private var viewModel = TodayViewModel()
    private let onStartFocus: (TaskItem?) -> Void
    private let onSelectTask: (TaskItem) -> Void
    
    public init(
        onStartFocus: @escaping (TaskItem?) -> Void = { _ in },
        onSelectTask: @escaping (TaskItem) -> Void = { _ in }
    ) {
        self.onStartFocus = onStartFocus
        self.onSelectTask = onSelectTask
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // MARK: - Header (Greeting & Avatar)
                    headerSection
                    
                    // MARK: - Today's Intention Hero Card
                    intentionHeroCard
                    
                    // MARK: - YOUR TOP 3 Section
                    topThreeSection
                    
                    // MARK: - FOCUS TODAY Card
                    focusTodayCard
                    
                    // MARK: - Bottom Stats Row
                    bottomStatsRow
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 100) // Extra padding for bottom navigation
            }
            .background(AppColors.canvas.ignoresSafeArea())
            .task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good afternoon, \(viewModel.userName).")
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("What deserves your attention?")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
            
            // User Avatar with glowing gradient rim
            ZStack {
                Circle()
                    .fill(AppColors.primaryTint)
                    .frame(width: 48, height: 48)
                
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(AppColors.primary.opacity(0.8))
            }
            .overlay(
                Circle()
                    .stroke(AppColors.primary.opacity(0.2), lineWidth: 2)
            )
        }
    }
    
    private var intentionHeroCard: some View {
        ZStack(alignment: .topTrailing) {
            // Background artwork decoration
            LinearGradient(
                colors: [Color(hex: "F3EFFF"), Color(hex: "EAE4FF"), Color(hex: "DFD6FF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle sun/circle illustration
            Circle()
                .fill(Color(hex: "D8CCFD").opacity(0.5))
                .frame(width: 110, height: 110)
                .offset(x: -20, y: 10)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Sparkle Badge
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                    
                    Text("Today's Intention")
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.6))
                .clipShape(Capsule())
                
                // Quote
                Text(viewModel.intentionQuote)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineSpacing(4)
                
                Spacer(minLength: 8)
                
                // Footer
                HStack(spacing: 6) {
                    Image(systemName: "heart")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.primary)
                    
                    Text(viewModel.intentionFooter)
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 145)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: AppColors.primary.opacity(0.08), radius: 14, x: 0, y: 6)
    }
    
    private var topThreeSection: some View {
        VStack(spacing: AppSpacing.sm) {
            SectionHeaderView(title: "Your Top 3", actionTitle: "View all") {
                // View all action
            }

            if viewModel.isLoading && viewModel.topThreeTasks.isEmpty {
                APIStateView(kind: .loading(message: "Loading your day..."))
            } else if let errorMessage = viewModel.errorMessage {
                APIStateView(
                    kind: .error(message: errorMessage),
                    onRetry: { Task { await viewModel.loadData() } }
                )
            } else if viewModel.topThreeTasks.isEmpty {
                APIStateView(
                    kind: .empty(
                        icon: "flag",
                        title: "No Top 3 yet",
                        subtitle: "Pick today's most meaningful tasks to see them here."
                    )
                )
            } else {
                ForEach(Array(viewModel.topThreeTasks.enumerated()), id: \.element.id) { index, task in
                    let iconName: String = {
                        switch index {
                        case 0: return "flag.fill"
                        case 1: return "chevron.left.forwardslash.chevron.right"
                        default: return "square.grid.2x2.fill"
                        }
                    }()

                    TaskRowView(
                        position: index + 1,
                        title: task.title,
                        projectName: task.projectName ?? "Productivity OS",
                        priority: task.priority ?? .medium,
                        iconName: iconName
                    ) {
                        onSelectTask(task)
                    }
                }
            }
        }
    }
    
    private var focusTodayCard: some View {
        HStack(spacing: AppSpacing.md) {
            // Mini Focus Ring
            FocusClockView(
                progress: viewModel.todayFocusProgress,
                timerText: viewModel.formattedTodayFocusedTime,
                variant: .mini
            )
            .frame(width: 130, height: 130)
            
            // Right CTA details
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                    
                    Text("FOCUS TODAY")
                        .font(AppTypography.captionSmall)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.primary)
                        .tracking(0.5)
                }
                
                Text("Deep work brings meaningful results.")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
                
                Spacer()
                
                AppButton(title: "Start Focus", icon: "play.fill", style: .primary) {
                    onStartFocus(viewModel.topThreeTasks.first)
                }
                .frame(height: 44)
            }
        }
        .padding(AppSpacing.md)
        .appCardStyle(
            backgroundColor: Color(hex: "F7F5FE"),
            borderColor: AppColors.primary.opacity(0.12),
            cornerRadius: AppRadius.xl
        )
    }
    
    private var bottomStatsRow: some View {
        HStack(spacing: 0) {
            statItem(icon: "timer", count: "\(viewModel.completedSessionsCount)", label: "Sessions")
            
            Divider()
                .frame(height: 36)
                .background(AppColors.surfaceBorder)
            
            statItem(icon: "flame.fill", count: "\(viewModel.dayStreak)", label: "Day streak", iconColor: Color(hex: "FF6B4A"))
            
            Divider()
                .frame(height: 36)
                .background(AppColors.surfaceBorder)
            
            statItem(icon: "chart.line.uptrend.xyaxis", count: viewModel.weeklyFocusFormatted, label: "This week", iconColor: AppColors.primary)
        }
        .padding(.vertical, AppSpacing.md)
        .appCardStyle(cornerRadius: AppRadius.lg)
    }
    
    private func statItem(icon: String, count: String, label: String, iconColor: Color = AppColors.primary) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(count)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text(label)
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TodayView()
}
