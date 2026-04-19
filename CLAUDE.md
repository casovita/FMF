# FMF – Fitness Monster Factory

Skills academy iOS app. Skill progression for handstand, pullups, handstand pushups.

## Quick Commands

```bash
make setup          # first-time setup
make run-dev        # run iOS simulator, dev flavor
make test           # run all tests
make analyze        # lint check
make codegen        # regenerate .g.dart + .freezed.dart files
```

## Architecture Rules

- Feature-first + layered: presentation / application / domain / data
- No business logic in widgets
- No direct Drift access from UI — always go through repositories
- Repository interfaces live in `packages/domain`; implementations in `packages/data`
- State management: Riverpod with `@riverpod` code generation
- Routing: go_router, routes defined in `apps/mobile_app/lib/app/router.dart`
- Models: freezed + json_serializable (immutable, codegen)
- Persistence: Drift via AppDatabase in `packages/data`

## Coding Rules

- Prefer `const` constructors everywhere possible
- Always use package imports (not relative) across packages
- No `dynamic` usage unless unavoidable (annotate with `// ignore: avoid_dynamic_calls`)
- Immutable models only — use freezed
- Small, testable providers; no god providers
- Never hardcode strings visible to users — use l10n ARB keys

## Testing Expectations

- Unit tests for domain logic and use cases
- Widget tests for key screens
- Integration tests in `integration_test/` for CI smoke runs
- Run `make test` before opening a PR

## Forbidden

- No secrets or API keys in source files
- No direct `sqflite`/sqlite calls — use Drift DAOs
- No business logic in `presentation/` layer
- No `setState` in feature screens — use Riverpod
- No `.g.dart` or `.freezed.dart` files committed to git (they're gitignored)

## Flavors

| Flavor   | Entry point         | App title        |
|----------|---------------------|------------------|
| dev      | main_dev.dart       | FMF [DEV]        |
| staging  | main_staging.dart   | FMF [STAGING]    |
| prod     | main_prod.dart      | Fitness Monster Factory |

## Before Finishing Work

1. `make analyze` — must pass
2. `make format-check` — must pass
3. `make test` — must pass
4. `make codegen` — if models changed
5. No `.env` files staged

## Packages

| Package              | Purpose                            |
|----------------------|------------------------------------|
| `fmf_core`           | Shared utilities, Result type      |
| `fmf_design_system`  | Tokens, theme, Material 3 base     |
| `fmf_domain`         | Domain models, repo interfaces     |
| `fmf_data`           | Drift DB, repo implementations     |
| `apps/mobile_app`    | Flutter app, features, UI          |

## Product Context

FMF is a **skills academy** — structured progression toward fitness skills.
Not a workout logger. Not a social app. Not a calorie tracker.
Navigation and content should feel like entering a training curriculum.

## Conventional Commits

```
feat(home): add skill module cards to dashboard
fix(drift): correct schema version migration
chore(deps): bump go_router to 17.2.1
docs(readme): add flavor setup instructions
test(skill): add unit tests for PracticeSession model
```
