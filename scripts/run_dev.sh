#!/usr/bin/env bash
set -euo pipefail
cd apps/mobile_app
fvm flutter run --flavor dev -t lib/main_dev.dart "$@"
