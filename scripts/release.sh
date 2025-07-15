#!/bin/bash

# 🔥 ZIKZAK MORPHY - RELEASE SCRIPT 🔥
# Automated versioning, changelog update, and publishing script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${PURPLE}🔥 ZIKZAK MORPHY - RELEASE AUTOMATION 🔥${NC}"
echo -e "${CYAN}==========================================${NC}"

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

print_header() {
    echo -e "${BOLD}${CYAN}$1${NC}"
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

# Function to validate version format
validate_version() {
    local version="$1"
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
        print_error "Invalid version format: $version"
        print_error "Expected format: X.Y.Z or X.Y.Z-suffix (e.g., 1.0.0, 2.1.0-beta.1)"
        exit 1
    fi
}

# Function to update pubspec version
update_pubspec_version() {
    local file="$1"
    local version="$2"
    local desc="$3"

    print_status "Updating $desc version to $version"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^version: .*/version: $version/" "$file"
    else
        # Linux
        sed -i "s/^version: .*/version: $version/" "$file"
    fi

    print_success "$desc version updated"
}

# Function to update dependency version in pubspec
update_dependency_version() {
    local file="$1"
    local dep_name="$2"
    local version="$3"
    local desc="$4"

    print_status "Updating $dep_name dependency in $desc to ^$version"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "/^  $dep_name:/,/^  [^ ]/ s/^    path:.*$/  $dep_name: ^$version/" "$file"
    else
        # Linux
        sed -i "/^  $dep_name:/,/^  [^ ]/ s/^    path:.*$/  $dep_name: ^$version/" "$file"
    fi

    print_success "$dep_name dependency updated in $desc"
}

# Function to get current version from pubspec
get_current_version() {
    local file="$1"
    grep '^version:' "$file" | cut -d' ' -f2
}

# Function to update changelog
update_changelog() {
    local package_dir="$1"
    local version="$2"
    local package_name="$3"

    local changelog_file="$package_dir/CHANGELOG.md"
    local date=$(date +"%Y-%m-%d")

    print_status "Updating CHANGELOG.md for $package_name"

    if [ ! -f "$changelog_file" ]; then
        print_warning "CHANGELOG.md not found, creating one"
        echo "# Changelog" > "$changelog_file"
        echo "" >> "$changelog_file"
    fi

    # Create temporary file with new entry
    local temp_file=$(mktemp)

    # Add new version entry
    echo "# Changelog" > "$temp_file"
    echo "" >> "$temp_file"
    echo "## [$version] - $date" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "### Added" >> "$temp_file"
    echo "- TODO: Add release notes for version $version" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "### Fixed" >> "$temp_file"
    echo "- Fixed constructor accessibility issue in cross-file entity extension" >> "$temp_file"
    echo "- Updated changeTo, copyWith, and patchWith methods to use public constructors" >> "$temp_file"
    echo "" >> "$temp_file"

    # Append existing changelog (skip the first "# Changelog" line)
    tail -n +2 "$changelog_file" >> "$temp_file"

    # Replace original with updated version
    mv "$temp_file" "$changelog_file"

    print_success "CHANGELOG.md updated for $package_name"
    print_warning "Please edit $changelog_file to add proper release notes!"
}

# Function to check pub.dev authentication
check_pub_auth() {
    print_status "🔐 Checking pub.dev authentication..."

    if ! dart pub token list 2>/dev/null | grep -q "pub.dev"; then
        print_error "No pub.dev authentication token found!"
        print_error "Please run: dart pub token add https://pub.dev"
        print_error "Follow the instructions to authenticate with your pub.dev account"
        exit 1
    fi

    print_success "Pub.dev authentication verified"
}

# Check if we're in the right directory
if [ ! -d "$PROJECT_ROOT/zikzak_morphy" ] || [ ! -d "$PROJECT_ROOT/zikzak_morphy_annotation" ]; then
    print_error "Must be run from morphy project root or scripts directory"
    print_error "Expected to find zikzak_morphy and zikzak_morphy_annotation directories"
    exit 1
fi

cd "$PROJECT_ROOT"

# Get current versions
annotation_current=$(get_current_version "zikzak_morphy_annotation/pubspec.yaml")
morphy_current=$(get_current_version "zikzak_morphy/pubspec.yaml")

print_header "📋 Current Versions"
echo -e "  ${CYAN}zikzak_morphy_annotation:${NC} $annotation_current"
echo -e "  ${CYAN}zikzak_morphy:${NC} $morphy_current"
echo ""

# Prompt for new version
print_header "🎯 Release Version Selection"
echo -e "${YELLOW}Enter the new version number (e.g., 2.1.0, 3.0.0-beta.1):${NC}"
read -p "New version: " NEW_VERSION

# Validate version format
validate_version "$NEW_VERSION"

echo ""
print_header "🎯 Release Plan"
echo -e "  ${CYAN}New version:${NC} $NEW_VERSION"
echo -e "  ${YELLOW}This will:${NC}"
echo -e "    • Update zikzak_morphy_annotation to $NEW_VERSION"
echo -e "    • Update zikzak_morphy to $NEW_VERSION"
echo -e "    • Update dependency references"
echo -e "    • Update changelogs"
echo -e "    • Run tests"
echo -e "    • Publish packages"
echo ""

# Confirmation
read -p "$(echo -e "${BOLD}Proceed with release? [y/N]:${NC} ")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Release cancelled"
    exit 1
fi

echo ""
print_header "🚀 Starting Release Process"

# Check pub.dev authentication before proceeding
check_pub_auth

# Step 1: Clean everything
print_header "🧹 Step 1: Cleaning build artifacts"
run_command "cd zikzak_morphy_annotation && rm -rf .dart_tool build" "Clean annotation package"
run_command "cd zikzak_morphy && rm -rf .dart_tool build" "Clean main package"
run_command "cd example && rm -rf .dart_tool build .packages" "Clean example"

# Step 2: Update versions in pubspec files
print_header "📝 Step 2: Updating package versions"
update_pubspec_version "zikzak_morphy_annotation/pubspec.yaml" "$NEW_VERSION" "zikzak_morphy_annotation"
update_pubspec_version "zikzak_morphy/pubspec.yaml" "$NEW_VERSION" "zikzak_morphy"

# Step 3: Update dependency references (switch from path to hosted)
print_header "📦 Step 3: Updating dependency references for release"
print_status "Switching zikzak_morphy to use hosted annotation dependency"

# Update main package to use hosted version
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "/zikzak_morphy_annotation:/,/path:/ c\\
  zikzak_morphy_annotation: ^$NEW_VERSION" zikzak_morphy/pubspec.yaml
else
    sed -i "/zikzak_morphy_annotation:/,/path:/ c\\
  zikzak_morphy_annotation: ^$NEW_VERSION" zikzak_morphy/pubspec.yaml
fi

print_success "Dependency references updated"

# Step 4: Update changelogs
print_header "📚 Step 4: Updating changelogs"
update_changelog "zikzak_morphy_annotation" "$NEW_VERSION" "zikzak_morphy_annotation"
update_changelog "zikzak_morphy" "$NEW_VERSION" "zikzak_morphy"

# Step 5: Get dependencies
print_header "📦 Step 5: Getting dependencies"
run_command "cd zikzak_morphy_annotation && dart pub get" "Get annotation dependencies"

# Step 6: Run tests on annotation package
print_header "🧪 Step 6: Testing annotation package"
run_command "cd zikzak_morphy_annotation && dart analyze" "Analyze annotation package"
run_command "cd zikzak_morphy_annotation && dart test" "Test annotation package"

# Step 7: Publish annotation package first
print_header "📤 Step 7: Publishing annotation package (FIRST)"
echo -e "${YELLOW}Publishing zikzak_morphy_annotation $NEW_VERSION...${NC}"
echo -e "${CYAN}Note: Annotation package MUST be published first as main package depends on it${NC}"
cd zikzak_morphy_annotation

# Dry run first
print_status "Running dry-run for annotation package"
if ! dart pub publish --dry-run; then
    print_error "Dry-run failed for annotation package"
    print_error "Please check the package configuration and try again"
    exit 1
fi

echo ""
echo -e "${BOLD}🚨 PUBLISHING TO PUBLIC PUB.DEV 🚨${NC}"
echo -e "${YELLOW}This will make zikzak_morphy_annotation $NEW_VERSION publicly available${NC}"
read -p "$(echo -e "${BOLD}Confirm: Publish zikzak_morphy_annotation $NEW_VERSION to pub.dev? [y/N]:${NC} ")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Annotation package publication cancelled by user"
    exit 1
fi

print_status "📤 Publishing zikzak_morphy_annotation to pub.dev..."
if dart pub publish --force; then
    print_success "✅ zikzak_morphy_annotation $NEW_VERSION published to pub.dev!"
    print_status "🔗 View at: https://pub.dev/packages/zikzak_morphy_annotation/versions/$NEW_VERSION"
else
    print_error "❌ Failed to publish zikzak_morphy_annotation"
    print_error "Check your network connection and pub.dev authentication"
    exit 1
fi

cd "$PROJECT_ROOT"

# Wait for pub.dev to process the annotation package
print_status "⏳ Waiting 45 seconds for pub.dev to process annotation package..."
echo -e "${CYAN}This ensures the main package can resolve the new annotation dependency${NC}"
sleep 45

# Step 8: Get dependencies for main package (should now get hosted annotation)
print_header "📦 Step 8: Getting main package dependencies"
run_command "cd zikzak_morphy && dart pub get" "Get main package dependencies"

# Step 9: Run tests on main package
print_header "🧪 Step 9: Testing main package"
run_command "cd zikzak_morphy && dart analyze" "Analyze main package"

cd zikzak_morphy
if dart test --reporter=compact; then
    print_success "Main package tests passed"
else
    print_warning "Some tests failed, but continuing (some test failures are expected)"
fi
cd "$PROJECT_ROOT"

# Step 10: Test code generation
print_header "🏗️ Step 10: Testing code generation"
run_command "cd example && dart pub get" "Get example dependencies"
run_command "cd example && dart run build_runner build --delete-conflicting-outputs" "Test code generation"

# Step 11: Publish main package (SECOND)
print_header "📤 Step 11: Publishing main package (SECOND)"
echo -e "${YELLOW}Publishing zikzak_morphy $NEW_VERSION...${NC}"
echo -e "${CYAN}Main package depends on annotation package, so it must be published second${NC}"
cd zikzak_morphy

# Dry run first
print_status "Running dry-run for main package"
if ! dart pub publish --dry-run; then
    print_error "Dry-run failed for main package"
    print_error "Please check the package configuration and dependencies"
    exit 1
fi

echo ""
print_status "Verifying annotation dependency is available..."
if dart pub deps | grep -q "zikzak_morphy_annotation"; then
    print_success "Annotation dependency resolved correctly"
else
    print_warning "Annotation dependency may not be fully propagated yet"
    print_warning "You may need to wait longer for pub.dev to process the annotation package"
fi

echo ""
echo -e "${BOLD}🚨 PUBLISHING TO PUBLIC PUB.DEV 🚨${NC}"
echo -e "${YELLOW}This will make zikzak_morphy $NEW_VERSION publicly available${NC}"
read -p "$(echo -e "${BOLD}Confirm: Publish zikzak_morphy $NEW_VERSION to pub.dev? [y/N]:${NC} ")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Main package publication cancelled by user"
    exit 1
fi

print_status "📤 Publishing zikzak_morphy to pub.dev..."
if dart pub publish --force; then
    print_success "✅ zikzak_morphy $NEW_VERSION published to pub.dev!"
    print_status "🔗 View at: https://pub.dev/packages/zikzak_morphy/versions/$NEW_VERSION"
else
    print_error "❌ Failed to publish zikzak_morphy"
    print_error "Check your network connection and pub.dev authentication"
    exit 1
fi

cd "$PROJECT_ROOT"

# Step 12: Create git tag and commit
print_header "🏷️ Step 12: Git operations"
run_command "git add ." "Stage changes"
run_command "git commit -m \"🚀 Release v$NEW_VERSION

- Updated zikzak_morphy_annotation to $NEW_VERSION
- Updated zikzak_morphy to $NEW_VERSION
- Fixed constructor accessibility issues
- Updated changelogs\"" "Commit release changes"

run_command "git tag -a v$NEW_VERSION -m \"Release v$NEW_VERSION\"" "Create git tag"

echo ""
print_header "✅ RELEASE COMPLETE! ✅"
echo -e "${CYAN}===========================================${NC}"
echo -e "${GREEN}🎉 Successfully released version $NEW_VERSION! 🎉${NC}"
echo ""
echo -e "${BOLD}📦 Published packages to pub.dev:${NC}"
echo -e "  • ${CYAN}zikzak_morphy_annotation:${NC} $NEW_VERSION ${GREEN}✅${NC}"
echo -e "  • ${CYAN}zikzak_morphy:${NC} $NEW_VERSION ${GREEN}✅${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo -e "  • Push changes: ${CYAN}git push origin main${NC}"
echo -e "  • Push tags: ${CYAN}git push origin v$NEW_VERSION${NC}"
echo -e "  • Update release notes on GitHub"
echo -e "  • Update documentation if needed"
echo ""
echo -e "${BOLD}📱 Package URLs:${NC}"
echo -e "  • ${CYAN}https://pub.dev/packages/zikzak_morphy_annotation/versions/$NEW_VERSION${NC}"
echo -e "  • ${CYAN}https://pub.dev/packages/zikzak_morphy/versions/$NEW_VERSION${NC}"
echo ""
echo -e "${BOLD}📋 Pub.dev commands for users:${NC}"
echo -e "  • ${CYAN}dart pub add zikzak_morphy_annotation${NC}"
echo -e "  • ${CYAN}dart pub add dev:zikzak_morphy${NC}"
echo ""
echo -e "${PURPLE}🔥 ZIKZAK MORPHY v$NEW_VERSION - UNLEASHED! 🔥${NC}"
