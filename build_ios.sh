#!/bin/bash
set -e

echo "🔨 Building ExtractIPA for iOS..."

# Get iOS SDK path
iOS_SDK=$(xcrun --show-sdk-path --sdk iphoneos)
echo "iOS SDK: $iOS_SDK"

# Create build directory
mkdir -p build

# Compile Swift code directly to iOS ARM64 binary
echo "Compiling Swift code..."
swiftc \
  -o build/ExtractIPA \
  -module-name ExtractIPA \
  -emit-executable \
  -O \
  -target arm64-apple-ios16.0 \
  -sdk "$iOS_SDK" \
  -Xcc -fmodule-map-file="$iOS_SDK/usr/include/module.modulemap" \
  Sources/ExtractIPAApp.swift \
  Sources/Models.swift \
  Sources/AppLister.swift \
  Sources/IPAExtractor.swift \
  Sources/DocumentsManager.swift \
  Sources/ViewModels.swift \
  Sources/ContentView.swift

echo "✅ Binary compiled successfully"
file build/ExtractIPA

# Create app bundle
echo ""
echo "Creating app bundle..."
mkdir -p build/Payload/ExtractIPA.app

# Copy executable
cp build/ExtractIPA build/Payload/ExtractIPA.app/
chmod +x build/Payload/ExtractIPA.app/ExtractIPA

# Copy Info.plist
cp Info.plist build/Payload/ExtractIPA.app/

# Copy entitlements
cp ExtractIPA.entitlements build/Payload/ExtractIPA.app/

echo "✅ App bundle created"
ls -lh build/Payload/ExtractIPA.app/*

# Create IPA
echo ""
echo "Creating IPA..."
cd build/Payload
zip -r -q ../ExtractIPA.ipa ExtractIPA.app/
cd ../..

echo "✅ IPA created successfully"
ls -lh build/ExtractIPA.ipa

echo ""
echo "📦 IPA Contents:"
unzip -l build/ExtractIPA.ipa | head -20

echo ""
echo "✅ Build complete! IPA ready at: build/ExtractIPA.ipa"
