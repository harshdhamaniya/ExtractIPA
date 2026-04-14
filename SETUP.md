# ExtractIPA - Setup & Deployment Guide

## Quick Start

This guide covers how to set up, build, and deploy the ExtractIPA application on a jailbroken iOS device.

## Prerequisites

### For Development Machine
- **Xcode 14.0+** with Swift 5.7+
- **macOS 12.0+** (Monterey or later)
- **Git** (for version control)
- **Homebrew** (optional, for additional tools)

### For Target Device
- **Jailbroken iOS device** (iOS 13.0+)
- **SSH access** enabled (via OpenSSH package)
- **Zip utility** installed (`apt-get install zip`)
- **At least 2GB free storage** for IPA extraction

## Setup Instructions

### 1. Prepare Development Environment

```bash
# Ensure Xcode Command Line Tools are installed
xcode-select --install

# If already installed, update to latest version
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### 2. Clone/Setup Project

```bash
# Navigate to project directory
cd ~/Desktop/Tools/Mobile\ App\ Testing/ExtractIPA

# Initialize with Git (optional)
git init
git add .
git commit -m "Initial ExtractIPA project structure"
```

### 3. Create Xcode Project

Since we're creating a Swift package, you have two options:

#### Option A: Use Swift Package Manager (SPM)

```bash
# Create workspace
swift package init --type executable --name ExtractIPA
```

#### Option B: Create iOS App Bundle Manually

```bash
# Create the project structure
mkdir -p ExtractIPA.app/Contents

# Copy source files to bundle
cp *.swift ExtractIPA.app/Contents/
cp Info.plist ExtractIPA.app/Contents/
cp ExtractIPA.entitlements ExtractIPA.app/Contents/
```

### 4. Configure Build Settings

**For Xcode Project:**

1. Open `ExtractIPA.xcodeproj` in Xcode
2. Select target "ExtractIPA"
3. Go to **Build Settings** and set:
   - **Signing & Capabilities** → Add capabilities:
     - `com.apple.private.security.no-container`
     - `com.apple.private.files.dasd.open-for-read`
     - `com.apple.private.files.dasd.open-for-write`
   - **Bundle Identifier** → `com.tools.extractipa`
   - **Deployment Target** → iOS 13.0
   - **Code Signing Identity** → "iPhone Developer" or Ad Hoc

## Building the App

### Build Using Xcode

```bash
# Build for Release
xcodebuild -scheme ExtractIPA -configuration Release \
  -derivedDataPath build/ \
  build

# Built files will be in: build/Build/Products/Release-iphoneos/

# Create IPA (app bundle)
cd build/Build/Products/Release-iphoneos/
mkdir -p Payload
mv ExtractIPA.app Payload/
zip -r ../ExtractIPA.ipa Payload/
```

### Build Using Command Line

```bash
# Compile Swift files
swiftc -o ExtractIPA \
  -module-name ExtractIPA \
  -parse-as-library \
  ExtractIPAApp.swift \
  Models.swift \
  AppLister.swift \
  IPAExtractor.swift \
  DocumentsManager.swift \
  ViewModels.swift \
  ContentView.swift
```

## Deployment to Jailbroken Device

### Method 1: SSH Direct Installation

```bash
# Variables
DEVICE_IP="192.168.1.100"
DEVICE_PORT="22"
DEVICE_USER="root"
APP_PATH="/var/mobile/Applications/ExtractIPA"

# SSH into device
ssh -p $DEVICE_PORT $DEVICE_USER@$DEVICE_IP

# On device:
mkdir -p $APP_PATH
cd $APP_PATH

# Exit SSH and transfer files
exit

# Transfer app files
scp -r -P $DEVICE_PORT build/Build/Products/Release-iphoneos/ExtractIPA.app \
  $DEVICE_USER@$DEVICE_IP:$APP_PATH/

# Back in SSH
ssh -p $DEVICE_PORT $DEVICE_USER@$DEVICE_IP

# Set permissions
chmod 755 /var/mobile/Applications/ExtractIPA/ExtractIPA.app
chmod 755 /var/mobile/Applications/ExtractIPA/ExtractIPA.app/ExtractIPA

# Install entitlements (if using ldid)
ldid -S ExtractIPA.entitlements /var/mobile/Applications/ExtractIPA/ExtractIPA.app/ExtractIPA

