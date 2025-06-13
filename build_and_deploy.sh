#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building MindraTimer...${NC}"
xcodebuild -scheme MindraTimer -configuration Release -archivePath build/MindraTimer.xcarchive archive

echo -e "${BLUE}Creating DMG...${NC}"
TEMP_DMG_DIR="temp_dmg"
mkdir -p "$TEMP_DMG_DIR"
cp -R "build/MindraTimer.xcarchive/Products/Applications/MindraTimer.app" "$TEMP_DMG_DIR/"
hdiutil create -volname "MindraTimer" -srcfolder "$TEMP_DMG_DIR" -ov -format UDZO "MindraTimer.dmg"
rm -rf "$TEMP_DMG_DIR"

echo -e "${BLUE}Copying DMG to docs directory...${NC}"
cp MindraTimer.dmg docs/

echo -e "${GREEN}Done! The DMG is now in both the root directory and docs directory.${NC}"
echo -e "${GREEN}You can now commit and push your changes to deploy to GitHub Pages.${NC}" 