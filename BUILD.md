# ExtractIPA - Complete Build Guide

## 📋 Overview

This guide covers all methods to build ExtractIPA as an iOS IPA file. Since iOS development requires macOS and Xcode, we provide multiple options depending on your setup.

---

## 🔧 Prerequisites

### Minimum Requirements
- **macOS 12.0+** (Monterey or later)
- **Xcode 14.0+** with Command Line Tools
- **20 GB** free disk space
- **8 GB** RAM minimum

### Optional
- **Git** for version control
- **Homebrew** for package management
- **Docker** for containerized builds

---

## Build Method 1: Direct Xcode Build (Easiest - Mac Only)

### Step-by-Step

#### 1. **Install/Update Xcode**

```bash
# Install Xcode from App Store
# OR use command line tools

xcode-select --install
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

#### 2. **Verify Installation**

```bash
xcodebuild -version
swift --version
```

#### 3. **Create Xcode Project**

```bash
cd ~/Desktop/Tools/Mobile\ App\ Testing/ExtractIPA

# Create project structure
mkdir -p ExtractIPA.xcodeproj/project.pbxproj
mkdir -p Sources
mkdir -p Tests

# Copy source files
cp *.swift Sources/ 2>/dev/null || true
```

#### 4. **Open in Xcode**

```bash
open ExtractIPA.xcodeproj
# OR manually create project in Xcode
```

**In Xcode:**
1. Select target "ExtractIPA"
2. Go to **General** settings
3. Set Bundle Identifier: `com.tools.extractipa`
4. Set Deployment Target: iOS 13.0
5. Go to **Signing & Capabilities**
6. Add Entitlements file: `ExtractIPA.entitlements`

#### 5. **Build**

```bash
# Build for Release
xcodebuild \
  -scheme ExtractIPA \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -derivedDataPath build \
  -arch arm64 \
  build
```

#### 6. **Create IPA**

```bash
# Navigate to build output
cd build/Build/Products/Release-iphoneos/

# Create IPA structure
mkdir -p Payload
mv ExtractIPA.app Payload/
zip -r ../ExtractIPA.ipa Payload/

# Result: ExtractIPA.ipa is ready!
```

---

## Build Method 2: Automated Build Script (Mac)

### Quick Build with One Command

#### 1. **Make Script Executable**

```bash
cd ~/Desktop/Tools/Mobile\ App\ Testing/ExtractIPA
chmod +x build.sh
```

#### 2. **Run Build**

```bash
./build.sh
```

**Output:**
```
========================================
ExtractIPA iOS App Builder
========================================

[1/5] Checking Xcode installation...
✓ Xcode found

[2/5] Setting up Xcode project structure...
✓ Project structure ready

[3/5] Building for iOS (Release)...
✓ Build completed

[4/5] Creating IPA file...
✓ IPA created: ExtractIPA.ipa

[5/5] Build Summary
========================================
✓ IPA Successfully Created!

📱 IPA Location: /path/to/ExtractIPA.ipa
📦 Size: 15.3 MB
🆔 Bundle ID: com.tools.extractipa

✅ Build completed successfully! 🎉
```

#### 3. **Find Your IPA**

```bash
ls -lh ExtractIPA.ipa
```

---

## Build Method 3: Swift Package Manager (Mac)

### Build as Swift Package

#### 1. **Check Package.swift**

```bash
cat Package.swift
```

#### 2. **Build Package**

```bash
swift build -c release
```

#### 3. **Alternative: Build iOS App**

```bash
# For iOS app specifically
swift build \
  -c release \
  --platform ios \
  --arch arm64 \
  --triple aarch64-apple-ios13.0
```

---

## Build Method 4: GitHub Actions (Cloud Build - No Mac Needed!)

### ☁️ Build in Cloud for Free

#### 1. **Push to GitHub**

```bash
cd ~/Desktop/Tools/Mobile\ App\ Testing/ExtractIPA

