# Fitness Monster Factory (FMF)

Skills academy iOS app for structured fitness skill progression.

**Skills:** Handstand · Pull-ups · Handstand Push-ups

---

## Stack

| Layer       | Tech                                  |
|-------------|---------------------------------------|
| UI          | SwiftUI (iOS 17+)                     |
| State       | `@Observable` + `@MainActor`          |
| Navigation  | `NavigationStack` + `TabView`         |
| Persistence | GRDB.swift ~> 6.0 (local SQLite)      |
| Pose detect | Apple Vision `VNDetectHumanBodyPoseRequest` |
| Camera      | AVFoundation                          |
| Project     | XcodeGen (`project.yml`)              |

**One external dependency:** GRDB.swift. Everything else is Apple SDK.

---

## Quick Start

**Prerequisites:** macOS, Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
cd apps/ios_app
xcodegen generate
open FMF.xcodeproj
```

Run scheme `FMF-Dev` on any iPhone 17 simulator.

---

## Project Structure

```
apps/ios_app/
  project.yml              ← XcodeGen spec
  Sources/
    App/                   ← @main, environment keys, flavors
    DesignSystem/          ← tokens (color, spacing, radius, typography)
    Domain/                ← models + repository protocols
    Data/                  ← GRDB tables + local repo implementations
    Features/              ← one folder per screen
  Tests/Unit/              ← Swift Testing suite (13 tests)
  Resources/               ← Assets, Localizable.strings, Info.plist
```

---

## Flavors

| Scheme    | Config          | App Title               |
|-----------|-----------------|-------------------------|
| FMF-Dev   | dev.xcconfig    | FMF [DEV]               |
| FMF-Prod  | prod.xcconfig   | Fitness Monster Factory |

---

## Running Tests

```bash
cd apps/ios_app
xcodebuild test \
  -project FMF.xcodeproj \
  -scheme FMF-Dev \
  -destination "platform=iOS Simulator,name=iPhone 17"
```

---

## Commit Convention

Uses [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(home): add skill module cards
fix(workout): correct Vision y-axis handstand check
chore(deps): bump GRDB to 6.1.0
```
