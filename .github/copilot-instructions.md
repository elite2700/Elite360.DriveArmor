# Copilot Instructions for Elite360.DriveArmor

## Project overview
iOS parental-control app for driving safety. Single binary with **Parent** and **Child** roles. Swift 5.9 / SwiftUI / Combine / Firebase (Auth + Firestore + FCM) / CoreMotion + CoreLocation.

## Build & run
```bash
xcodegen generate          # Creates DriveArmor.xcodeproj from project.yml
pod install                # Installs Firebase pods
open DriveArmor.xcworkspace
# Replace DriveArmor/Resources/GoogleService-Info.plist with your real Firebase config
# ⌘+R on a physical device (CoreMotion requires real hardware)
```
Run tests: `⌘+U` or `xcodebuild test -workspace DriveArmor.xcworkspace -scheme DriveArmor -destination 'platform=iOS Simulator,name=iPhone 16'`

## Architecture (MVVM + Service layer)
```
View → ViewModel (@MainActor ObservableObject) → Service → Firebase / Apple APIs
                      ↕
              Combine Publishers (real-time Firestore listeners)
```
- **AppState** (`DriveArmor/App/AppState.swift`) is the global `@EnvironmentObject` managing auth stage and role-based navigation routing.
- **ContentView** switches between auth flow, pairing flow, and role dashboards based on `AppState.authStage`.
- ViewModels are `@MainActor`; they own service instances and expose `@Published` properties.
- Views never import Firebase directly — all backend access goes through services in `DriveArmor/Services/`.

## Key services and their responsibilities
| Service | File | Purpose |
|---------|------|---------|
| `AuthService` | Services/AuthService.swift | Firebase Auth + `/users` profile CRUD |
| `FamilyService` | Services/FamilyService.swift | `/families` CRUD, pairing code join |
| `CommandService` | Services/CommandService.swift | Write commands (parent), listen + ack (child) |
| `DeviceStatusService` | Services/DeviceStatusService.swift | Child status writes, parent subscriptions, driving logs |
| `DrivingDetectionService` | Services/DrivingDetectionService.swift | CoreMotion + CoreLocation driving detection |
| `SafeModeService` | Services/SafeModeService.swift | Overlay + notification suppression (no airplane mode) |

## Firestore schema (do not change paths without updating all services)
- `/users/{uid}` — profile with `role`, `familyId`, `fcmToken`
- `/families/{familyId}` — `parentId`, `childIds[]`, `pairingCode`
- `/families/{fId}/commands/{cId}` — `type` (`enableSafeMode`/`disableSafeMode`), `status`, `targetChildId`, `params`
- `/families/{fId}/deviceStatus/{childId}` — live child state
- `/families/{fId}/drivingLogs/{logId}` — completed driving sessions

## Conventions to follow
- Models live in `DriveArmor/Models/`, each has `asDictionary` and `static from(dictionary:…)` for Firestore round-tripping.
- Views are grouped by role: `Views/Auth/`, `Views/Parent/`, `Views/Child/`, `Views/Pairing/`, `Views/Settings/`, `Views/Shared/`.
- Use `CommandType` and `CommandStatus` enums (in `CommandModel.swift`) — do not use raw strings.
- Pairing codes are 6-char uppercase alphanumeric (excluding confusable chars 0/O/1/I) — see `FamilyModel.generatePairingCode()`.
- Safe mode must NOT toggle airplane mode or any capability prohibited by iOS sandboxing. Use the overlay + notification approach in `SafeModeService`.
- Constants go in `DriveArmor/Constants/AppConstants.swift` (Firestore paths, thresholds, notification strings).

## Scope guardrails
- Do not add features outside the blueprint in `readme.txt` (no web portals, no Android, no billing/subscriptions).
- Keep changes incremental and traceable to blueprint requirements.
- Security rules live in `firestore.rules` — keep them in sync with any schema changes.