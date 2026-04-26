# iOS Setup — Xcode Project Creation

이 디렉토리는 비어있어요. Xcode에서 iOS App 프로젝트를 만든 다음, 만들어진 자리에 source 파일을 다시 채워넣을 거예요.

## 1. Xcode에서 새 프로젝트 만들기 (5분)

1. **Xcode 16+** 실행.
2. **File → New → Project** (`Cmd+Shift+N`)
3. **iOS → App** 선택 → **Next**
4. 옵션:
   - Product Name: **`VerticalLog`**
   - Team: 본인 Apple ID (free 계정도 OK)
   - Organization Identifier: `com.itlearning` (또는 본인의 reverse-DNS)
   - Bundle ID: 자동으로 `com.itlearning.VerticalLog`이 됨
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - **Include Tests** 체크 ✓
5. **Next** → 저장 위치 선택:
   - `~/vertical-log/ios/` 폴더로 이동
   - "Create Git Repository on my Mac" **언체크** (이미 git repo 있음)
   - **Create**

6. Xcode가 만든 결과:
   ```
   ios/
   ├── VerticalLog.xcodeproj/        ← 이건 commit됨 (.gitignore에서 제외 안 함)
   ├── VerticalLog/
   │   ├── VerticalLogApp.swift      ← Xcode default @main
   │   ├── ContentView.swift          ← Xcode default 초기 view
   │   ├── Assets.xcassets/
   │   └── Preview Content/
   └── VerticalLogTests/
       └── VerticalLogTests.swift
   ```

## 2. 프로젝트 설정

빌드 전에 몇 가지 설정 변경:

### Deployment target
- 좌측 navigator에서 `VerticalLog` 프로젝트 클릭
- TARGETS → VerticalLog → General 탭
- **Minimum Deployments → iOS**: `17.0`

### Signing & Capabilities
- Signing & Capabilities 탭
- Team 선택 (본인 Apple ID)
- Bundle Identifier 확인: `com.itlearning.VerticalLog`
- **+ Capability** → **Sign in with Apple** 추가

### Info.plist 추가 keys (Sprint 1 카메라 작업 전 필요)
프로젝트 → TARGETS → VerticalLog → Info 탭에서 추가:
- `NSCameraUsageDescription` = `9:16 클립을 캡처하기 위해 카메라가 필요해요`
- `NSMicrophoneUsageDescription` = `클립 음성 녹음에 필요해요`

(또는 Xcode 16에선 build settings의 INFOPLIST_KEY_NSCameraUsageDescription 등으로 직접 입력 가능)

## 3. 빌드 & 빈 프로젝트 확인

`Cmd+R` → 시뮬레이터에서 default `Hello, world!` 화면 보이면 OK.

`Cmd+U` → default test가 통과하면 OK.

## 4. 알려주세요

여기까지 되면 알려주세요. 그러면 source 파일 (`VerticalLogApp.swift`, `RootView.swift`, `Features/...`, `Core/...`, 테스트 등)을 모두 정확한 자리에 다시 작성합니다. Xcode에서 "Add Files to VerticalLog..."로 새로 추가된 폴더들 일괄 추가하면 됩니다.

## 트러블슈팅

- **"Folder 'VerticalLog' already exists"** 경고가 뜨면: 이미 `ios/VerticalLog/` 가 있다는 뜻. 직전에 직접 만들었거나 잔여 파일. `ls ios/` 확인 후 비우고 재시도.
- **Xcode 버전 mismatch**: Xcode 16+ 필요. App Store에서 업데이트.
- **CI ios.yml 실패**: 이건 본인이 첫 commit push까지 빨간색일 수 있음. xcodeproj 생성 후 첫 push에서 처음으로 정상 작동.
