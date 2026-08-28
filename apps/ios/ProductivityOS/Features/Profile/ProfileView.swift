import SwiftUI

/// Profile view with theme switching and developer tools
public struct ProfileView: View {
    @State private var authSession = AuthSession.shared
    @AppStorage("selectedTheme") private var selectedTheme: String = "system"
    @State private var showThemePicker = false
    @State private var showDevLog = false

    public init() {}

    var themeBinding: ColorScheme? {
        switch selectedTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

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
                            themeSettingRow()
                            Divider().background(AppColors.surfaceBorder)
                            settingRow(icon: "waveform", title: "Focus Sounds", value: "Lo-Fi")
                        }
                        .appCardStyle(cornerRadius: AppRadius.md)
                    }

                    // Developer Tools
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SectionHeaderView(title: "Developer Tools")

                        VStack(spacing: 0) {
                            developerRow(icon: "terminal", title: "API Request Log", value: "View requests") {
                                showDevLog = true
                            }
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
            .preferredColorScheme(themeBinding)
            .sheet(isPresented: $showThemePicker) {
                themePickerSheet()
            }
            .sheet(isPresented: $showDevLog) {
                DevAPIRequestLogView()
            }
        }
    }

    // MARK: - Rows

    private func themeSettingRow() -> some View {
        Button {
            showThemePicker = true
        } label: {
            HStack {
                Image(systemName: "moon.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 28)

                Text("Appearance")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text(selectedTheme.capitalized)
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

    // MARK: - Theme Picker

    @ViewBuilder
    private func themePickerSheet() -> some View {
        NavigationStack {
            List {
                Section("Theme") {
                    themeOptionRow(label: "System", value: "system")
                    themeOptionRow(label: "Light", value: "light")
                    themeOptionRow(label: "Dark", value: "dark")
                }
            }
            .navigationTitle("Appearance")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showThemePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func themeOptionRow(label: String, value: String) -> some View {
        Button {
            selectedTheme = value
            showThemePicker = false
        } label: {
            HStack {
                Text(label)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                if selectedTheme == value {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Developer Log View

public struct DevAPIRequestLogView: View {
    @StateObject private var logStore = APILogStore.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("API Requests") {
                    if logStore.logEntries.isEmpty {
                        Text("No requests logged.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    } else {
                        ForEach(logStore.logEntries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(entry.method)
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundStyle(entry.status == nil ? AppColors.textSecondary : (entry.status ?? 0 >= 200 && (entry.status ?? 0) < 300 ? AppColors.primary : .red))
                                    Spacer()
                                    Text(entry.timestamp, style: .time)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(AppColors.textTertiary)
                                }
                                Text(entry.url)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                if let status = entry.status {
                                    Text("Status: \(status)")
                                        .font(.system(.caption2))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                if !entry.bodyPreview.isEmpty {
                                    Text(entry.bodyPreview)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(AppColors.textTertiary)
                                        .lineLimit(3)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("API Request Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") {
                        logStore.clear()
                    }
                    .font(.system(.subheadline, weight: .semibold))
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    ProfileView()
}