# Refresh Cydia (if installed in /Applications)
killall SpringBoard
```

### Method 2: Using Cydia/Sileo

1. Build the app as a Debian package (.deb)
2. Upload to your Cydia repository
3. Install from Cydia:
   ```bash
   apt-get install extractipa
   ```

### Method 3: Over-the-Air (OTA)

```bash
# Create IPA distribution format
mkdir -p ExtractIPA.app/Contents
cp -r build/Build/Products/Release-iphoneos/ExtractIPA.app/* \
  ExtractIPA.app/Contents/

# Create manifest
cat > manifest.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>items</key>
    <array>
        <dict>
            <key>assets</key>
            <array>
                <dict>
                    <key>kind</key>
                    <string>software-package</string>
                    <key>url</key>
                    <string>https://yourserver.com/ExtractIPA.ipa</string>
                </dict>
            </array>
            <key>metadata</key>
            <dict>
                <key>bundle-identifier</key>
                <string>com.tools.extractipa</string>
                <key>bundle-version</key>
                <string>1.0</string>
                <key>kind</key>
                <string>software</string>
                <key>title</key>
                <string>ExtractIPA</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>
EOF

# Serve files via HTTPS
cp manifest.plist /var/www/html/
cp ExtractIPA.ipa /var/www/html/

# Create installation link
echo "itms-services://?action=download-manifest&url=https://yourserver.com/manifest.plist"
```

## Verification & Testing

### After Installation

```bash
# SSH into device
ssh root@192.168.1.100

# Verify app exists
ls -la /var/mobile/Applications/ExtractIPA/

# Check entitlements
ldid -e /var/mobile/Applications/ExtractIPA/ExtractIPA.app/ExtractIPA

# Run app from command line (optional)
/var/mobile/Applications/ExtractIPA/ExtractIPA.app/ExtractIPA
```

### Test Functionality

1. **Launch App** from SpringBoard
2. **Wait for app discovery** (should complete in 10-30 seconds)
3. **Verify apps are listed** (should show multiple apps)
4. **Search for an app** (test search functionality)
5. **Select an app** and view details
6. **Extract IPA** and monitor progress
7. **Check Documents folder** for extracted IPA:
   ```bash
   ls -la /var/mobile/Containers/Data/Application/*/Documents/ExtractedIPAs/
   ```

## Troubleshooting

### App Won't Launch

```bash
# Check app logs
log stream --process ExtractIPA --level debug

# Verify entitlements are applied
ldid -e /var/mobile/Applications/ExtractIPA/ExtractIPA.app/ExtractIPA

# Check memory usage
top
```

### Apps Not Discovered

```bash
# Verify permissions on app directories
ls -la /var/containers/Bundle/Application/
ls -la /Applications/

# Check for permission issues
chmod 755 /var/containers/Bundle/Application/*
```

### Extraction Fails

```bash
# Ensure zip is installed
which zip
apt-get install zip

# Check available disk space
df -h

# Verify temp directory
ls -la /tmp/
chmod 777 /tmp/
```

## Performance Optimization

### For Large Apps (5GB+)

1. **Check available RAM**
   ```bash
   free -h
   ```

2. **Clear cache before extraction**
   ```bash
   rm -rf /var/mobile/Library/Caches/*
   ```

3. **Extract during off-peak hours** to avoid system slowdown

### Network Optimization (for SSH transfers)

```bash
# Use compression for faster SCP transfer
scp -C -P 22 root@device:/path/to/file .

# Monitor transfer speed
scp -v ...

# Use rsync for partial transfers
rsync -avz --partial root@device:/path/to/app/ ./
```

## Building for Different Scenarios

### Debug Build (Development)

```bash
xcodebuild -scheme ExtractIPA -configuration Debug \
  -derivedDataPath build/ \
  GCC_PREPROCESSOR_DEFINITIONS='DEBUG=1'
```

### Release Build (Production)

```bash
xcodebuild -scheme ExtractIPA -configuration Release \
  -derivedDataPath build/ \
  STRIP_INSTALLED_PRODUCT=YES \
  COPY_PHASE_STRIP=YES
```

### Minimized Build

```bash
# Strip debug symbols
strip -S /path/to/ExtractIPA

# Compress IPA
zip -r -q ExtractIPA-min.ipa ExtractIPA.app
```

## Advanced Configuration

### Custom Directories

Edit `AppLister.swift` to scan additional directories:

```swift
private let appDirectories = [
    "/var/containers/Bundle/Application",
    "/Applications",
    "/var/stash/Applications",  // Custom location
    "/opt/local/apps"           // Another custom location
]
```

### Modify Extraction Location

Edit `DocumentsManager.swift`:

```swift
var extractedIPAsDirectory: URL {
    // Change to custom directory
    return URL(fileURLWithPath: "/var/mobile/ExtractedIPAs")
}
```

## Maintenance

### Regular Updates

```bash
# Pull latest changes
cd ~/Desktop/Tools/Mobile\ App\ Testing/ExtractIPA
git pull origin main

# Rebuild and redeploy
xcodebuild -scheme ExtractIPA -configuration Release -derivedDataPath build/
# ... follow deployment steps above
```

### Uninstall

```bash
ssh root@device

# Remove application
rm -rf /var/mobile/Applications/ExtractIPA/

# Clear cached data
rm -rf /var/mobile/Containers/Data/Application/[UUID]/

# Refresh SpringBoard
killall -9 SpringBoard
```

## Next Steps

After successful deployment:

1. ✅ Test with various apps
2. ✅ Extract IPAs and verify structure
3. ✅ Share IPAs with other devices
4. ✅ Monitor performance and logs
5. ✅ Collect feedback for improvements

## Support & Debugging

### Enable Verbose Logging

Add to `AppLister.swift`:

```swift
func listInstalledApps() async throws -> [AppInfo] {
    print("DEBUG: Starting app discovery...")
    // ... rest of code
    print("DEBUG: Found \(apps.count) apps")
}
```

### Common Issues Reference

See **README.md** for detailed troubleshooting guide.

---

**Last Updated:** 2024
**Version:** 1.0
**Status:** Ready for Deployment
