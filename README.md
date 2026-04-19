# Fitness Monster Factory (FMF)

A skills academy iOS app for fitness skill progression.

**Skills:** Handstand · Pull-ups · Handstand Push-ups

---

## Stack

| Layer       | Tech                           |
|-------------|--------------------------------|
| State       | Riverpod 3.x (`@riverpod`)     |
| Routing     | go_router 17.x                 |
| Persistence | Drift 2.x (local SQLite)       |
| Models      | freezed + json_serializable    |
| Monorepo    | melos 7.x + Dart pub workspace |
| Design      | Material 3 + FMF token layer   |
| CI          | GitHub Actions                 |

---

## Quick Start

**Prerequisites:** macOS + Apple Silicon, Xcode, FVM

```bash
# One-time setup
make setup

# Run on iOS simulator (dev flavor)
make run-dev
```

---

## Workspace Packages

| Package                    | Description                          |
|----------------------------|--------------------------------------|
| `apps/mobile_app`          | Flutter iOS app                      |
| `packages/fmf_core`        | Shared utilities (Result type, etc.) |
| `packages/fmf_design_system` | Material 3 + FMF tokens            |
| `packages/fmf_domain`      | Domain models, repository interfaces |
| `packages/fmf_data`        | Drift DB, local repo implementations |

---

## Development Workflow

```bash
make get            # Get all dependencies
make codegen        # Generate .g.dart + .freezed.dart
make analyze        # Run lint checks
make test           # Run all tests
make format         # Format code
```

---

## Flavors

| Flavor   | Command             | App Title               |
|----------|---------------------|-------------------------|
| dev      | `make run-dev`      | FMF [DEV]               |
| staging  | `make run-staging`  | FMF [STAGING]           |
| prod     | `make run-prod`     | Fitness Monster Factory |

---

## Commit Convention

Uses [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(home): add skill module cards to dashboard
fix(drift): correct schema migration
chore(deps): bump go_router to 17.2.1
```

---

## Architecture

```
presentation/   widgets, screens (read providers only)
application/    Riverpod providers, controllers
domain/         models (freezed), repository interfaces
data/           Drift tables, DAOs, repo implementations
```

Dependency flow: `mobile_app` → `fmf_data` → `fmf_domain` → `fmf_core`

---

## TODOs Before Production

- [ ] Configure Xcode schemes for dev/staging/prod flavors (native)
- [ ] Set bundle IDs: `com.fmf.app`, `com.fmf.app.dev`, `com.fmf.app.staging`
- [ ] Add app icons per flavor
- [ ] Configure backend when leaving POC stage
- [ ] Implement auth state and route guards
- [ ] Add integration test CI job with iOS simulator
