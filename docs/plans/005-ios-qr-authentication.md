# Plan 005 — iOS QR Authentication

Implement QR-based authentication for the iOS application, including necessary backend and web support.

## Phase 1: Backend Implementation

1. **Database Migration:** Add `qr_auth_challenges` table.
2. **Persistence:** Create `QrAuthChallenge` entity and `QrAuthChallengeRepository`.
3. **Service:** Create `QrAuthService` to handle challenge generation, validation, and exchange.
4. **Controller:** Add `qr/challenge` and `qr/exchange` endpoints to `AuthController`.
5. **Tests:** Unit tests for challenge lifecycle and exchange security.

## Phase 2: Web Implementation

1. **API Integration:** Add `qrAuth` methods to the web API client.
2. **UI:** Add a "Connect Device" section to the Profile or Settings page.
3. **QR Generation:** Implement QR code rendering for `productivityos://auth?challenge={value}`.
4. **UX:** Handle challenge expiration and refresh on the web side.

## Phase 3: iOS Foundation & Entry

1. **App Root:** Ensure `ProductivityOSApp` restores session and handles the `isAuthenticated` state correctly.
2. **Login View:** Update `LoginView` to lead with "Scan QR" instead of email/password (keeping email/password as a secondary option if needed, but per spec, it's mostly QR now).
3. **Service:** Create `QRAuthenticationService`.

## Phase 4: iOS QR Scanner

1. **Native Scanner:** Implement `QRScannerView` using `AVFoundation` or `DataScannerViewController` (if iOS 16+).
2. **Permissions:** Handle camera permission flow and denied states.
3. **Validation:** Recognize `productivityos://auth?challenge=...` and extract the challenge.

## Phase 5: iOS Confirmation & Exchange

1. **Confirmation UI:** "Connect to Productivity OS?" screen with Continue/Cancel.
2. **API Call:** Call `POST /auth/qr/exchange`.
3. **Session Update:** On success, update `AuthSession` and navigate to Today.
4. **Error Handling:** Handle expired, used, or invalid challenges with user-friendly messages.

## Phase 6: Verification & Security

1. **Security Audit:** Ensure no sensitive data is logged or stored insecurely.
2. **Accessibility:** Add VoiceOver support and accessible labels.
3. **End-to-End Test:** Manual verification of the full web -> iOS flow.
4. **Unit Tests:** Add iOS tests for scanner validation and auth exchange logic.

## Acceptance Criteria Traceability

| ID | Requirement | Status |
|----|-------------|--------|
| AC-001 | Unauthenticated iOS app shows QR authentication | PASS |
| AC-002 | User can open QR scanner with permissions | PASS |
| AC-003 | Valid Productivity OS QR is recognized | PASS |
| AC-004 | User must explicitly confirm authentication | PASS |
| AC-005 | Challenge is exchanged with backend | PASS |
| AC-006 | Session is securely stored and AuthSession updated | PASS |
| AC-007 | Expired/used challenges handled correctly | PASS |
| AC-008 | No sensitive data in logs or QR payload | PASS |
