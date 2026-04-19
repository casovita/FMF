#!/usr/bin/env bash
set -euo pipefail

echo "==> Running flutter analyze"
melos run analyze
echo "✓ Analysis complete"
