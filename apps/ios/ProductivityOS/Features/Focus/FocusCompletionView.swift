import SwiftUI

/// Calm Focus Completion acknowledgement matching spec
public struct FocusCompletionView: View {
    private let focusedDurationSeconds: TimeInterval
    private let onDone: () -> Void
    
    public init(
        focusedDurationSeconds: TimeInterval,
        onDone: @escaping () -> Void = {}
    ) {
        self.focusedDurationSeconds = focusedDurationSeconds
        self.onDone = onDone
    }
    
    private var formattedDuration: String {
        let totalMinutes = max(1, Int(focusedDurationSeconds) / 60)
        return "\(totalMinutes) minutes"
    }
    
    public var body: some View {
        ZStack {
            AppColors.canvas.ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // Sparkle / lotus calm emblem
                ZStack {
                    Circle()
                        .fill(AppColors.primaryTint)
                        .frame(width: 88, height: 88)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
                
                VStack(spacing: AppSpacing.xs) {
                    Text("Well done.")
                        .font(AppTypography.largeTitle)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("\(formattedDuration) focused.")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                AppButton(title: "Done", style: .primary, action: onDone)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
            }
        }
    }
}

#Preview {
    FocusCompletionView(focusedDurationSeconds: 2520) {}
}