git init
git add .
git commit -m "Initial ExtractIPA project"
git remote add origin https://github.com/harshdhamaniya/ExtractIPA.git
git push -u origin main
```

#### 2. **Automatic Build Triggers**

Push to GitHub, and the build runs automatically:
- On every commit to `main` or `develop`
- On every pull request
- Manually via "Actions" tab in GitHub

#### 3. **Download Built IPA**

1. Go to your GitHub repo
2. Click **Actions** tab
3. Select latest workflow run
4. Click **Artifacts** section
5. Download `ExtractIPA-*.ipa`

**Benefits:**
- ✅ No local build needed
- ✅ Automatic on every push
- ✅ History of all builds
- ✅ 30-day artifact storage
- ✅ Works on Windows/Linux

#### 4. **Create Release**

Tag your commit for automated release:

```bash
git tag v1.0.0
git push --tags
```

Goes straight to Releases with built IPA!

---

## Build Method 5: Docker (Containerized Build)

### Build in Container (No Xcode Install Needed)

#### 1. **Install Docker**

```bash
# macOS
brew install docker colima
colima start

# or use Docker Desktop from docker.com
```

#### 2. **Build with Docker**

```bash
cd ~/Desktop/Tools/Mobile\ App\ Testing/ExtractIPA

docker build -t extractipa-builder .
docker run -v $(pwd):/app extractipa-builder
```

#### 3. **Extract IPA from Container**

```bash
docker run -it \
  -v $(pwd):/output \
  extractipa-builder \
  bash -c "cp *.ipa /output/"
```

---

## Build Method 6: Windows → Remote Mac Build

### For Windows Users With Remote Mac Access

#### 1. **Install SSH**

```bash
# Enable SSH on Mac
System Preferences → Sharing → Remote Login

# Note Mac IP address (192.168.x.x)
```

#### 2. **Connect From Windows**

```powershell
# PowerShell on Windows
ssh user@mac_ip_address

# Or use Git Bash/WSL
ssh user@192.168.x.x
```

#### 3. **Build on Remote Mac**

```bash
# On connected Mac
cd /path/to/ExtractIPA
chmod +x build.sh
./build.sh
```

#### 4. **Download IPA**

```powershell
# PowerShell on Windows
scp user@192.168.x.x:/path/to/ExtractIPA/ExtractIPA.ipa .
```

---

## Troubleshooting Builds

### Build Fails: Xcode Not Found

```bash
# Solution 1: Install Xcode
xcode-select --install

# Solution 2: Update to latest
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### Build Fails: Swift Version Mismatch

```bash
# Check Swift version
swift --version

# Update Xcode to latest
xcode-select --install
```

### Build Fails: Not Enough Disk Space

```bash
# Check available space
df -h

# Clean build cache
rm -rf build/
xcodebuild clean
```

### Build Fails: Entitlements Issues

```bash
# Verify entitlements file
cat ExtractIPA.entitlements

# Re-sign after build
ldid -S ExtractIPA.entitlements \
  build/Build/Products/Release-iphoneos/ExtractIPA.app/ExtractIPA
```

### Build Succeeds but IPA Creation Fails

```bash
# Manual IPA creation
cd build/Build/Products/Release-iphoneos/
mkdir -p Payload
cp -r ExtractIPA.app Payload/
zip -r ../ExtractIPA.ipa Payload/
```

---

## Build Configuration Options

### Release Build (For Distribution)

```bash
xcodebuild \
  -configuration Release \
  -arch arm64 \
  build
```

### Debug Build (For Testing)

```bash
xcodebuild \
  -configuration Debug \
  -arch arm64 \
  build
```

### Optimized Build (Minimal Size)

```bash
xcodebuild \
  -configuration Release \
  STRIP_INSTALLED_PRODUCT=YES \
  COPY_PHASE_STRIP=YES \
  build
```

---

## Output Files & Locations

### After Successful Build

