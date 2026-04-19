.PHONY: setup get clean analyze format format-check test codegen codegen-watch run-dev run-staging run-prod build-ios-dev doctor help

APP_DIR := apps/mobile_app

setup:
	@echo "→ Installing FVM..."
	@dart pub global activate fvm
	@echo "→ Installing Flutter via FVM..."
	@fvm install
	@echo "→ Activating melos..."
	@dart pub global activate melos
	@echo "→ Bootstrapping workspace..."
	@melos bootstrap
	@echo "✓ Setup complete. Run: make run-dev"

get:
	@melos bootstrap

clean:
	@melos run clean

analyze:
	@melos run analyze

format:
	@melos run format

format-check:
	@melos run format:check

test:
	@melos run test

codegen:
	@melos run codegen

codegen-watch:
	@melos run codegen:watch

run-dev:
	@cd $(APP_DIR) && fvm flutter run --flavor dev -t lib/main_dev.dart

run-staging:
	@cd $(APP_DIR) && fvm flutter run --flavor staging -t lib/main_staging.dart

run-prod:
	@cd $(APP_DIR) && fvm flutter run --flavor prod -t lib/main_prod.dart

build-ios-dev:
	@cd $(APP_DIR) && fvm flutter build ios --flavor dev -t lib/main_dev.dart

doctor:
	@fvm flutter doctor -v

help:
	@echo "Available targets:"
	@echo "  setup           Install FVM, Flutter, melos, and bootstrap workspace"
	@echo "  get             Get all dependencies"
	@echo "  clean           Clean all packages"
	@echo "  analyze         Run flutter analyze"
	@echo "  format          Format all Dart code"
	@echo "  format-check    Check formatting (CI)"
	@echo "  test            Run all tests"
	@echo "  codegen         Run build_runner on all packages"
	@echo "  codegen-watch   Watch and regenerate on changes"
	@echo "  run-dev         Run on iOS simulator (dev flavor)"
	@echo "  run-staging     Run on iOS simulator (staging flavor)"
	@echo "  run-prod        Run on iOS simulator (prod flavor)"
	@echo "  build-ios-dev   Build iOS archive (dev)"
	@echo "  doctor          Run flutter doctor -v"
