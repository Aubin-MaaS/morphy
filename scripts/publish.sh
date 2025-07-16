#!/bin/bash
set -e

# Color codes for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

readonly SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
readonly PROJECT_DIR="$(dirname $SCRIPT_PATH)"

# The order of packages for publishing (dependencies first)
PACKAGES=(
    "zikzak_morphy_annotation"
    "zikzak_morphy"
)

# Function to check if a package version is already published on pub.dev
check_package_on_pubdev() {
    local package_name=$1
    local version=$2

    echo -e "${BLUE}Checking if $package_name version $version is available on pub.dev...${NC}"

    # Use curl to query the pub.dev API
    local response=$(curl -s "https://pub.dev/api/packages/$package_name")
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://pub.dev/api/packages/$package_name")

    # Check if the package exists
    if [ "$http_code" != "200" ]; then
        echo -e "${YELLOW}Package $package_name not found on pub.dev. Will be published for the first time.${NC}"
        return 1
    fi

    # Check if the version exists in the package versions
    if echo "$response" | grep -q "\"version\":\"$version\""; then
        echo -e "${GREEN}Version $version of $package_name is already published on pub.dev!${NC}"
        return 0
    else
        echo -e "${YELLOW}Version $version of $package_name is not yet published. Ready to publish.${NC}"
        return 1
    fi
}

# Function to test if a package version can actually be resolved by pub get
test_package_resolution() {
    local package_name=$1
    local version=$2

    echo -e "${BLUE}Testing if $package_name version $version can be resolved by pub get...${NC}"

    # Create a temporary directory for testing
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # Create a minimal pubspec.yaml to test dependency resolution
    cat > pubspec.yaml << EOF
name: test_resolution
description: Temporary project to test dependency resolution
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  $package_name: ^$version
EOF

    # Try to resolve dependencies
    if dart pub get > /dev/null 2>&1; then
        echo -e "${GREEN}Package $package_name version $version can be resolved successfully!${NC}"
        cd "$PROJECT_DIR"
        rm -rf "$temp_dir"
        return 0
    else
        echo -e "${YELLOW}Package $package_name version $version cannot be resolved yet (pub.dev propagation delay)${NC}"
        cd "$PROJECT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to check if all dependencies of a package are available on pub.dev
check_dependencies() {
    local package_dir="$1"
    local max_retries=30
    local retry_interval=30

    # Extract package version from pubspec.yaml
    local version=$(grep "^version:" "$PROJECT_DIR/$package_dir/pubspec.yaml" | sed 's/version: //' | tr -d '[:space:]')

    # Only zikzak_morphy has internal dependencies
    if [ "$package_dir" != "zikzak_morphy" ]; then
        echo -e "${BLUE}No internal dependencies to check for $package_dir.${NC}"
        return 0
    fi

    echo -e "${BLUE}Checking dependencies for $package_dir...${NC}"

    # Check if zikzak_morphy_annotation is available and can be resolved
    local retry_count=0
    while [ $retry_count -lt $max_retries ]; do
        if check_package_on_pubdev "zikzak_morphy_annotation" "$version" && test_package_resolution "zikzak_morphy_annotation" "$version"; then
            echo -e "${GREEN}Dependency zikzak_morphy_annotation version $version is fully available and resolvable!${NC}"
            break
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                echo -e "${YELLOW}Dependency zikzak_morphy_annotation not fully available yet (API published but not resolvable). Waiting ${retry_interval}s before retry ($retry_count/$max_retries)...${NC}"
                sleep $retry_interval
            else
                echo -e "${RED}Dependency zikzak_morphy_annotation version $version is required but not resolvable after $max_retries retries.${NC}"
                echo -e "${RED}There may be a pub.dev propagation delay. Try again later.${NC}"
                return 1
            fi
        fi
    done

    echo -e "${GREEN}All dependencies for $package_dir are available on pub.dev!${NC}"
    return 0
}

# Function to publish a package
publish_package() {
    local package_dir="$1"

    echo -e "${BLUE}======================================${NC}"
    echo -e "${YELLOW}Publishing package: ${GREEN}$package_dir${NC}"
    echo -e "${BLUE}======================================${NC}"

    # Extract package version
    local version=$(grep "^version:" "$PROJECT_DIR/$package_dir/pubspec.yaml" | sed 's/version: //' | tr -d '[:space:]')

    # Check if package is already published
    if check_package_on_pubdev "$package_dir" "$version"; then
        echo -e "${GREEN}Skipping $package_dir version $version (already published)${NC}"
        return 0
    fi

    # Check if all dependencies are available on pub.dev
    if ! check_dependencies "$package_dir"; then
        echo -e "${RED}Cannot publish $package_dir yet due to missing dependencies.${NC}"
        return 1
    fi

    # Navigate to the package directory
    cd "$PROJECT_DIR/$package_dir"

    # Format the Dart code
    echo -e "${BLUE}Formatting Dart code...${NC}"
    if [ -d "lib" ]; then
        dart format lib/
    fi

    # Analyze the package
    echo -e "${BLUE}Analyzing package...${NC}"
    flutter analyze

    # Publish with dry-run first
    echo -e "${BLUE}Running dry-run...${NC}"
    flutter pub publish --dry-run

    echo -e "${BLUE}Publishing to pub.dev...${NC}"
    flutter pub publish -f
    echo -e "${GREEN}Package $package_dir published to pub.dev successfully!${NC}"

    return 0
}

# Main script execution
echo -e "${BLUE}Starting publication process in the correct order${NC}"
echo -e "${YELLOW}Packages will be published in this order:${NC}"
for package in "${PACKAGES[@]}"; do
    echo -e "- $package"
done
echo

# Confirm publication of all packages
echo -e "${YELLOW}Do you want to proceed with publishing all packages? (y/n)${NC}"
read -r proceed
if [ "$proceed" != "y" ] && [ "$proceed" != "Y" ]; then
    echo -e "${RED}Publication process aborted.${NC}"
    exit 0
fi

# Publish each package in the defined order
for package in "${PACKAGES[@]}"; do
    if ! publish_package "$package"; then
        echo -e "${RED}Publication process stopped at $package.${NC}"
        exit 1
    fi
done
tag=$(grep "^version:" "$PROJECT_DIR/zikzak_morphy/pubspec.yaml" | sed 's/version: //' | tr -d '[:space:]')

echo -e "${GREEN}All packages published successfully!${NC}"
echo -e ""
echo -e "${BLUE}Options for next steps:${NC}"
echo -e "1. ${YELLOW}To revert to development setup (keep branch):${NC}"
echo -e "   ./scripts/restore_dev_mode.sh"
echo -e ""
echo -e "2. ${YELLOW}To merge changes to master and create tag:${NC}"
echo -e "   git checkout master && git merge $(git branch --show-current) && git tag v$tag && git push origin master --tags"
echo -e ""
echo -e "${GREEN}🔥🔥🔥 MORPHY PACKAGES PUBLISHED! CODING BEAST MODE ACTIVATED! 🔥🔥🔥${NC}"
