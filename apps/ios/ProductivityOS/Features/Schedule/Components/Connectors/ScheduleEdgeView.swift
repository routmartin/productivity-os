import SwiftUI

/// Connecting link edge showing flow and active habit stack illumination (Spec AC-005).
public struct ScheduleEdgeView: View {
    public let active: Bool
    public let height: CGFloat
    public let label: String?

    public init(active: Bool, height: CGFloat = 20, label: String? = nil) {
        self.active = active
        self.height = height
        self.label = label
    }

    public var body: some View {
        HStack(spacing: 8) {
            Spacer().frame(width: 24)

            ZStack {
                // Background Track / Inactive dashed
                if !active {
                    Line()
                        .stroke(
                            Color(hex: "CBD5E1"),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4])
                        )
                        .frame(width: 2, height: height)
                } else {
                    // Active Illuminated Solid Line
                    Line()
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.primary, Color(hex: "A855F7")],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 3, height: height)
                        .shadow(color: AppColors.primary.opacity(0.4), radius: 4, x: 0, y: 0)
                }
            }

            if let label = label {
                Text(label)
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(active ? AppColors.primary : AppColors.textSecondary)
            }

            Spacer()
        }
        .frame(height: height)
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}
