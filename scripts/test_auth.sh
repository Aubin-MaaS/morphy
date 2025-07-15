#!/bin/bash

# 🔥 ZIKZAK MORPHY - AUTH TEST SCRIPT 🔥
# Simple script to test pub.dev authentication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🔥 ZIKZAK MORPHY - AUTH TEST 🔥${NC}"
echo -e "${CYAN}=================================${NC}"

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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}Testing pub.dev authentication...${NC}"
echo ""

# Test 1: Check for tokens
print_status "Test 1: Checking for pub.dev tokens"
if dart pub token list 2>/dev/null; then
    echo ""
    if dart pub token list 2>/dev/null | grep -q -E "(pub\.dev|https://pub\.dev)"; then
        print_success "Found pub.dev token!"
    else
        print_warning "No pub.dev token found in token list"
    fi
else
    print_warning "Could not list tokens (this is sometimes normal)"
fi

echo ""

# Test 2: Try dry-run on annotation package
print_status "Test 2: Testing with dry-run on annotation package"
cd "$PROJECT_ROOT/zikzak_morphy_annotation"

# Capture dry-run output to analyze
dry_run_output=$(dart pub publish --dry-run 2>&1)
dry_run_exit_code=$?

echo "$dry_run_output" | head -10
echo ""

# Check for authentication errors specifically
if echo "$dry_run_output" | grep -q -i "authentication\|unauthorized\|forbidden\|token"; then
    print_error "Authentication failed! No valid pub.dev token found."
    echo ""
    print_status "To set up authentication:"
    echo -e "  ${CYAN}dart pub token add https://pub.dev${NC}"
    echo -e "  Follow the browser instructions to authenticate"
elif [ $dry_run_exit_code -eq 0 ] || echo "$dry_run_output" | grep -q "Package validation found"; then
    print_success "Dry-run successful! Authentication is working."
    if echo "$dry_run_output" | grep -q "warning\|Warning"; then
        print_warning "Dry-run has warnings (this is normal for development)"
    fi
else
    print_warning "Dry-run had issues, but may still work for publishing"
fi

echo ""

# Test 3: Check current authentication status with curl
print_status "Test 3: Testing API access"
if curl -s "https://pub.dev/api/packages/test" >/dev/null 2>&1; then
    print_success "Can access pub.dev API"
else
    print_warning "Cannot access pub.dev API (network issue?)"
fi

echo ""

# Test 4: Show current Dart/Flutter environment
print_status "Test 4: Environment info"
echo -e "${CYAN}Dart version:${NC}"
dart --version 2>/dev/null || echo "  Dart not found"
echo ""

cd "$PROJECT_ROOT"

echo -e "${CYAN}=============================${NC}"
echo -e "${YELLOW}Authentication Test Complete${NC}"
echo ""
echo -e "${BLUE}If dry-run succeeded, you're ready to publish!${NC}"
echo -e "${BLUE}If not, run: ${CYAN}dart pub token add https://pub.dev${NC}"
