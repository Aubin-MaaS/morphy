#!/bin/bash

# 🔥 ZIKZAK MORPHY - MANUAL TOKEN SETUP 🔥
# Manual guide for setting up pub.dev authentication token

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🔥 ZIKZAK MORPHY - MANUAL TOKEN SETUP 🔥${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

echo -e "${BOLD}${YELLOW}STEP 1: Get Your Pub.dev Token${NC}"
echo -e "${CYAN}1. Open your browser and go to:${NC} ${BLUE}https://pub.dev${NC}"
echo -e "${CYAN}2. Sign in with your Google account${NC}"
echo -e "${CYAN}3. Click on your profile picture (top right)${NC}"
echo -e "${CYAN}4. Select 'My packages'${NC}"
echo -e "${CYAN}5. Click on 'Create token' or go to:${NC} ${BLUE}https://pub.dev/my-packages${NC}"
echo -e "${CYAN}6. Create a new token with these permissions:${NC}"
echo -e "   • ${GREEN}✓${NC} Package:write"
echo -e "   • ${GREEN}✓${NC} Package:read"
echo -e "${CYAN}7. Copy the generated token${NC}"
echo ""

echo -e "${BOLD}${YELLOW}STEP 2: Add Token to Dart${NC}"
echo -e "${CYAN}Run this command in your terminal:${NC}"
echo -e "  ${BLUE}dart pub token add https://pub.dev${NC}"
echo ""
echo -e "${CYAN}When prompted, paste your token from Step 1${NC}"
echo ""

echo -e "${BOLD}${YELLOW}STEP 3: Alternative Manual Setup${NC}"
echo -e "${CYAN}If the command above fails, you can manually create the token file:${NC}"
echo ""

# Get the expected token directory
TOKEN_DIR=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    TOKEN_DIR="$HOME/.config/dart/pub-credentials.json"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    TOKEN_DIR="$HOME/.config/dart/pub-credentials.json"
else
    TOKEN_DIR="~/.config/dart/pub-credentials.json"
fi

echo -e "${CYAN}Create this file:${NC} ${BLUE}$TOKEN_DIR${NC}"
echo -e "${CYAN}With this content (replace YOUR_TOKEN_HERE):${NC}"
echo ""
echo -e "${BLUE}{"
echo -e "  \"https://pub.dev\": {"
echo -e "    \"accessToken\": \"YOUR_TOKEN_HERE\","
echo -e "    \"refreshToken\": null,"
echo -e "    \"tokenEndpoint\": null,"
echo -e "    \"scopes\": [\"https://www.googleapis.com/auth/userinfo.email\"],"
echo -e "    \"expiration\": null"
echo -e "  }"
echo -e "}${NC}"
echo ""

echo -e "${BOLD}${YELLOW}STEP 4: Verify Setup${NC}"
echo -e "${CYAN}Test your authentication:${NC}"
echo -e "  ${BLUE}dart pub token list${NC}"
echo ""
echo -e "${CYAN}You should see 'pub.dev' listed${NC}"
echo ""

echo -e "${BOLD}${YELLOW}STEP 5: Test Publishing${NC}"
echo -e "${CYAN}Run the auth test script:${NC}"
echo -e "  ${BLUE}./scripts/test_auth.sh${NC}"
echo ""
echo -e "${CYAN}If successful, proceed with release:${NC}"
echo -e "  ${BLUE}./scripts/release.sh${NC}"
echo ""

echo -e "${BOLD}${RED}🚨 TROUBLESHOOTING 🚨${NC}"
echo ""
echo -e "${YELLOW}❌ 'Operation not supported by device'${NC}"
echo -e "${CYAN}Solution:${NC} Use the manual file creation method (Step 3)"
echo ""
echo -e "${YELLOW}❌ 'No pub.dev token found'${NC}"
echo -e "${CYAN}Solution:${NC} Verify the token file exists and has correct format"
echo ""
echo -e "${YELLOW}❌ 'Authentication failed'${NC}"
echo -e "${CYAN}Solution:${NC} Generate a new token from pub.dev and replace the old one"
echo ""
echo -e "${YELLOW}❌ 'Token expired'${NC}"
echo -e "${CYAN}Solution:${NC} Delete old token and create a new one"
echo -e "  ${BLUE}rm $TOKEN_DIR${NC}"
echo -e "  ${BLUE}dart pub token add https://pub.dev${NC}"
echo ""

echo -e "${BOLD}${GREEN}📱 QUICK COMMANDS${NC}"
echo -e "${CYAN}List tokens:${NC} ${BLUE}dart pub token list${NC}"
echo -e "${CYAN}Remove token:${NC} ${BLUE}dart pub token remove https://pub.dev${NC}"
echo -e "${CYAN}Add token:${NC} ${BLUE}dart pub token add https://pub.dev${NC}"
echo -e "${CYAN}Test auth:${NC} ${BLUE}./scripts/test_auth.sh${NC}"
echo -e "${CYAN}Release:${NC} ${BLUE}./scripts/release.sh${NC}"
echo ""

echo -e "${BOLD}${PURPLE}🔥 READY FOR ZIKZAK DOMINATION! 🔥${NC}"
echo -e "${CYAN}After setup, run: ${BLUE}./scripts/release.sh${NC}"
