// Simple placeholder QRScannerView for use in LoginView. Replace with real scanner when ready.
import SwiftUI

/// Placeholder scanner view that lets the user enter a value manually for testing purposes.
public struct QRScannerView: View {
    let onCodeScanned: (String) -> Void
    let onCancel: () -> Void
    @State private var code: String = ""

    public init(
        onCodeScanned: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onCodeScanned = onCodeScanned
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColors.primary)
                    .padding(.top, 24)
                Text("Simulated QR Scanner")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                TextField("Paste or type QR challenge", text: $code)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                AppButton(title: "Scan", style: .primary) {
                    onCodeScanned(code)
                }
                .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Spacer()
            }
            .navigationTitle("Scan QR")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding()
        }
    }
}

#Preview {
    QRScannerView(
        onCodeScanned: { _ in },
        onCancel: {}
    )
}
