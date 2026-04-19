#!/usr/bin/env bash
set -euo pipefail

echo "==> Running tests"
melos run test
echo "✓ Tests complete"
