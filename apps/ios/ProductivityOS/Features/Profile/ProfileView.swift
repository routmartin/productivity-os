import SwiftUI

/// Profile & Settings view scaffolding
public struct ProfileView: View {
    @State private var authSession = AuthSession.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Profile Header Card
                    HStack(spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryTint)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                                .foregroundStyle(AppColors.primary.opacity(0.8))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authSession.currentUser?.displayName ?? "Rout")
                                .font(AppTypography.headline)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Text(authSession.currentUser?.email ?? "rout@productivityos.com")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(AppSpacing.md)
                    .appCardStyle(cornerRadius: AppRadius.lg)
                    
                    // Preferences Group
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SectionHeaderView(title: "Preferences")
                        
                        VStack(spacing: 0) {
                            settingRow(icon: "bell.badge", title: "Notifications", value: "Enabled")
                            Divider().background(AppColors.surfaceBorder)
                            settingRow(icon: "moon.fill", title: "Appearance", value: "System")
                            Divider().background(AppColors.surfaceBorder)
                            settingRow(icon: "waveform", title: "Focus Sounds", value: "Lo-Fi")
                        }
                        .appCardStyle(cornerRadius: AppRadius.md)
                    }
                    
                    // Account / App Info Group
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SectionHeaderView(title: "About")
                        
                        VStack(spacing: 0) {
                            settingRow(icon: "info.circle", title: "Version", value: "0.1.0 Foundation")
                            Divider().background(AppColors.surfaceBorder)
                            settingRow(icon: "server.rack", title: "API Environment", value: APIConfiguration.shared.environment.rawValue.capitalized)
                        }
                        .appCardStyle(cornerRadius: AppRadius.md)
                    }
                    
                    // Sign out
                    AppButton(title: "Log Out", style: .secondary) {
                        Task {
                            await AuthService.shared.logout()
                        }
                    }
                    .padding(.top, AppSpacing.sm)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 100)
            }
            .background(AppColors.canvas.ignoresSafeArea())
            .navigationTitle("Me")
        }
    }
    
    private func settingRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColors.primary)
                .frame(width: 28)
            
            Text(title)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.caption)
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
    ProfileView()
}
