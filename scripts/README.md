# 🔥 ZikZak Morphy Scripts 🔥

This folder contains automation scripts for development and release management of the ZikZak Morphy project.

## Scripts

### `dev_mode.sh` - Development Environment Setup

Sets up and validates the development environment for local development.

**What it does:**
- Cleans all build artifacts
- Gets dependencies for all packages
- Runs static analysis
- Runs tests (with tolerance for expected failures during development)
- Tests code generation on example project
- Provides development tips

**Usage:**
```bash
# From project root or scripts directory
./scripts/dev_mode.sh
```

**Perfect for:**
- Setting up a new development environment
- Validating changes before committing
- Quick health check of the entire project

### `release.sh` - Automated Release Process

Fully automated release script that handles versioning, testing, and publishing.

**What it does:**
- Prompts for new version number with validation
- Updates both package versions (annotation + morphy)
- Updates dependency references for publishing
- Updates changelogs with release notes
- Runs comprehensive tests
- Publishes to pub.dev with confirmation prompts
- Creates git commit and tag
- Provides post-release instructions

**Usage:**
```bash
# From project root or scripts directory
./scripts/release.sh
```

**Interactive prompts:**
1. Enter new version number (e.g., `2.1.0`, `3.0.0-beta.1`)
2. Confirm release plan
3. Confirm annotation package publication
4. Confirm main package publication

**Version format:** `X.Y.Z` or `X.Y.Z-suffix` (semver compliant)

### `publish_help.sh` - Publishing Setup Guide

Interactive help script for pub.dev publishing setup and troubleshooting.

**What it displays:**
- Pub.dev authentication setup instructions
- Publishing requirements checklist
- Manual publishing commands (if needed)
- Troubleshooting common issues
- Critical publishing order (annotations first, morphy second)
- Testing commands for published packages

**Usage:**
```bash
# Display publishing help and setup guide
./scripts/publish_help.sh
```

**Perfect for:**
- First-time pub.dev setup
- Troubleshooting publishing issues
- Understanding the publishing workflow
- Manual publishing when automation fails

## Development Workflow

### Daily Development
```bash
# 1. Set up/validate environment
./scripts/dev_mode.sh

# 2. Make your changes
# ... code changes ...

# 3. Test specific functionality
cd example && dart run build_runner build
cd example && dart test test/specific_test.dart

# 4. Run dev mode again to validate
./scripts/dev_mode.sh
```

### Release Process
```bash
# 1. Ensure everything is working
./scripts/dev_mode.sh

# 2. Commit all changes
git add . && git commit -m "Your final changes"

# 3. Run release script
./scripts/release.sh

# 4. Follow post-release steps
git push origin main
git push origin vX.Y.Z
```

## Script Features

### 🎨 Colored Output
- **Blue**: Info messages
- **Green**: Success messages  
- **Yellow**: Warnings
- **Red**: Errors
- **Purple**: Headers and branding
- **Cyan**: Highlights and values

### 🛡️ Safety Features
- Input validation (version format, directory checks)
- Dry-run before publishing
- Confirmation prompts for destructive actions
- Automatic rollback on failures
- Clear error messages with context

### 🔧 Cross-Platform Support
- Works on macOS and Linux
- Handles different `sed` implementations
- Uses portable shell scripting practices

## Requirements

- **Bash shell** (standard on macOS/Linux)
- **Dart SDK** (3.8.0 or higher)
- **Git** (for release script)
- **pub.dev account** (for publishing - create at https://pub.dev)
- **pub.dev authentication token** (configured via `dart pub token add`)

## Troubleshooting

### Permission Denied
```bash
chmod +x scripts/*.sh
```

### Version Format Error
Use semantic versioning: `X.Y.Z` or `X.Y.Z-suffix`
- ✅ Good: `2.1.0`, `3.0.0-beta.1`, `1.2.3-alpha.2`
- ❌ Bad: `v2.1.0`, `2.1`, `2.1.0.1`

### Pub.dev Authentication
First-time setup:
```bash
# Check current tokens
dart pub token list

# Add pub.dev token (follow browser instructions)
dart pub token add https://pub.dev

# Or use the help script
./scripts/publish_help.sh
```

### Git Not Found
Ensure git is installed and in your PATH.

## Publishing Workflow

### Automated Publishing (Recommended)
```bash
# Complete automated release
./scripts/release.sh
```

### Manual Publishing (Advanced)
```bash
# 1. Check setup
./scripts/publish_help.sh

# 2. Publish annotation package FIRST
cd zikzak_morphy_annotation
dart pub publish --dry-run  # Test first
dart pub publish            # Publish

# 3. Wait 1-2 minutes for pub.dev processing

# 4. Publish main package SECOND  
cd ../zikzak_morphy
dart pub get                # Get latest annotation
dart pub publish --dry-run  # Test first
dart pub publish            # Publish
```

**Critical:** Always publish in this order:
1. `zikzak_morphy_annotation` (has no dependencies)
2. `zikzak_morphy` (depends on annotation package)

## Contributing

When adding new scripts:
1. Follow the existing color scheme and output format
2. Add proper error handling with descriptive messages
3. Include confirmation prompts for destructive actions
4. Update this README with documentation
5. Test on both macOS and Linux if possible
6. Make scripts executable with `chmod +x`

---

**🔥 ZIKZAK MANIFESTO: PROCESSES OVER PRODUCTS 🔥**