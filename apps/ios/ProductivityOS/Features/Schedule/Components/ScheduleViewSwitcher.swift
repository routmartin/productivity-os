import SwiftUI

/// Segmented view switcher for Spine, Journey, and Matrix layouts (Spec AC-001).
public struct ScheduleViewSwitcher: View {
    @Binding public var activeLayout: ScheduleLayoutMode
    public var onLayoutChanged: ((ScheduleLayoutMode) -> Void)?

    public init(
        activeLayout: Binding<ScheduleLayoutMode>,
        onLayoutChanged: ((ScheduleLayoutMode) -> Void)? = nil
    ) {
        self._activeLayout = activeLayout
        self.onLayoutChanged = onLayoutChanged
    }

    private let modes: [ScheduleLayoutMode] = ScheduleLayoutMode.allCases

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(modes, id: \.id) { mode in
                let isSelected = (activeLayout == mode)

                Button {
                    withAnimation(AppMotion.standard) {
                        activeLayout = mode
                        onLayoutChanged?(mode)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))

                        Text(mode.displayName)
                            .font(AppTypography.caption)
                            .fontWeight(isSelected ? .semibold : .medium)
                    }
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                    .fill(AppColors.surface)
                                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(Color(hex: "F0EBF8"))
        )
    }
}
