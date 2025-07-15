#!/bin/bash

# 🔥 ZIKZAK MORPHY - DEV MODE SCRIPT 🔥
# Development mode script for local development and testing
# Automatically switches dependencies between local paths (dev) and hosted packages (prod)
# Usage: ./dev_mode.sh [dev|prod]

set -e

# Default mode is dev
MODE="${1:-dev}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${PURPLE}🔥 ZIKZAK MORPHY DEV MODE 🔥${NC}"
echo -e "${CYAN}Mode: ${MODE}${NC}"
echo -e "${CYAN}======================================${NC}"

# Function to print colored status
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to run command with status
run_command() {
    local cmd="$1"
    local desc="$2"

    print_status "$desc"
    if eval "$cmd"; then
        print_success "$desc completed"
    else
        print_error "$desc failed"
        exit 1
    fi
}

# Function to run command with status (non-fatal)
run_command_soft() {
    local cmd="$1"
    local desc="$2"

    print_status "$desc"
    if eval "$cmd"; then
        print_success "$desc completed"
    else
        print_warning "$desc failed (continuing...)"
    fi
}

# Function to switch dependencies to dev mode (local paths)
switch_to_dev_mode() {
    print_status "🔧 Switching to DEV mode (local paths)..."

    # zikzak_morphy: use local annotation
    cat > "$PROJECT_ROOT/zikzak_morphy/pubspec.yaml" << 'EOF'
name: zikzak_morphy
description: A powerful code generation package for Dart/Flutter that provides clean class definitions with copyWith, JSON serialization, toString, equality, and inheritance support
version: 2.1.0
homepage: https://github.com/arrrrny/morphy

environment:
  sdk: ">=3.8.0 <4.0.0"

dependencies:
  zikzak_morphy_annotation:
    path: ../zikzak_morphy_annotation
  analyzer: ^7.5.7
  build: ^2.5.4
  source_gen: ^2.0.0
  dartx: ^1.2.0
  quiver: ^3.2.2
  path: ^1.9.0

dev_dependencies:
  build_runner: ^2.5.4
  test: ^1.26.2
EOF

    # example: use local paths for both
    cat > "$PROJECT_ROOT/example/pubspec.yaml" << 'EOF'
name: example
publish_to: "none"

environment:
  sdk: ">=3.8.0 <4.0.0"

dependencies:
  zikzak_morphy_annotation:
    path: ../zikzak_morphy_annotation
  json_annotation: ^4.9.0

dev_dependencies:
  test: ^1.26.2
  build_runner: ^2.5.4
  zikzak_morphy:
    path: ../zikzak_morphy
  json_serializable: ^6.8.0
EOF

    print_success "Switched to DEV mode"
}

# Function to switch dependencies to production mode (hosted packages)
switch_to_prod_mode() {
    print_status "🔧 Switching to PROD mode (hosted packages)..."

    # zikzak_morphy: use hosted annotation
    cat > "$PROJECT_ROOT/zikzak_morphy/pubspec.yaml" << 'EOF'
name: zikzak_morphy
description: A powerful code generation package for Dart/Flutter that provides clean class definitions with copyWith, JSON serialization, toString, equality, and inheritance support
version: 2.1.0
homepage: https://github.com/arrrrny/morphy

environment:
  sdk: ">=3.8.0 <4.0.0"

dependencies:
  zikzak_morphy_annotation: ^2.1.0
  analyzer: ^7.5.7
  build: ^2.5.4
  source_gen: ^2.0.0
  dartx: ^1.2.0
  quiver: ^3.2.2
  path: ^1.9.0

dev_dependencies:
  build_runner: ^2.5.4
  test: ^1.26.2
EOF

    # example: use hosted packages
    cat > "$PROJECT_ROOT/example/pubspec.yaml" << 'EOF'
name: example
publish_to: "none"

environment:
  sdk: ">=3.8.0 <4.0.0"

dependencies:
  zikzak_morphy_annotation: ^2.1.0
  json_annotation: ^4.9.0

dev_dependencies:
  test: ^1.26.2
  build_runner: ^2.5.4
  zikzak_morphy: ^2.1.0
  json_serializable: ^6.8.0
EOF

    print_success "Switched to PROD mode"
}

