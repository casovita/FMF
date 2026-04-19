#!/usr/bin/env bash
set -euo pipefail
cd apps/mobile_app
fvm flutter run --flavor prod -t lib/main_prod.dart "$@"
