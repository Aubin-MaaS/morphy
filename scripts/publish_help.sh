#!/bin/bash

# 🔥 ZIKZAK MORPHY - PUBLISHING HELP 🔥
# Helper script for pub.dev publishing setup and manual commands

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🔥 ZIKZAK MORPHY - PUBLISHING HELP 🔥${NC}"
echo -e "${CYAN}========================================${NC}"

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

print_header "📋 Pub.dev Publishing Requirements"
echo -e "${YELLOW}Before publishing, ensure you have:${NC}"
echo -e "  1. ${CYAN}Dart SDK${NC} (3.8.0 or higher)"
echo -e "  2. ${CYAN}Pub.dev account${NC} (create at https://pub.dev)"
echo -e "  3. ${CYAN}Authentication token${NC} configured"
echo -e "  4. ${CYAN}Git repository${NC} with clean working directory"
echo ""

print_header "🔐 Authentication Setup"
echo -e "${YELLOW}Step 1: Check current authentication${NC}"
echo -e "  ${CYAN}dart pub token list${NC}"
echo ""
echo -e "${YELLOW}Step 2: Add pub.dev token (if needed)${NC}"
echo -e "  ${CYAN}dart pub token add https://pub.dev${NC}"
echo -e "  Follow the browser instructions to authenticate"
echo ""

print_header "🚀 Automated Release (RECOMMENDED)"
echo -e "${YELLOW}Use the release script for full automation:${NC}"
echo -e "  ${CYAN}./scripts/release.sh${NC}"
echo ""
echo -e "${YELLOW}This script will:${NC}"
echo -e "  • Prompt for version number"
echo -e "  • Update pubspec.yaml files"
echo -e "  • Update changelogs"
echo -e "  • Run tests"
echo -e "  • Publish annotation package first"
echo -e "  • Publish main package second"
echo -e "  • Create git commit and tag"
echo ""

print_header "⚙️ Manual Publishing (Advanced)"
echo -e "${YELLOW}If you need to publish manually:${NC}"
echo ""
echo -e "${BOLD}Step 1: Publish annotation package FIRST${NC}"
echo -e "  ${CYAN}cd zikzak_morphy_annotation${NC}"
echo -e "  ${CYAN}dart pub publish --dry-run${NC}    # Test first"
echo -e "  ${CYAN}dart pub publish${NC}              # Actual publish"
echo ""
echo -e "${BOLD}Step 2: Wait for propagation (important!)${NC}"
echo -e "  ${YELLOW}Wait 1-2 minutes for pub.dev to process${NC}"
echo ""
echo -e "${BOLD}Step 3: Publish main package SECOND${NC}"
echo -e "  ${CYAN}cd ../zikzak_morphy${NC}"
echo -e "  ${CYAN}dart pub get${NC}                  # Get latest annotation"
echo -e "  ${CYAN}dart pub publish --dry-run${NC}    # Test first"
echo -e "  ${CYAN}dart pub publish${NC}              # Actual publish"
echo ""

print_header "🔧 Troubleshooting"
echo -e "${BOLD}Common Issues:${NC}"
echo ""
echo -e "${YELLOW}❌ 'No pub.dev token found'${NC}"
echo -e "  ${CYAN}Solution:${NC} Run ${CYAN}dart pub token add https://pub.dev${NC}"
echo ""
echo -e "${YELLOW}❌ 'Package validation failed'${NC}"
echo -e "  ${CYAN}Solution:${NC} Run ${CYAN}dart pub publish --dry-run${NC} to see specific issues"
echo ""
echo -e "${YELLOW}❌ 'Dependency resolution failed'${NC}"
echo -e "  ${CYAN}Solution:${NC} Ensure annotation package was published first and wait for propagation"
echo ""
echo -e "${YELLOW}❌ 'Version already exists'${NC}"
echo -e "  ${CYAN}Solution:${NC} Update version number in pubspec.yaml files"
echo ""

print_header "📊 Publishing Order (CRITICAL)"
echo -e "${RED}${BOLD}ALWAYS PUBLISH IN THIS ORDER:${NC}"
echo -e "  ${GREEN}1st:${NC} ${CYAN}zikzak_morphy_annotation${NC} (no dependencies)"
echo -e "  ${GREEN}2nd:${NC} ${CYAN}zikzak_morphy${NC} (depends on annotation)"
echo ""
echo -e "${YELLOW}Why this order matters:${NC}"
echo -e "  • Main package depends on annotation package"
echo -e "  • Pub.dev needs time to process each publication"
echo -e "  • Wrong order = dependency resolution failures"
echo ""

print_header "📱 Testing Published Packages"
echo -e "${YELLOW}After publishing, test in a new project:${NC}"
echo -e "  ${CYAN}dart create test_morphy${NC}"
echo -e "  ${CYAN}cd test_morphy${NC}"
echo -e "  ${CYAN}dart pub add zikzak_morphy_annotation${NC}"
echo -e "  ${CYAN}dart pub add dev:zikzak_morphy${NC}"
echo ""

print_header "🌐 Package URLs"
echo -e "${CYAN}Annotation Package:${NC} https://pub.dev/packages/zikzak_morphy_annotation"
echo -e "${CYAN}Main Package:${NC} https://pub.dev/packages/zikzak_morphy"
echo ""

print_header "📚 Documentation Links"
echo -e "${CYAN}Pub.dev Publishing Guide:${NC} https://dart.dev/tools/pub/publishing"
echo -e "${CYAN}Package Layout Conventions:${NC} https://dart.dev/tools/pub/package-layout"
echo -e "${CYAN}Versioning Guide:${NC} https://dart.dev/tools/pub/versioning"
echo ""

echo -e "${GREEN}✅ Ready to publish? Use: ${CYAN}./scripts/release.sh${NC}"
echo -e "${PURPLE}🔥 FOR ZIKZAK MORPHY WORLD DOMINATION! 🔥${NC}"
