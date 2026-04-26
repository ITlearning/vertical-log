# iOS Setup

This directory contains the iOS source files for vertical-log. The Xcode project itself (`.xcodeproj`) is **not** committed — each developer creates it locally.

## Why no committed `.xcodeproj`?

`.xcodeproj` files are binary, hard to merge, and tend to thrash on every change. Source files committed; project re-created on first checkout.

## First-time setup (one-time, ~5 minutes)

1. Open Xcode (16+).
2. **File → New → Project**.
3. iOS → **App** → Next.
4. Settings:
   - Product Name: `VerticalLog`
   - Team: your Apple ID (free tier is fine for V0)
   - Organization Identifier: `com.itlearning` (or your reverse-DNS)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - Include Tests: **checked**
5. Save location: select the `ios/` directory of this repo. **Uncheck "Create Git Repository"** (we already have one).
6. Xcode creates `ios/VerticalLog.xcodeproj` plus default files in `ios/VerticalLog/` and `ios/VerticalLogTests/` — these will overwrite stub files. **Cancel the overwrite** when prompted, OR delete the Xcode-default files (`VerticalLogApp.swift`, `ContentView.swift`, default test) and add the existing scaffolded files via **File → Add Files to "VerticalLog"…** → select all `.swift` files in `ios/VerticalLog/` recursively.
7. Build settings:
   - Deployment target: **iOS 17.0**
   - Signing: select your Team. Bundle ID: `com.itlearning.verticallog`.
8. Add capability: **Signing & Capabilities → + Capability → Sign in with Apple**.
9. Add Info.plist keys (or set in build settings):
   - `NSCameraUsageDescription` = "9:16 클립을 캡처하기 위해 카메라가 필요해요"
   - `NSMicrophoneUsageDescription` = "클립 음성 녹음에 필요해요" (V0는 muted compile이지만 capture는 audio 포함)

## Build & test (post-setup)

- Build & run: `Cmd+R` (Xcode)
- Test: `Cmd+U` (Xcode) — runs Swift Testing suite
- CI: see `.github/workflows/ios.yml` (added in Sprint 1)

## File layout

```
ios/
├── VerticalLog.xcodeproj/      # local only, gitignored
├── VerticalLog/
│   ├── App/
│   │   ├── VerticalLogApp.swift   # @main
│   │   └── RootView.swift         # auth-aware root
│   ├── Features/
│   │   ├── Auth/AuthView.swift    # Sign in with Apple
│   │   ├── Capture/CaptureView.swift  # 9:16 camera (TODO)
│   │   ├── Feed/FeedView.swift    # room timeline
│   │   └── Rooms/RoomsView.swift  # list/create/join
│   └── Core/
│       ├── Models/Models.swift    # Codable structs
│       ├── Networking/APIClient.swift
│       └── Storage/               # Keychain, local clip queue (Sprint 1)
└── VerticalLogTests/
    └── ModelsTests.swift
```

## Sprint 1 implementation TODOs (in source files)

Search the project for `TODO(sprint-1):` to find all stubs.

- AVCaptureSession 9:16 capture with 2-sec auto-stop
- Sign in with Apple → backend `POST /auth/apple` → JWT in Keychain
- Room create/join API wiring
- Local clip upload queue
- AVPlayer-backed feed cells

## Sprint 2+ (deferred)

- iOS Local Notifications (1시간 cadence) + BGAppRefreshTask
- Compile player view
- CAGL share button (downloads `share_ready.mp4` → iOS share sheet)
- Realtime chat (Supabase Realtime client)
