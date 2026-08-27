import SwiftUI

/// Authentication entry point: sign in, with an inline toggle to create an
/// account (backend requires a password of at least 12 characters).
public struct LoginView: View {
    @State private var authSession = AuthSession.shared
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isRegistering = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isShowingScanner = false
    @State private var isShowingConfirmation = false
    @State private var challengeToExchange: String?
    @State private var isAuthenticatingQr = false

    private let authService: AuthService
    private let qrAuthService: QRAuthenticationService = .shared

    public init(authService: AuthService = .shared) {
        self.authService = authService
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isRegistering ? "Create your account" : "Welcome back.")
                            .font(AppTypography.largeTitle)
                            .foregroundStyle(AppColors.textPrimary)

                        Text("What deserves your attention today?")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.top, AppSpacing.xl)

                    if !isRegistering {
                        // QR Login Entry
                        VStack(spacing: AppSpacing.md) {
                            Text("Scan the QR code\nfrom your Productivity OS account\nto continue.")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, AppSpacing.md)

                            AppButton(
                                title: "Scan QR",
                                icon: "qrcode.viewfinder",
                                style: .primary
                            ) {
                                isShowingScanner = true
                            }
                        }
                        .padding(AppSpacing.lg)
                        .frame(maxWidth: .infinity)
                        .appCardStyle(cornerRadius: AppRadius.xl)

                        HStack {
                            VStack { Divider().background(AppColors.surfaceBorder) }
                            Text("OR")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textTertiary)
                                .padding(.horizontal, AppSpacing.sm)
                            VStack { Divider().background(AppColors.surfaceBorder) }
                        }
                        .padding(.vertical, AppSpacing.sm)
                    }

                    // Form Card
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EMAIL")
                                .font(AppTypography.sectionHeader)
                                .foregroundStyle(AppColors.primary)
                            TextField("you@example.com", text: $email)
                                .font(AppTypography.body)
                                .autocorrectionDisabled()
                                #if os(iOS)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                #endif
                        }

                        Divider().background(AppColors.surfaceBorder)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("PASSWORD")
                                .font(AppTypography.sectionHeader)
                                .foregroundStyle(AppColors.primary)
                            SecureField(isRegistering ? "At least 12 characters" : "Your password", text: $password)
                                .font(AppTypography.body)
                                #if os(iOS)
                                .textInputAutocapitalization(.never)
                                #endif
                        }

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                                .font(AppTypography.caption)
                                .foregroundStyle(Color(hex: "FF6B4A"))
                        }
                    }
                    .padding(AppSpacing.lg)
                    .appCardStyle(cornerRadius: AppRadius.xl)

                    // Primary action
                    AppButton(
                        title: isLoading ? "Please wait..." : (isRegistering ? "Create Account" : "Log In"),
                        icon: nil,
                        style: .primary
                    ) {
                        submit()
                    }
                    .disabled(isLoading || !isInputValid)
                    .opacity(isInputValid ? 1 : 0.6)

                    // Mode toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isRegistering.toggle()
                            errorMessage = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isRegistering ? "Already have an account?" : "New to Productivity OS?")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            Text(isRegistering ? "Log in" : "Create an account")
                                .font(AppTypography.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColors.canvas.ignoresSafeArea())
            .sheet(isPresented: $isShowingScanner) {
                QRScannerView(
                    onCodeScanned: { code in
                        if let challenge = qrAuthService.parseChallenge(from: code) {
                            challengeToExchange = challenge
                            isShowingScanner = false
                            // Delay slightly to allow scanner to dismiss before showing confirmation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isShowingConfirmation = true
                            }
                        } else {
                            errorMessage = "This QR code isn't valid. Please scan the QR code generated by Productivity OS."
                            isShowingScanner = false
                        }
                    },
                    onCancel: {
                        isShowingScanner = false
                    }
                )
            }
            .sheet(isPresented: $isShowingConfirmation) {
                if let challenge = challengeToExchange {
                    QRConfirmationView(
                        isLoading: isAuthenticatingQr,
                        onContinue: {
                            authenticateWithQr(challenge: challenge)
                        },
                        onCancel: {
                            isShowingConfirmation = false
                            challengeToExchange = nil
                        }
                    )
                    .presentationDetents([PresentationDetent.medium])
                }
            }
        }
    }

    private var isInputValid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else { return false }
        return !password.isEmpty
    }

    private func submit() {
        guard !isLoading else { return }
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                if isRegistering {
                    try await authService.register(email: trimmedEmail, password: password)
                    try await authService.login(email: trimmedEmail, password: password)
                } else {
                    try await authService.login(email: trimmedEmail, password: password)
                }
                // AuthSession.isAuthenticated flips → app root shows MainTabView.
            } catch {
                errorMessage = FocusSessionViewModel.userMessage(for: error)
            }
        }
    }

    private func authenticateWithQr(challenge: String) {
        isAuthenticatingQr = true
        errorMessage = nil
        
        Task {
            defer { 
                isAuthenticatingQr = false
                isShowingConfirmation = false
                challengeToExchange = nil
            }
            do {
                try await qrAuthService.authenticate(challenge: challenge)
            } catch {
                errorMessage = FocusSessionViewModel.userMessage(for: error)
            }
        }
    }
}

#Preview {
    LoginView()
}
