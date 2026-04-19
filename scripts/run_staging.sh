#!/usr/bin/env bash
set -euo pipefail
cd apps/mobile_app
fvm flutter run --flavor staging -t lib/main_staging.dart "$@"