```
ExtractIPA/
├── build/
│   └── Build/
│       └── Products/
│           └── Release-iphoneos/
│               └── ExtractIPA.app     ← App bundle
├── Payload/                           ← Intermediate
├── ExtractIPA.ipa                     ← FINAL IPA FILE ⭐
└── build.log                          ← Build log
```

### Check Build Details

```bash
# List IPA contents
unzip -l ExtractIPA.ipa

# Check IPA size
du -h ExtractIPA.ipa

# Verify structure
```

---

## Deployment After Build

### Option 1: SSH to Device

```bash
scp ExtractIPA.ipa root@device.local:/tmp/

# SSH into device
ssh root@device.local

# Unzip and install
cd /tmp
unzip ExtractIPA.ipa
cp -r Payload/ExtractIPA.app /var/mobile/Applications/
chmod 755 /var/mobile/Applications/ExtractIPA.app/*
ldid -S ExtractIPA.entitlements \
  /var/mobile/Applications/ExtractIPA.app/ExtractIPA
killall -9 SpringBoard
```

### Option 2: Cydia Package

Convert IPA to .deb package for Cydia:

```bash
# Extract
unzip ExtractIPA.ipa

# Create package structure
mkdir -p DEBIAN
cat > DEBIAN/control << EOF
Package: com.tools.extractipa
Name: ExtractIPA
Version: 1.0
Architecture: iphoneos-arm
Description: Extract IPA files from installed apps
Maintainer: Harsh Dhamaniya <harsh@example.com>
Author: Harsh Dhamaniya
EOF

# Build .deb
dpkg-deb -Zbzip2 -b . ExtractIPA.deb
```

### Option 3: OTA Installation

See SETUP.md for complete OTA setup guide.

---

## Recommended Build Flow

```
1. Development
   └─ On Mac with Xcode

2. Build
   ├─ Use build.sh for quick local builds
   └─ OR push to GitHub for cloud builds

3. Test
   └─ Deploy to jailbroken test device

4. Release
   ├─ Tag commit: git tag v1.0.0
   ├─ Push tag (GitHub Actions auto-builds)
   └─ Assets automatically uploaded to Releases

5. Distribution
   ├─ Share IPA via GitHub Releases
   ├─ Deploy via SSH to devices
   └─ Publish as Cydia package
```

---

## Performance Tips

### Faster Builds

```bash
# Use parallel jobs
xcodebuild \
  -j 4 \  # Use 4 CPU cores
  -configuration Release \
  build
```

### Faster Testing

```bash
# Skip unnecessary steps
xcodebuild \
  -configuration Release \
  -derivedDataPath build \
  -skipPackagePluginValidation \
  build
```

### Reduce IPA Size

```bash
# Bitcode disabled
xcodebuild \
  BITCODE_GENERATION_MODE=bitcode \
  -configuration Release \
  build
```

---

## Version Management

### Build Versioning

Update version in Info.plist:

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<key>CFBundleVersion</key>
<string>1</string>
```

### Git Tagging for Releases

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push --tags
# GitHub Actions automatically creates release with IPA
```

---

## Next Steps After Building

✅ **Build Complete?**
1. ✓ Verify IPA file exists and has correct size
2. ✓ Test on jailbroken iOS device
3. ✓ Deploy to team/users
4. ✓ Collect feedback
5. ✓ Plan next version improvements

**Ready to Deploy?** → See **SETUP.md** for deployment guide

---

## Support

Having build issues? Try:
1. Check Xcode version: `xcodebuild -version`
2. Run diagnostics: `xcode-select --install`
3. Review build log: `cat build.log`
4. Check available disk space: `df -h`
5. Ask on GitHub Issues

---

**Built with ❤️ by Harsh Dhamaniya**

🔗 [LinkedIn](https://www.linkedin.com/in/harshdhamaniya/) | 🐙 [GitHub](https://github.com/harshdhamaniya) | 📸 [Instagram](https://www.instagram.com/damnnharsh/)
