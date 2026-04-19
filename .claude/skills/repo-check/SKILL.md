# Skill: repo-check

Run a full health check on the FMF repository.

## Usage

```
/repo-check
```

## Checks

1. `make analyze` — lint and type errors
2. `make format-check` — formatting compliance
3. `make test` — full test suite
4. Scan for `.env` files that should not be committed
5. Scan for `*.g.dart` or `*.freezed.dart` committed by mistake
6. Verify no hardcoded user-visible strings in `presentation/` layer
7. Verify no Drift imports in `presentation/` or `application/` layers
8. Verify all routes in `router.dart` have corresponding screen files
9. Verify all repository interfaces in `fmf_domain` have implementations in `fmf_data`
10. Check `analysis_options.yaml` is present and not overridden

## Output Format

```
✓ analyze — clean
✗ format-check — 3 files need formatting: [list]
✓ tests — 12 passed
...
```

Report issues with file:line references. Block on any ✗.
