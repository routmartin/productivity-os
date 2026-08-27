import SwiftUI
import AVFoundation

#if os(iOS)
import UIKit
#endif

/// Native QR scanner using AVFoundation.
public struct QRScannerView: View {
    let onCodeScanned: (String) -> Void
    let onCancel: () -> Void
    
    @State private var isScanning = true
    @State private var permissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var initializationError: String?
    
    public init(onCodeScanned: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.onCodeScanned = onCodeScanned
        self.onCancel = onCancel
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.canvas.ignoresSafeArea()
                
                #if os(iOS)
                if let error = initializationError {
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "camera.badge.ellipsis")
                            .font(.system(size: 48))
                            .foregroundStyle(AppColors.textSecondary)
                        
                        Text("Camera Error")
                            .font(AppTypography.headline)
                        
                        Text(error)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                    }
                } else if permissionStatus == .authorized {
                    ScannerCoordinatorView(
                        isScanning: $isScanning,
                        onCodeScanned: handleScannedCode,
                        onInitializationError: { error in
                            self.initializationError = error
                        }
                    )
                    .ignoresSafeArea()
                    
                    // Scanner Overlay
                    VStack {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(AppColors.primary, lineWidth: 4)
                            .frame(width: 250, height: 250)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .accessibilityLabel("QR Scanner Frame")
                            .accessibilityHint("Position the Productivity OS QR code inside this frame to scan.")
                        
                        Text("Align QR code within the frame")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(.white)
                            .padding(.top, 24)
                            .shadow(radius: 4)
                        
                        Spacer()
                    }
                } else if permissionStatus == .denied || permissionStatus == .restricted {
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(AppColors.textSecondary)
                        
                        Text("Camera Access Required")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Text("Productivity OS uses your camera to securely connect this device to your account.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                        
                        AppButton(title: "Open Settings", style: .primary) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .padding(AppSpacing.xl)
                } else {
                    ProgressView()
                        .tint(AppColors.primary)
                }
                #else
                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text("Scanner not available")
                        .font(AppTypography.headline)
                    
                    Text("QR scanning is only available on iOS devices.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppSpacing.xl)
                #endif
            }
            .navigationTitle("Scan QR Code")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(AppColors.primary)
                }
            }
            .onAppear {
                checkPermission()
            }
        }
    }
    
    private func checkPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        DispatchQueue.main.async {
            self.permissionStatus = status
        }
        
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.permissionStatus = granted ? .authorized : .denied
                }
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        isScanning = false
        onCodeScanned(code)
    }
}

#if os(iOS)
/// UIViewRepresentable bridge for AVCaptureSession.
struct ScannerCoordinatorView: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    let onCodeScanned: (String) -> Void
    let onInitializationError: (String) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned, onInitializationError: onInitializationError)
    }
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let onCodeScanned: (String) -> Void
        let onInitializationError: (String) -> Void
        
        init(onCodeScanned: @escaping (String) -> Void, onInitializationError: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
            self.onInitializationError = onInitializationError
        }
        
        func didScanCode(_ code: String) {
            onCodeScanned(code)
        }
        
        func didFailInitialization(error: String) {
            onInitializationError(error)
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didScanCode(_ code: String)
    func didFailInitialization(error: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    weak var delegate: ScannerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.didFailInitialization(error: "No camera found on this device. The scanner requires physical camera hardware.")
            return
        }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.didFailInitialization(error: "Unable to access the camera: \(error.localizedDescription)")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            delegate?.didFailInitialization(error: "Unable to add camera input to the capture session.")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            delegate?.didFailInitialization(error: "Unable to add QR detection to the capture session.")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func startScanning() {
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopScanning() {
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanCode(stringValue)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        previewLayer.frame = view.layer.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
}
#endif
