import SwiftUI

/// Tab selection enum
public enum AppTab: String, CaseIterable, Identifiable {
    case today = "Today"
    case focus = "Focus"
    case tasks = "Tasks"
    case me = "Me"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .today: return "house.fill"
        case .focus: return "scope"
        case .tasks: return "checklist"
        case .me: return "person.fill"
        }
    }
}

/// Custom bottom tab navigation bar matching `today.png`
public struct CustomTabBar: View {
    @Binding public var selectedTab: AppTab
    
    public init(selectedTab: Binding<AppTab>) {
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        HStack {
            ForEach(AppTab.allCases) { tab in
                let isSelected = selectedTab == tab
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        // Top active indicator line
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isSelected ? AppColors.primary : Color.clear)
                            .frame(width: 24, height: 3)
                        
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? AppColors.primary : AppColors.textTertiary)
                            .frame(height: 24)
                        
                        Text(tab.rawValue)
                            .font(AppTypography.captionSmall)
                            .fontWeight(isSelected ? .bold : .medium)
                            .foregroundStyle(isSelected ? AppColors.primary : AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, 6)
        .padding(.bottom, 24)
        .background(
            AppColors.surface
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(.today))
    }
    .background(AppColors.canvas)
}
