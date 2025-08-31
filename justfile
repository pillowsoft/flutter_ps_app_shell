#!/usr/bin/env just --justfile

# Default recipe - shows available commands
default:
    @just --list

# Setup the project (install dependencies for package and example)
setup:
    @echo "Setting up Flutter App Shell project..."
    cd packages/flutter_app_shell && flutter pub get
    cd example && flutter pub get
    @echo "Setup complete!"

# Run the example app
run:
    cd example && flutter run

# Run the example app on web
run-web:
    cd example && flutter run -d chrome

# Run the example app on iOS simulator
run-ios:
    cd example && flutter run -d ios

# Run the example app on Android
run-android:
    cd example && flutter run -d android

# Run the example app on macOS
run-macos:
    cd example && flutter run -d macos

# Run tests for the package
test-package:
    cd packages/flutter_app_shell && flutter test

# Run tests for the example app
test-example:
    cd example && flutter test

# Run all tests
test: test-package test-example

# Analyze the package code
analyze-package:
    cd packages/flutter_app_shell && flutter analyze

# Analyze the example code
analyze-example:
    cd example && flutter analyze

# Analyze all code
analyze: analyze-package analyze-example

# Format the package code
format-package:
    cd packages/flutter_app_shell && dart format .

# Format the example code
format-example:
    cd example && dart format .

# Format all code
format: format-package format-example

# Clean build artifacts for package
clean-package:
    cd packages/flutter_app_shell && flutter clean

# Clean build artifacts for example
clean-example:
    cd example && flutter clean

# Clean all build artifacts
clean: clean-package clean-example

# Build example for all platforms
build-all: build-android build-ios build-web build-macos build-windows build-linux

# Build Android APK
build-android:
    cd example && flutter build apk

# Build iOS
build-ios:
    cd example && flutter build ios

# Build for web
build-web:
    cd example && flutter build web

# Build for macOS
build-macos:
    cd example && flutter build macos

# Build for Windows
build-windows:
    cd example && flutter build windows

# Build for Linux
build-linux:
    cd example && flutter build linux

# Check outdated dependencies in package
outdated-package:
    cd packages/flutter_app_shell && flutter pub outdated

# Check outdated dependencies in example
outdated-example:
    cd example && flutter pub outdated

# Check all outdated dependencies
outdated: outdated-package outdated-example

# Upgrade dependencies in package
upgrade-package:
    cd packages/flutter_app_shell && flutter pub upgrade

# Upgrade dependencies in example
upgrade-example:
    cd example && flutter pub upgrade

# Upgrade all dependencies
upgrade: upgrade-package upgrade-example

# Publish the package (dry run)
publish-dry:
    cd packages/flutter_app_shell && flutter pub publish --dry-run

# Publish the package
publish:
    cd packages/flutter_app_shell && flutter pub publish

# Create a new feature in the example app
create-feature name:
    @echo "Creating new feature: {{name}}"
    mkdir -p example/lib/features/{{name}}
    @echo "Feature {{name}} created at example/lib/features/{{name}}"

# Run integration tests
integration-test:
    cd example && flutter test integration_test

# Generate coverage report for package
coverage-package:
    cd packages/flutter_app_shell && flutter test --coverage
    cd packages/flutter_app_shell && genhtml coverage/lcov.info -o coverage/html

# Generate coverage report for example
coverage-example:
    cd example && flutter test --coverage
    cd example && genhtml coverage/lcov.info -o coverage/html

# Generate all coverage reports
coverage: coverage-package coverage-example

# Development mode - runs example with hot reload
dev:
    cd example && flutter run

# Quick check before committing
pre-commit: format analyze test
    @echo "Pre-commit checks passed!"

# Full CI pipeline simulation
ci: clean setup format analyze test build-web
    @echo "CI pipeline completed successfully!"

# Generate llms.txt files for documentation
generate-llms:
    @echo "Generating llms.txt files for Flutter App Shell documentation..."
    ./generate_llms_txt --verbose

# Build the llms.txt generator executable
build-llms-generator:
    @echo "Building llms.txt generator executable..."
    cd scripts/llms_generator && dart pub get
    cd scripts/llms_generator && dart compile exe bin/generate_llms_txt.dart -o ../../generate_llms_txt
    @echo "✅ Executable created: generate_llms_txt"

# Setup llms.txt generator and generate files
setup-llms: build-llms-generator generate-llms
    @echo "✅ llms.txt setup complete!"

# Show package info
info:
    @echo "Flutter App Shell Package Information:"
    @echo "======================================="
    cd packages/flutter_app_shell && flutter --version
    @echo ""
    @echo "Package Dependencies:"
    cd packages/flutter_app_shell && flutter pub deps --no-dev
    @echo ""
    @echo "Example Dependencies:"
    cd example && flutter pub deps --no-dev

# =====================================
# Cloudflare Workers Integration
# =====================================

# Cloudflare worker paths
WORKER_DART_DIR := "workers/dart-api-worker"
WORKER_TS_DIR   := "workers/ts-auth-shim"

