# CLAUDE.md — vertical-log

## Project context

Korean 직장인 친구 그룹용 세로 캡처 + 자동 데일리 vlog 앱. Setlog의 vertical 버전. 차별점:
1. 세로 캡처 (SOCIAL friction 제거)
2. CAGL share-ready compile (IG/TikTok/YT Shorts overlay에 안 가려짐)

V0 launch group: 본인 + 직장인 친구 4명. TestFlight.

## Source of truth

- Design doc: `~/.gstack/projects/vertical-log/tabber-main-design-2026-04-26.md`
- CAGL layout spec: design doc Section 12a (1080×1920, 2×2 grid centered, top/bottom 400px dead zones)
- Eng review patches: design doc Section 14
- CEO review patches: design doc Section 15

## Conventions

### Swift / iOS
- iOS 17+ minimum
- SwiftUI first, UIKit only when SwiftUI insufficient (camera preview)
- Async/await, no Combine for new code
- File naming: `FeatureNameView.swift`, `FeatureNameViewModel.swift`
- Tests: Swift Testing framework (`@Test`), XCTest fallback for iOS 16

### Web / Backend
- Next.js App Router (Vercel Fluid Compute, Node runtime)
- Drizzle ORM for Postgres
- Vercel.ts for project config (NOT vercel.json)
- API routes under `web/app/api/`
- Workers (ffmpeg compile) under `web/workers/` (called from cron API route)

### Database
- All IDs UUID v7 (time-ordered)
- Timestamps UTC, display TZ in client
- Soft delete via `deleted_at` only on `users` (others: hard delete)

### Git
- Conventional commits: `feat(ios): ...`, `fix(web): ...`, `chore: ...`
- Branch per feature: `feat/capture`, `feat/rooms`, `feat/compile`
- No commits to main without PR (once GitHub set up)

## Critical do-not-break

- **9:16 capture geometry**: AVCaptureSession sessionPreset + videoOrientation locked. Don't touch without testing on physical device.
- **CAGL safe zones (400/400px)**: hardcoded in ffmpeg pipeline. Verified via IG upload screenshot 2026-04-26 (TBD pending sprint 1 check).
- **Sign in with Apple anon-relay handling**: never assume email matches across users. Use invite code for friend matching.
- **iOS Local Notification 64 pending limit**: refresh on app open via BGAppRefreshTask.

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.

Key routing:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", crashes → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Architecture review for new feature → invoke plan-eng-review
- CEO/strategy review → invoke plan-ceo-review
- Update docs after shipping → invoke document-release
- Save progress, checkpoint, resume → invoke checkpoint
- iOS-specific TDD → invoke everything-claude-code-ios:swift-tdd
- iOS code review → invoke everything-claude-code-ios:swift-review
- iOS security review → invoke everything-claude-code-ios:ios-security-review
- iOS build/compile error → invoke everything-claude-code-ios:xcode-build-fix
- XCUITest E2E → invoke everything-claude-code-ios:xcuitest

## Testing

- **iOS**: Swift Testing framework (iOS 17+). Run via `swift test` from `ios/` or Xcode `Cmd+U`.
- **Web**: Vitest. Run via `npm test` from `web/`.
- **E2E (V0)**: Manual TestFlight with friend group. XCUITest for V1+.
- **CAGL output**: pixel-diff against reference frame (`scripts/cagl-verify.sh`, V1+).

100% coverage 목표. 새 함수 추가 시 테스트 동시 작성. 버그 픽스 시 회귀 테스트 필수.

## Environment

- Local: macOS, Xcode 16+, Node 24+, ffmpeg installed (`brew install ffmpeg`).
- CI: GitHub Actions (iOS test, web test, lint).
- Deploy: Vercel (web), TestFlight (iOS).

## Active blockers / context

- **Sprint 1 in progress** (2026-04-26~): monorepo init, CAGL prototype validation, iOS scaffold, web scaffold.
- Apple Developer account: free tier 가정 (V0 친구 4명 TestFlight 충분).
- Vercel auth: pending sprint 2.
- GitHub repo: pending first push (private 가정).
