# Elite360.DriveArmor

iOS parental-control app for driving safety. Parents remotely enable "safe mode" on their child's device to minimize distractions while driving. Built with **SwiftUI**, **Firebase**, and Apple's **CoreMotion/CoreLocation** APIs.

---

## Prerequisites

| Tool | Version |
|------|---------|
| **macOS** | 15+ (Sequoia) |
| **Xcode** | 17+ |
| **CocoaPods** | 1.15+ (`sudo gem install cocoapods`) |
| **XcodeGen** | 2.40+ (`brew install xcodegen`) |
| **Firebase CLI** | latest (`npm install -g firebase-tools`) — optional, for rules deployment |

## Quick Start

### 1. Clone & Generate

```bash
git clone https://github.com/elite2700/Elite360.DriveArmor.git
cd Elite360.DriveArmor

# Generate the Xcode project from project.yml
xcodegen generate

# Install CocoaPods dependencies
pod install
```

### 2. Firebase Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project (or use an existing one).
2. Add an **iOS app** with bundle ID `com.elite360.DriveArmor`.
3. Download **GoogleService-Info.plist** and replace the placeholder at:
   ```
   DriveArmor/Resources/GoogleService-Info.plist
   ```
4. Enable the following in Firebase Console:
   - **Authentication** → Email/Password sign-in
   - **Cloud Firestore** → Create database (start in test mode, then deploy rules)
   - **Cloud Messaging** → Upload your APNs authentication key

5. (Optional) Deploy Firestore security rules:
   ```bash
   firebase login
   firebase init firestore   # point to existing firestore.rules
   firebase deploy --only firestore:rules
   ```

### 3. Configure Signing

Open `DriveArmor.xcworkspace` (not `.xcodeproj`) in Xcode:

1. Select the **DriveArmor** target → Signing & Capabilities.
2. Set your **Team** and **Bundle Identifier**.
3. Ensure these capabilities are enabled:
   - Push Notifications
   - Background Modes: Location updates, Background fetch, Remote notifications, Background processing

### 4. Build & Run

```
⌘ + R  in Xcode
```

- Run on a **physical device** for CoreMotion/CoreLocation (simulator has limited support).
- For driving simulation in the simulator, use **Debug → Simulate Location → Freeway Drive**.

---

## Project Structure

```
DriveArmor/
├── App/                        # Entry point, AppDelegate, AppState, ContentView
├── Models/                     # Codable data models (User, Family, Command, etc.)
├── Services/                   # Firebase & Apple API abstractions
│   ├── AuthService.swift       # Firebase Auth wrapper
│   ├── FamilyService.swift     # Family CRUD and pairing
│   ├── CommandService.swift    # Real-time command pub/sub
│   ├── DeviceStatusService.swift # Child status + driving logs
│   ├── DrivingDetectionService.swift # CoreMotion + CoreLocation
│   ├── SafeModeService.swift   # Notification suppression + overlay
│   ├── LocationService.swift   # CLLocationManager wrapper
│   └── NotificationService.swift # FCM token + local notifications
├── ViewModels/                 # MVVM view models with @Published state
├── Views/
│   ├── Auth/                   # Login, SignUp, RoleSelection
│   ├── Parent/                 # Dashboard, ChildStatusCard, Reports, RemoteControl
│   ├── Child/                  # Dashboard, SafeModeOverlay
│   ├── Pairing/                # CreateFamily, JoinFamily
│   ├── Settings/               # SettingsView
│   └── Shared/                 # LoadingView, ErrorBanner
├── Extensions/                 # Color theme, Date formatting
├── Constants/                  # AppConstants
├── Resources/                  # Info.plist, Assets, GoogleService-Info.plist
└── DriveArmor.entitlements
```

## Architecture

**MVVM** with service layer:

```
View  →  ViewModel  →  Service  →  Firebase / Apple APIs
                          ↕
                      Combine Publishers (real-time updates)
```

- **Views** are pure SwiftUI; they only read `@Published` properties from ViewModels.
- **ViewModels** are `@MainActor ObservableObject` classes that call async service methods.
- **Services** encapsulate all Firebase SDK and Apple framework calls behind clean async/await interfaces.
- **AppState** (global `@EnvironmentObject`) manages auth lifecycle and top-level navigation routing.

### Data Flow

```
Parent Device                    Firebase Firestore                    Child Device
─────────────                    ──────────────────                    ────────────
Tap "Enable Safe Mode"
  → CommandService.sendCommand()
     → /families/{id}/commands/{id}  ──→  Snapshot listener triggers
                                           → CommandService.listenForCommands()
                                             → SafeModeService.activate()
                                               → Show overlay, suppress notifications

Child status updates (every 10s)  ←──  /families/{id}/deviceStatus/{childId}
  → ParentDashboardViewModel
    subscribes via Combine
```

## Firestore Schema

| Path | Purpose |
|------|---------|
| `/users/{uid}` | User profile (role, familyId, fcmToken) |
| `/families/{familyId}` | Family group (parentId, childIds, pairingCode) |
| `/families/{fId}/commands/{cId}` | Safe-mode commands (type, status, params) |
| `/families/{fId}/deviceStatus/{childId}` | Child's real-time status |
| `/families/{fId}/drivingLogs/{logId}` | Completed driving session records |

## Running Tests

```bash
# Unit tests
xcodebuild test -workspace DriveArmor.xcworkspace -scheme DriveArmor -destination 'platform=iOS Simulator,name=iPhone 16'

# Or in Xcode: ⌘ + U
```

## Key Design Decisions

- **No airplane-mode toggling**: iOS sandboxing prohibits this. Safe mode uses an app-internal overlay + notification suppression instead.
- **Pairing via code**: A 6-character code (no confusable characters) is simpler and more reliable than QR codes for the initial MVP.
- **Combine for real-time**: Firestore snapshot listeners are wrapped in `PassthroughSubject` publishers, consumed by ViewModels via `.sink()`.
- **Background location**: Uses `activityType = .automotiveNavigation` and `significantChangeMonitoring` to balance accuracy vs battery life.

## License

Proprietary — Elite360. All rights reserved.