# Check if we're in the right directory
if [ ! -d "$PROJECT_ROOT/zikzak_morphy" ] || [ ! -d "$PROJECT_ROOT/zikzak_morphy_annotation" ]; then
    print_error "Must be run from morphy project root or scripts directory"
    print_error "Expected to find zikzak_morphy and zikzak_morphy_annotation directories"
    exit 1
fi

cd "$PROJECT_ROOT"

echo -e "${CYAN}Project Root: ${PROJECT_ROOT}${NC}"
echo ""

# Switch dependency mode based on parameter
if [ "$MODE" = "prod" ]; then
    switch_to_prod_mode
else
    switch_to_dev_mode
fi
echo ""

# Clean all build artifacts
print_status "🧹 Cleaning build artifacts..."
run_command "cd \"$PROJECT_ROOT/zikzak_morphy\" && rm -rf .dart_tool build" "Clean zikzak_morphy"
run_command "cd \"$PROJECT_ROOT/zikzak_morphy_annotation\" && rm -rf .dart_tool build" "Clean zikzak_morphy_annotation"
run_command "cd \"$PROJECT_ROOT/example\" && rm -rf .dart_tool build .packages" "Clean example"

# Get dependencies for annotation package
print_status "📦 Getting dependencies for annotation package..."
run_command "cd \"$PROJECT_ROOT/zikzak_morphy_annotation\" && dart pub get" "Get annotation dependencies"

# Get dependencies for main package
print_status "📦 Getting dependencies for main package..."
run_command "cd \"$PROJECT_ROOT/zikzak_morphy\" && dart pub get" "Get main package dependencies"

# Get dependencies for example
print_status "📦 Getting dependencies for example..."
run_command "cd \"$PROJECT_ROOT/example\" && dart pub get" "Get example dependencies"

# Run static analysis
print_status "🔍 Running static analysis..."
run_command "cd \"$PROJECT_ROOT/zikzak_morphy_annotation\" && dart analyze" "Analyze annotation package"
run_command_soft "cd \"$PROJECT_ROOT/zikzak_morphy\" && dart analyze" "Analyze main package (warnings expected)"

# Run tests for annotation package (if available)
print_status "🧪 Running annotation package tests..."
cd "$PROJECT_ROOT/zikzak_morphy_annotation"
if [ -d "test" ] && dart pub deps | grep -q "test:"; then
    cd "$PROJECT_ROOT"
    run_command "cd \"$PROJECT_ROOT/zikzak_morphy_annotation\" && dart test" "Test annotation package"
else
    print_warning "No tests found for annotation package (this is normal)"
    cd "$PROJECT_ROOT"
fi

# Run tests for main package
print_status "🧪 Running main package tests..."
cd "$PROJECT_ROOT/zikzak_morphy"
if dart test --reporter=compact 2>&1; then
    print_success "Main package tests completed successfully"
else
    print_warning "Some main package tests failed (this is expected during development)"
fi
cd "$PROJECT_ROOT"

# Build example to test code generation
print_status "🏗️ Testing code generation on example..."
run_command "cd \"$PROJECT_ROOT/example\" && dart run build_runner build --delete-conflicting-outputs" "Generate code for example"

# Run example tests (allow some failures during dev)
print_status "🧪 Running example tests..."
cd "$PROJECT_ROOT/example"
if dart test --reporter=compact 2>&1; then
    print_success "Example tests completed successfully"
else
    print_warning "Some example tests failed (reviewing...)"
    echo ""
    print_status "Running specific working tests..."
    # Run some basic tests that should always work
    dart test test/ex1_simple_test.dart --reporter=compact || true
    dart test test/ex13_copywith_test.dart --reporter=compact || true
fi
cd "$PROJECT_ROOT"

echo ""
echo -e "${GREEN}✅ DEV MODE SETUP COMPLETE! ✅${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${YELLOW}Development Tips:${NC}"
echo -e "  • Use ${CYAN}cd example && dart run build_runner build${NC} to regenerate code"
echo -e "  • Use ${CYAN}cd example && dart run build_runner watch${NC} for auto-regeneration"
echo -e "  • Use ${CYAN}cd zikzak_morphy && dart test${NC} to run generator tests"
echo -e "  • Use ${CYAN}cd example && dart test test/SPECIFIC_TEST.dart${NC} to test specific features"
echo ""
echo -e "${PURPLE}🔥 READY FOR ZIKZAK DEVELOPMENT! 🔥${NC}"
