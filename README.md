# vertical-log

> 일상은 세로로. (가로는 본격, 세로는 일상.)

Setlog 1:1 벤치마킹 + 세로 캡처 + CAGL share-ready compile.

## 구조

```
vertical-log/
├── ios/                  # SwiftUI 네이티브 앱 (V0 main target)
│   ├── Package.swift
│   ├── Sources/VerticalLog/
│   └── Tests/VerticalLogTests/
├── web/                  # Next.js (Vercel Functions API + admin/landing)
│   ├── app/
│   │   └── api/          # Vercel Functions
│   ├── lib/db/           # Drizzle schema + migrations
│   └── workers/          # Compile pipeline (ffmpeg)
├── shared/               # OpenAPI spec, shared types
├── scripts/              # CAGL prototype, dev tools
└── .github/workflows/    # CI
```

## V0 Features (3.5주, 시퀀스 ship)

- **주1 (A)**: 9:16 세로 캡처 + 방/그룹 + 수동 포스팅 + feed
- **주2 (B)**: iOS Local Notifications (1시간 cadence) + 자동 데일리 컴파일 (long + CAGL share-ready)
- **주3 (C)**: 인앱 채팅

## Stack

- **iOS**: Swift / SwiftUI 네이티브 (Sign in with Apple, AVCaptureSession)
- **Backend**: Vercel Functions + Fluid Compute (Node)
- **DB**: Neon Postgres (Marketplace)
- **Storage**: Vercel Blob (presigned PUT)
- **Realtime**: Supabase Realtime (Marketplace, chat 채널)
- **Push**: iOS Local Notifications (1시간) + APNs (chat)
- **Compile**: ffmpeg via Fluid Compute (xstack + pad + drawtext for CAGL)
- **Android (V1+)**: [Skip](https://skip.dev) — SwiftUI → Jetpack Compose

## Decision references

- Design doc: `~/.gstack/projects/vertical-log/tabber-main-design-2026-04-26.md`
- CAGL spec: design doc Section 12a
- Eng review: 2026-04-26 (clean, 0 critical gaps)
- CEO review: 2026-04-26 (CAGL added as differentiator #2)

## Quick start

```bash
# 1. CAGL prototype 검증 (가장 먼저 실행)
./scripts/cagl-prototype.sh

# 2. iOS 빌드 (Xcode에서)
open ios/Package.swift

# 3. Backend setup (Sprint 2)
cd web && npm install
vercel link  # Vercel 연동
vercel env pull
```

## License

Private. All rights reserved.
