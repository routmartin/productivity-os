# Productivity OS — iOS Project

---

## Visual Design Source of Truth

The UI is modeled directly from the approved design references in `docs/design/references/`:

- **Today Screen**: [`docs/design/references/ios-today-approved.png`](../../docs/design/references/ios-today-approved.png) (`today.png`)
- **Focus Flow**: [`docs/design/references/ios-focus-flow-approved.png`](../../docs/design/references/ios-focus-flow-approved.png) (`focsu-flow.png`)

---

## Project Structure

```text
apps/ios/
├── Package.swift                             # Swift Package configuration
├── ProductivityOS/
│   ├── App/
│   │   └── ProductivityOSApp.swift           # SwiftUI App entry point
│   ├── Core/
│   │   ├── DesignSystem/
│   │   │   ├── AppColors.swift               # Palette (Lavender canvas, Dark Navy focus, Priority pills)
│   │   │   ├── AppTypography.swift           # Typography scales (Display, Rounded titles, Mono timers)
│   │   │   ├── AppSpacing.swift              # 4pt grid spacing and corner radius tokens
│   │   │   └── Components/
│   │   │       ├── AppCard.swift             # Soft elevated card container
│   │   │       ├── AppButton.swift           # Primary purple gradient, secondary, and focus controls
│   │   │       ├── TaskRowView.swift         # Numbered badge (01..03), icon, priority pill, chevron
│   │   │       ├── SectionHeaderView.swift   # Tracked uppercase section header with action link
│   │   │       ├── FocusClockView.swift      # Circular clipping / ring clock with glowing arc & mono digits
│   │   │       └── CustomTabBar.swift        # Floating bottom navigation (Today, Focus, Tasks, Me)
│   │   ├── Networking/
│   │   │   ├── APIConfiguration.swift        # Environment configuration (Dev/Staging/Prod)
│   │   │   ├── APIError.swift                # Strongly typed network errors
│   │   │   ├── Endpoint.swift                # Type-safe endpoint definition protocol
│   │   │   └── APIClient.swift               # Native URLSession + async/await API client
│   │   ├── Authentication/
│   │   │   ├── KeychainManager.swift         # Secure Apple Keychain token storage
│   │   │   └── AuthSession.swift             # Observable authentication state & token holder
│   │   ├── Extensions/
│   │   │   ├── Color+Hex.swift               # Hex color initializer utility
│   │   │   └── View+Extensions.swift         # Card modifiers and focus styling
│   │   └── Utilities/
│   │       └── SampleData.swift              # 100% offline sample data for SwiftUI previews
│   ├── Features/
│   │   ├── Main/
│   │   │   └── MainTabView.swift             # Root tab navigation and Focus transition orchestrator
│   │   ├── Today/
│   │   │   ├── TodayView.swift               # Today screen matching today.png reference
│   │   │   └── TodayViewModel.swift          # Today feature state and Top 3 presenter
│   │   ├── Focus/
│   │   │   ├── FocusPreparationView.swift    # Task selection, duration chips, tip toggle
│   │   │   ├── ActiveFocusView.swift         # Hero deep navy running/paused focus mode
│   │   │   ├── FocusCompletionView.swift     # Calm completion acknowledgement
│   │   │   └── FocusSessionViewModel.swift   # Focus session manager & timestamp calculator
│   │   ├── Tasks/
│   │   │   └── TasksView.swift               # Task list and browsing scaffolding
│   │   └── Profile/
│   │       └── ProfileView.swift             # User profile, preferences, and logout
│   ├── Models/
│   │   ├── User.swift                        # User model matching backend DTO
│   │   ├── Task.swift                        # TaskItem with Priority, Energy, TaskStatus
│   │   ├── TopThree.swift                    # TopThreeItem model matching backend DTO
│   │   ├── FocusDuration.swift               # 25m, 45m, 60m, Unlimited duration options
│   │   ├── FocusSession.swift                # FocusSession model matching backend DTO
│   │   └── FocusSessionState.swift           # Timestamp-based resilient focus state machine
│   └── Resources/
│       └── Info.plist                        # Application bundle manifest
└── ProductivityOSTests/
    ├── FocusSessionStateTests.swift          # State transitions and time calculations
    ├── FocusTimerCalculationsTests.swift     # Backgrounding and suspension resilience tests
    ├── ModelDecodingTests.swift              # Backend JSON contract decoding tests
    └── KeychainManagerTests.swift            # Secure storage validation tests
```

---

## Building and Running

### 1. In Xcode

Open `apps/ios/` in Xcode (`open apps/ios` or `xed apps/ios`), select an iOS Simulator (e.g., iPhone 16 Pro), and press **⌘R** to run.

### 2. From Terminal via `xcodebuild`

```bash
cd apps/ios
xcodebuild build -scheme ProductivityOS -destination "generic/platform=iOS Simulator"
```

### 3. Running Unit Tests

```Shell
cd apps/ios
swift test
```