# Setup Cloudflare workers (login, install deps)
setup-cloudflare:
    cd {{WORKER_TS_DIR}} && npm i || true
    @echo "Run 'wrangler login' if you haven't authenticated with Cloudflare yet"
    @echo "Run 'just secrets-cloudflare' to set up worker secrets"

# Set all required secrets for Cloudflare workers
secrets-cloudflare:
    @echo "Setting up TypeScript auth shim secrets..."
    cd {{WORKER_TS_DIR}} && wrangler secret put SESSION_JWT_SECRET
    cd {{WORKER_TS_DIR}} && wrangler secret put INSTANT_APP_ID
    @echo "Setting up Dart API worker secrets..."
    cd {{WORKER_DART_DIR}} && wrangler secret put SESSION_JWT_SECRET
    cd {{WORKER_DART_DIR}} && wrangler secret put R2_ACCOUNT_ID
    cd {{WORKER_DART_DIR}} && wrangler secret put R2_ACCESS_KEY_ID
    cd {{WORKER_DART_DIR}} && wrangler secret put R2_SECRET_ACCESS_KEY
    cd {{WORKER_DART_DIR}} && wrangler secret put R2_BUCKET
    cd {{WORKER_DART_DIR}} && wrangler secret put CF_API_TOKEN

# Set AI Gateway secrets for enhanced AI features
secrets-ai-gateway:
    @echo "Setting up AI Gateway configuration..."
    cd {{WORKER_DART_DIR}} && wrangler secret put AI_GATEWAY_ID
    cd {{WORKER_DART_DIR}} && wrangler secret put CF_ACCOUNT_ID
    @echo "Setting up AI provider API keys (optional)..."
    @echo "Note: You can skip providers you don't want to use"
    cd {{WORKER_DART_DIR}} && wrangler secret put OPENAI_API_KEY --optional
    cd {{WORKER_DART_DIR}} && wrangler secret put ANTHROPIC_API_KEY --optional
    cd {{WORKER_DART_DIR}} && wrangler secret put GOOGLE_AI_API_KEY --optional
    @echo "✅ AI Gateway secrets configured!"

# Set all secrets (basic + AI Gateway)
secrets-cloudflare-all: secrets-cloudflare secrets-ai-gateway
    @echo "✅ All Cloudflare secrets configured!"

# Build Dart worker to JavaScript
build-dart-worker:
    cd {{WORKER_DART_DIR}} && dart compile js -O4 -o build/worker.js lib/main.dart

# Run Dart worker in development mode
dev-dart-worker: build-dart-worker
    cd {{WORKER_DART_DIR}} && wrangler dev

# Deploy Dart worker to production
deploy-dart-worker: build-dart-worker
    cd {{WORKER_DART_DIR}} && wrangler deploy

# Run TypeScript auth shim in development mode
dev-ts-shim:
    cd {{WORKER_TS_DIR}} && wrangler dev

# Deploy TypeScript auth shim to production
deploy-ts-shim:
    cd {{WORKER_TS_DIR}} && wrangler deploy

# Deploy both workers
deploy-cloudflare: deploy-ts-shim deploy-dart-worker
    @echo "✅ Both Cloudflare workers deployed successfully!"

# Create an R2 bucket
r2-create BUCKET:
    wrangler r2 bucket create {{BUCKET}}
    @echo "✅ R2 bucket '{{BUCKET}}' created successfully!"

# Tail logs for Dart worker
tail-dart-worker:
    cd {{WORKER_DART_DIR}} && wrangler tail

# Tail logs for TypeScript auth shim
tail-ts-shim:
    cd {{WORKER_TS_DIR}} && wrangler tail

# Show Cloudflare worker help
help-cloudflare:
    @echo "Cloudflare Workers Commands:"
    @echo "============================"
    @echo "  setup-cloudflare           # Install dependencies, guide for auth"
    @echo "  secrets-cloudflare         # Set basic worker secrets"
    @echo "  secrets-ai-gateway         # Set AI Gateway secrets"
    @echo "  secrets-cloudflare-all     # Set all secrets (basic + AI Gateway)"
    @echo "  dev-dart-worker           # Build + run Dart worker locally"
    @echo "  dev-ts-shim               # Run TypeScript auth shim locally"
    @echo "  deploy-dart-worker        # Deploy Dart worker to production"
    @echo "  deploy-ts-shim            # Deploy TypeScript auth shim"
    @echo "  deploy-cloudflare         # Deploy both workers"
    @echo "  r2-create BUCKET=name     # Create R2 bucket"
    @echo "  tail-dart-worker          # Tail Dart worker logs"
    @echo "  tail-ts-shim              # Tail auth shim logs"
    @echo ""
    @echo "AI Gateway Setup:"
    @echo "  1. Create AI Gateway at https://dash.cloudflare.com/ai-gateway"
    @echo "  2. Run 'just secrets-ai-gateway' to configure"
    @echo "  3. Update .env with AI_GATEWAY_ID and CF_ACCOUNT_ID"