import SwiftUI

/// Standard section header with uppercase title and optional trailing action
public struct SectionHeaderView: View {
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?
    
    public init(
        title: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        HStack {
            Text(title.uppercased())
                .font(AppTypography.sectionHeader)
                .foregroundStyle(AppColors.primary)
                .tracking(0.8)
            
            Spacer()
            
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 2) {
                        Text(actionTitle)
                            .font(AppTypography.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    SectionHeaderView(title: "Your Top 3", actionTitle: "View all") {}
        .padding()
        .background(AppColors.canvas)
}
