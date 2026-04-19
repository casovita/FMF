#!/usr/bin/env bash
set -euo pipefail

echo "==> Running code generation on all packages"
melos run codegen
echo "✓ Code generation complete"
