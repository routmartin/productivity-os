#if os(iOS)
import SwiftUI

/// Profile view with theme switching and developer tools
public struct ProfileView: View {
    @State private var authSession = AuthSession.shared
    #if DEBUG && os(iOS)
    @State private var showDevLog = false
    #endif

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
                            settingRow(icon: "moon.fill", title: "Appearance", value: "Light")
                            Divider().background(AppColors.surfaceBorder)
                            settingRow(icon: "waveform", title: "Focus Sounds", value: "Lo-Fi")
                        }
                        .appCardStyle(cornerRadius: AppRadius.md)
                    }

                    // Developer Tools
                    #if DEBUG && os(iOS)
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SectionHeaderView(title: "Developer Tools")

                        VStack(spacing: 0) {
                            developerRow(icon: "terminal", title: "API Request Log", value: "View requests") {
                                showDevLog = true
                            }
                        }
                        .appCardStyle(cornerRadius: AppRadius.md)
                    }
                    #endif

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
            .preferredColorScheme(.light)
            #if DEBUG && os(iOS)
            .sheet(isPresented: $showDevLog) {
                DevAPIRequestLogView()
            }
            #endif
        }
    }

    // MARK: - Rows

    private func developerRow(icon: String, title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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

// MARK: - Developer Tools entry

#Preview {
    ProfileView()
}
#endif
