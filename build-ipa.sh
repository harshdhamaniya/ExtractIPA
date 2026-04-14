#!/bin/bash
# Build ExtractIPA iOS App - Run on Mac with Xcode

set -e

cd "$(dirname "$0")"

echo "🔨 Building ExtractIPA for iOS..."
echo ""

# Get iOS SDK
iOS_SDK=$(xcrun --show-sdk-path --sdk iphoneos)
echo "📱 iOS SDK: $iOS_SDK"

# Create build directory
mkdir -p build

# Compile Swift files for iOS ARM64
echo "⏳ Compiling Swift source for iOS ARM64..."
swiftc -o build/ExtractIPA \
  -module-name ExtractIPA \
  Sources/main.swift \
  Sources/Models.swift \
  Sources/AppLister.swift \
  Sources/IPAExtractor.swift \
  Sources/DocumentsManager.swift \
  Sources/ViewModels.swift \
  Sources/ContentView.swift \
  -sdk "$iOS_SDK" \
  -target arm64-apple-ios16.0 \
  -parse-as-library \
  -Osize \
  2>&1

# Verify binary was created
if [ ! -f "build/ExtractIPA" ]; then
  echo "❌ Compilation failed"
  exit 1
fi

# Check binary type
BINARY_TYPE=$(file build/ExtractIPA)
echo "✅ Binary created: $BINARY_TYPE"
echo "📊 Size: $(du -h build/ExtractIPA | cut -f1)"

# Create IPA structure
echo "📦 Creating IPA..."
mkdir -p Payload/ExtractIPA.app

# Copy binary
cp build/ExtractIPA Payload/ExtractIPA.app/
chmod +x Payload/ExtractIPA.app/ExtractIPA

# Copy Info.plist
cp Info.plist Payload/ExtractIPA.app/

# Copy entitlements
cp ExtractIPA.entitlements Payload/ExtractIPA.app/

# Create IPA (ZIP with Payload at root)
rm -f ExtractIPA-compiled.ipa
zip -r ExtractIPA-compiled.ipa Payload/

echo ""
echo "✅ IPA CREATED: ExtractIPA-compiled.ipa"
echo "📊 Size: $(du -h ExtractIPA-compiled.ipa | cut -f1)"
echo ""
echo "🚀 Ready to deploy with iSideload or Xcode!"
echo ""
echo "IPA Contents:"
unzip -l ExtractIPA-compiled.ipa | head -20
