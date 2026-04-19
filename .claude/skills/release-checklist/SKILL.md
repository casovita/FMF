# Skill: release-checklist

Run through FMF release preparation steps.

## Usage

```
/release-checklist [version]
```

Example: `/release-checklist 1.0.0`

## Steps

1. Verify version in `apps/mobile_app/pubspec.yaml` matches `[version]`
2. Run `make analyze` — must be clean
3. Run `make test` — must pass
4. Run `make format-check` — must pass
5. Run `make codegen` — verify no uncommitted generated files
6. Verify CHANGELOG has entry for this version
7. Scan for `// TODO:` comments tagged `before-release`
8. Verify flavor configs (dev/staging/prod) are correct in `app_flavor.dart`
9. Check CI is green on main branch
10. Verify iOS build compiles: `make build-ios-dev`
11. Check no `.env` files staged

## Output

Numbered checklist with ✓/✗ per step.
Block release on any ✗.
Append "Ready to release ✓" or "NOT ready — N items blocked ✗".
