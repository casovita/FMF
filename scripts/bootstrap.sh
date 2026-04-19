#!/usr/bin/env bash
set -euo pipefail

echo "==> FMF Bootstrap"

if ! command -v fvm &>/dev/null; then
  echo "→ Installing FVM..."
  dart pub global activate fvm
fi

echo "→ Installing Flutter stable via FVM..."
fvm install

echo "→ Activating melos..."
dart pub global activate melos

echo "→ Running melos bootstrap..."
melos bootstrap

echo ""
echo "✓ Bootstrap complete"
echo ""
echo "Next steps:"
echo "  make run-dev       # Run on iOS simulator (dev flavor)"
echo "  make codegen       # Generate .g.dart and .freezed.dart files"
echo "  make test          # Run all tests"
