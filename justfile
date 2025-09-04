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
# Release Management
# =====================================

# Show current version
version:
    @echo "Current version: $(grep '^version:' packages/flutter_app_shell/pubspec.yaml | cut -d' ' -f2)"
    @echo ""
    @echo "Recent tags:"
    @git tag --list --sort=-version:refname | head -10

# Bump patch version (e.g., 0.3.0 -> 0.3.1)
release-patch: _release-pre-check
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Bumping patch version..."
    current_version=$(grep '^version:' packages/flutter_app_shell/pubspec.yaml | cut -d' ' -f2)
    major=$(echo $current_version | cut -d. -f1)
    minor=$(echo $current_version | cut -d. -f2)
    patch=$(echo $current_version | cut -d. -f3)
    new_patch=$((patch + 1))
    new_version="$major.$minor.$new_patch"
    just _do-release $new_version

# Bump minor version (e.g., 0.3.0 -> 0.4.0)
release-minor: _release-pre-check
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Bumping minor version..."
    current_version=$(grep '^version:' packages/flutter_app_shell/pubspec.yaml | cut -d' ' -f2)
    major=$(echo $current_version | cut -d. -f1)
    minor=$(echo $current_version | cut -d. -f2)
    new_minor=$((minor + 1))
    new_version="$major.$new_minor.0"
    just _do-release $new_version

# Bump major version (e.g., 0.3.0 -> 1.0.0)
release-major: _release-pre-check
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Bumping major version..."
    current_version=$(grep '^version:' packages/flutter_app_shell/pubspec.yaml | cut -d' ' -f2)
    major=$(echo $current_version | cut -d. -f1)
    new_major=$((major + 1))
    new_version="$new_major.0.0"
    just _do-release $new_version

# Create a release with a custom version
release-custom VERSION: _release-pre-check
    @echo "Setting custom version: {{VERSION}}"
    @just _do-release {{VERSION}}

# Create a GitHub Release from an existing tag
github-release VERSION:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "📦 Creating GitHub Release for v{{VERSION}}..."
    
    # Check if tag exists
    if ! git tag -l | grep -q "^v{{VERSION}}$"; then
        echo "❌ Tag v{{VERSION}} does not exist!"
        echo "Run 'just release-minor' or 'just release-major' first"
        exit 1
    fi
    
    # Extract release notes from CHANGELOG
    RELEASE_NOTES=$(awk '/^## {{VERSION}}/ {flag=1; next} /^## [0-9]/ {flag=0} flag' packages/flutter_app_shell/CHANGELOG.md | sed '/^$/d')
    
    if [ -z "$RELEASE_NOTES" ]; then
        echo "⚠️  No release notes found in CHANGELOG for version {{VERSION}}"
        RELEASE_NOTES="Release v{{VERSION}}"
    fi
    
    # Create GitHub release
    gh release create v{{VERSION}} \
        --title "Flutter App Shell v{{VERSION}}" \
        --notes "$RELEASE_NOTES" \
        --verify-tag
    
    echo "✅ GitHub Release created successfully!"
    echo "View it at: https://github.com/yourusername/flutter_ps_app_shell/releases/tag/v{{VERSION}}"

# Publish a release (push + create GitHub release)
publish-release VERSION:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "🚀 Publishing release v{{VERSION}}..."
    
    # Push commits and tags
    git push origin main
    git push origin v{{VERSION}}
    
    # Create GitHub release
    just github-release {{VERSION}}

# Create GitHub releases for existing tags
create-missing-releases:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "🔍 Checking for tags without GitHub releases..."
    
    # Get all tags
    for tag in $(git tag -l | grep "^v[0-9]"); do
        version=${tag#v}
        
        # Check if release exists
        if gh release view "$tag" >/dev/null 2>&1; then
            echo "✅ Release exists for $tag"
        else
            echo "📦 Creating release for $tag..."
            just github-release $version
        fi
    done
    
    echo "✅ All releases created!"

# Private recipe: Check prerequisites before release
_release-pre-check:
    @echo "Checking release prerequisites..."
    @git diff --quiet || (echo "❌ Working directory has uncommitted changes!" && exit 1)
    @git diff --cached --quiet || (echo "❌ Index has staged changes!" && exit 1)
    @echo "✅ Working directory is clean"

# Private recipe: Execute the release
_do-release VERSION:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "📦 Creating release v{{VERSION}}"
    echo ""
    
    # Update version in pubspec.yaml
    sed -i.bak 's/^version: .*/version: {{VERSION}}/' packages/flutter_app_shell/pubspec.yaml && rm packages/flutter_app_shell/pubspec.yaml.bak
    echo "✅ Updated pubspec.yaml to version {{VERSION}}"
    
    # Check if CHANGELOG entry exists for this version
    if grep -q "## {{VERSION}}" packages/flutter_app_shell/CHANGELOG.md; then
        echo "✅ CHANGELOG.md already contains entry for v{{VERSION}}"
    else
        echo ""
        echo "📝 Adding CHANGELOG entry for v{{VERSION}}"
        
        # Add new version entry at the top of CHANGELOG
        DATE=$(date +%Y-%m-%d)
        TEMP_FILE=$(mktemp)
        
        # Write new entry
        echo "# Changelog" > "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        echo "## {{VERSION}} - $DATE" >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        echo "### Added" >> "$TEMP_FILE"
        echo "- " >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        echo "### Changed" >> "$TEMP_FILE"
        echo "- " >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        echo "### Fixed" >> "$TEMP_FILE"
        echo "- " >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        
        # Append existing content (skip the first "# Changelog" line)
        tail -n +2 packages/flutter_app_shell/CHANGELOG.md >> "$TEMP_FILE"
        
        # Replace the original file
        mv "$TEMP_FILE" packages/flutter_app_shell/CHANGELOG.md
        
        echo "✅ Added CHANGELOG template for v{{VERSION}}"
        echo ""
        echo "⚠️  Please edit packages/flutter_app_shell/CHANGELOG.md to add release notes"
        echo "   Then run: git add . && git commit -m 'chore: release v{{VERSION}}'"
        echo "   Finally: git tag -a v{{VERSION}} -m 'Release v{{VERSION}}'"
    fi
    
    # Commit changes
    git add packages/flutter_app_shell/pubspec.yaml packages/flutter_app_shell/CHANGELOG.md
    
    if git diff --cached --quiet; then
        echo "ℹ️  No changes to commit"
    else
        git commit -m "chore: release v{{VERSION}}"
        echo "✅ Committed release v{{VERSION}}"
    fi
    
    # Create tag
    if git tag -l | grep -q "^v{{VERSION}}$"; then
        echo "⚠️  Tag v{{VERSION}} already exists"
    else
        git tag -a "v{{VERSION}}" -m "Release v{{VERSION}}"
        echo "✅ Created tag v{{VERSION}}"
    fi
    
    echo ""
    echo "🎉 Release v{{VERSION}} prepared successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Push changes:  git push origin main && git push origin v{{VERSION}}"
    echo "  2. Create GitHub Release:  just github-release {{VERSION}}"
    echo ""
    echo "Or do both at once:  just publish-release {{VERSION}}"
    echo ""
    echo "Other projects can now depend on this version using:"
    echo "  flutter_app_shell:"
    echo "    git:"
    echo "      url: https://github.com/yourusername/flutter_ps_app_shell"
    echo "      ref: v{{VERSION}}"

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