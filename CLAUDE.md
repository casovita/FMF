# FMF – Fitness Monster Factory

Skills academy iOS app. Skill progression for handstand, pullups, handstand pushups.

## Quick Commands

```bash
cd apps/ios_app
xcodegen generate                          # regenerate .xcodeproj after adding files
xcodebuild -project FMF.xcodeproj -scheme FMF-Dev \
  -destination "platform=iOS Simulator,name=iPhone 17" build
xcodebuild -project FMF.xcodeproj -scheme FMF-Dev \
  -destination "platform=iOS Simulator,name=iPhone 17" test
```

## Architecture Rules

- Feature-first + layered: `Features/<Name>/` contains View + ViewModel only
- No business logic in Views
- Repository protocols in `Domain/Repositories/`; implementations in `Data/Repositories/`
- State: `@Observable @MainActor` ViewModels (iOS 17 — no Riverpod)
- Navigation: `NavigationStack` + `navigationDestination` + `TabView`
- Models: plain Swift `struct` (value semantics, no codegen)
- Persistence: GRDB.swift via `AppDatabase` — never call GRDB directly from Views

## Coding Rules

- `@Observable @MainActor` on every ViewModel
- Repository protocols marked `: Sendable` for Swift 6
- `nonisolated(unsafe)` on `EnvironmentKey.defaultValue` for repo protocol types
- No hardcoded user-visible strings — use `String(localized:)` + `Localizable.strings`
- Run `xcodegen generate` after adding/removing source files

## Testing

- Framework: Swift Testing (`@Suite`, `@Test`, `#expect`)
- Unit tests in `Tests/Unit/`
- Run before every PR — must all pass with zero errors

## Forbidden

- No secrets or API keys in source
- No direct GRDB calls from Views — always through repositories
- No business logic in View files
- No UIKit imports in feature Views (AVFoundation in `PoseDetectionService` is the exception)

## Flavors

| Scheme   | Config           | App title               |
|----------|------------------|-------------------------|
| FMF-Dev  | dev.xcconfig     | FMF [DEV]               |
| FMF-Prod | prod.xcconfig    | Fitness Monster Factory |

## Before Finishing Work

1. `xcodebuild build` — zero errors, zero warnings
2. `xcodebuild test` — all tests pass
3. `xcodegen generate` — if files were added/removed
4. No `.env` files staged

## Key Files

| File | Purpose |
|------|---------|
| `Sources/App/FMFApp.swift` | `@main`, injects repos via `.environment` |
| `Sources/App/EnvironmentKeys.swift` | `SkillRepository` + `PracticeSessionRepository` env keys |
| `Sources/Data/Database/AppDatabase.swift` | GRDB pool, `DatabaseWriter` protocol |
| `Sources/Domain/Repositories/` | Protocol definitions |
| `Sources/Features/` | All screens — one folder per feature |
| `project.yml` | XcodeGen spec — edit this, then `xcodegen generate` |
| `Resources/Localizable.strings` | All user-visible strings |

## Product Context

FMF is a **skills academy** — structured progression toward fitness skills.
Not a workout logger. Not a social app. Not a calorie tracker.
Navigation and content should feel like entering a training curriculum.

## Conventional Commits

```
feat(home): add skill module cards to dashboard
fix(workout): correct Vision y-axis handstand check
chore(deps): bump GRDB to 6.1.0
docs(readme): update setup instructions
test(skill): add unit tests for PracticeSession model
```
