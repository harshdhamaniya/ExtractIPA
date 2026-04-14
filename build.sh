#!/bin/bash

# ExtractIPA Build Script for macOS
# This script builds the iOS app and creates an IPA file

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="ExtractIPA"
BUNDLE_ID="com.tools.extractipa"
CONFIGURATION="Release"
DESTINATION="generic/platform=iOS"
DERIVED_DATA_PATH="build"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}ExtractIPA iOS App Builder${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Check if Xcode is installed
echo -e "${YELLOW}[1/5]${NC} Checking Xcode installation..."
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode not found. Please install Xcode from App Store.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Xcode found${NC}"
echo ""

# Create Xcode project structure if not exists
echo -e "${YELLOW}[2/5]${NC} Setting up Xcode project structure..."
if [ ! -d "${PROJECT_NAME}.xcodeproj" ]; then
    echo "Creating Xcode project..."
    xcodebuild -createProject \
        -name ${PROJECT_NAME} \
        -organizationName "Tools" \
        -organizationIdentifier "com.tools" \
        2>/dev/null || true
fi
echo -e "${GREEN}✓ Project structure ready${NC}"
echo ""

# Build for iOS
echo -e "${YELLOW}[3/5]${NC} Building for iOS (${CONFIGURATION})..."
xcodebuild \
    -scheme ${PROJECT_NAME} \
    -configuration ${CONFIGURATION} \
    -destination "${DESTINATION}" \
    -derivedDataPath ${DERIVED_DATA_PATH} \
    -arch arm64 \
    build || {
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
}
echo -e "${GREEN}✓ Build completed${NC}"
echo ""

# Create IPA
echo -e "${YELLOW}[4/5]${NC} Creating IPA file..."
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.app"

if [ -d "$APP_PATH" ]; then
    mkdir -p Payload
    cp -r "$APP_PATH" Payload/
    zip -r "${PROJECT_NAME}.ipa" Payload/
    rm -rf Payload
    echo -e "${GREEN}✓ IPA created: ${PROJECT_NAME}.ipa${NC}"
else
    echo -e "${RED}❌ App bundle not found${NC}"
    exit 1
fi
echo ""

# Final summary
echo -e "${YELLOW}[5/5]${NC} Build Summary"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ IPA Successfully Created!${NC}"
echo ""
echo "📱 IPA Location: $(pwd)/${PROJECT_NAME}.ipa"
echo "📦 Size: $(du -h ${PROJECT_NAME}.ipa | cut -f1)"
echo "🆔 Bundle ID: ${BUNDLE_ID}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Transfer IPA to jailbroken device via SSH"
echo "2. Install using Cydia, Sileo, or direct deployment"
echo "3. Configure entitlements with ldid if needed"
echo ""
echo -e "${GREEN}Build completed successfully! 🎉${NC}"
