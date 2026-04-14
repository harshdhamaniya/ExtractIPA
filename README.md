# ExtractIPA - iOS App Extractor

A native iOS application for jailbroken devices that lists installed apps and extracts them as IPA files for distribution and testing.

## Features

✅ **App Discovery** - Automatically scans and lists all installed applications on the device
✅ **IPA Extraction** - Converts app bundles to standard IPA format with proper structure
✅ **Progress Tracking** - Real-time extraction progress with file size indicators
✅ **Smart Storage** - Saves extracted IPAs to Documents folder for easy access
✅ **Search & Filter** - Find apps quickly by name or bundle ID
✅ **Error Handling** - Comprehensive error messages and retry mechanisms
✅ **File Management** - View extracted IPAs and handle file naming conflicts

## Architecture

### Project Structure

```
ExtractIPA/
├── ExtractIPAApp.swift          # App entry point and state management
├── Models.swift                 # Data models and error types
├── AppLister.swift              # App discovery service
├── IPAExtractor.swift           # IPA extraction orchestrator
├── DocumentsManager.swift       # File system and storage management
├── ViewModels.swift             # UI state management (MVVM)
└── ContentView.swift            # SwiftUI interface components
```

### Core Services

#### **AppLister**
Scans device directories for installed apps:
- Checks `/var/containers/Bundle/Application/` (standard iOS app location)
- Checks `/Applications` (for system and jailbroken apps)
- Parses Info.plist files for app metadata
- Extracts app name, version, bundle ID, executable name
- Calculates app bundle size
- Resolves symbolic links

#### **IPAExtractor**
Creates proper IPA archives:
- Creates Payload directory structure
- Copies app bundle to Payload/
- Compresses using ZIP format
- Generates standard .ipa files
- Supports progress callbacks
- Handles large files efficiently

#### **DocumentsManager**
Manages file storage:
- Creates ExtractedIPAs folder in Documents
- Checks available storage space
- Lists extracted IPAs
- Handles file naming conflicts
- Provides file size formatting

### UI Architecture (MVVM)

**ViewModels:**
- `AppListViewModel` - Manages app discovery and filtering
- `ExtractionViewModel` - Manages extraction state and progress

**Views:**
- `ContentView` - Main app container
- `AppListView` - App list with search
- `AppDetailView` - App details and extraction UI
- `ExtractionProgressView` - Progress tracking
- `SuccessView` - Extraction completion

## Requirements

### System Requirements
- Jailbroken iOS device (iOS 13.0 or later recommended)
- Access to `/var/containers/Bundle/Application/` directory
- Zip utility installed (`/usr/bin/zip`)

### Xcode Requirements
- Xcode 14.0 or later
- Swift 5.7+
- iOS deployment target: 13.0

### Required Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>application-identifier</key>
    <string>*</string>

    <key>com.apple.private.security.no-container</key>
    <true/>

    <key>platform-application</key>
    <true/>

    <key>com.apple.private.files.dasd.open-for-read</key>
    <true/>

    <key>com.apple.private.files.dasd.open-for-write</key>
    <true/>
</dict>
</plist>
```

**Note:** These entitlements require signing with Apple's private certificates, which necessitates:
- A jailbroken device with Sileo/Cydia
- An entitlements patcher or custom signing setup
- Or building as an unsigned executable on the device itself

## Usage

### Basic Flow

1. **Launch App** → App discovers installed applications
2. **Search/Browse** → Find the app you want to extract
3. **Select App** → Tap app to view details
4. **Extract IPA** → Tap "Extract IPA" button
5. **Monitor Progress** → Watch extraction progress
6. **Access File** → Extracted IPA saved to Documents/ExtractedIPAs/

### File Locations

- **Extracted IPAs:** `Documents/ExtractedIPAs/`
- **IPA Naming:** `[AppName]-[Version].ipa`
- **Temp Files:** Cleaned up automatically after extraction

## Installation

### Option 1: Xcode Build

```bash
cd /path/to/ExtractIPA
open ExtractIPA.xcodeproj
# Build and run on jailbroken device
```

### Option 2: Command Line Build

```bash
cd /path/to/ExtractIPA
xcodebuild -scheme ExtractIPA -configuration Release
```

### Option 3: On-Device Compilation

For pre-jailbroken devices with development tools:

```bash
# SSH into device
ssh root@device.local

# Compile on device (requires Clang/LLVM)
clang -fmodules -fimplicit-module-maps -Qunused-arguments \
  -Xclang -isysroot -Xclang /var/stash/_.XXXXXXX/System/Library/Frameworks \
  -framework UIKit -framework Foundation -o ExtractIPA ExtractIPA.swift
```

## Error Handling

### Common Errors

#### **"No installed apps found"**
- Ensure device is properly jailbroken
- Check `/var/containers/Bundle/Application/` permissions
- Verify app directories are accessible

#### **"Permission denied accessing app data"**
- App lacks required entitlements
- Device security policies blocking access
- Try running with `sudo` if on SSH connection

#### **"Insufficient storage space"**
- Not enough free space on device
- Check available storage with `df` command
- Clear cache or unused files

#### **"Extraction failed: Zip creation failed"**
- `/usr/bin/zip` not available on device
- Install zip utility: `apt-get install zip`
- Verify file permissions in temp directory

### Retry Mechanism

The app automatically provides retry options for:
- Network timeouts
- Temporary file access issues
- Concurrent access conflicts

## Development

### Key Classes and Methods

**AppLister**
```swift
func listInstalledApps() async throws -> [AppInfo]
func parseAppBundle(at: String) throws -> AppInfo?
```

**IPAExtractor**
```swift
func extractIPA(from: AppInfo, to: URL, progressCallback: @escaping (ExtractionProgress) -> Void) async throws -> URL
```

**DocumentsManager**
```swift
var extractedIPAsDirectory: URL
func hasEnoughSpace(for: Int64) -> Bool
func getFileSize(at: URL) -> Int64
```

### Adding Features

To extend functionality:

1. **New extraction formats** → Extend `IPAExtractor`
2. **Additional app metadata** → Update `AppInfo` model
3. **Cloud storage** → Add to `DocumentsManager`
4. **Filtering options** → Update `AppListViewModel`

## IPA File Structure

The app generates standard IPA archives:

```
MyApp.ipa (ZIP file)
├── Payload/
│   └── MyApp.app/
│       ├── Info.plist
│       ├── PkgInfo
│       ├── MyApp (executable)
│       ├── Frameworks/
│       │   └── [Dynamic frameworks]
│       ├── PlugIns/
│       │   └── [App extensions]
│       ├── Assets.car (image assets)
│       └── [Other resources]
├── iTunesMetadata.plist (optional)
└── iTunesArtwork (optional)
```

Compatible with:
- Apple Configurator 2
- TestFlight (with modifications)
- iPhone Configuration Utility
- iOS App Installer tools

## Performance Considerations

### Optimization Tips

1. **Large Apps** → Extraction may take several minutes
2. **Network Storage** → Avoid storing IPAs on network shares
3. **Memory Usage** → Monitor device memory during extraction
4. **Multiple Extractions** → Extract one app at a time

### Progress Tracking

- Updates every 500ms to prevent UI lag
- Shows file-by-file progress for large bundles
- Estimated time remaining calculated internally

## Troubleshooting

### Apps Not Discovered

```bash
# SSH to device and check app directories
ls -la /var/containers/Bundle/Application/
ls -la /Applications/
```

### Permission Issues

```bash
# Adjust permissions if needed
chmod -R 755 /var/containers/Bundle/Application/
```

### Manual Cleanup

```bash
# Remove temp files if stuck
rm -rf /tmp/IPA_*
```

## Limitations

⚠️ **Jailbreak Only** - Requires jailbroken iOS device
⚠️ **No DRM** - Cannot extract encrypted/protected apps
⚠️ **File Size** - Large apps (5GB+) may take considerable time
⚠️ **Storage** - Needs sufficient free space (app size × 2)
⚠️ **iOS Version** - May need adjustments for newer iOS versions

## Security Notes

The app requires:
- Direct filesystem access (jailbreak privilege)
- Ability to read private app bundles
- Write access to Documents folder

Use only on:
- Personal devices
- Test/development devices
- Devices you have explicit permission to jailbreak

## License

This tool is for educational and personal use only. Extracting and redistributing apps may violate app store terms of service and copyright laws in your jurisdiction.

## Support

For issues or questions:
1. Check Troubleshooting section
2. Verify filesystem permissions
3. Ensure device jailbreak is functioning
4. Review system logs: `log stream --level debug`

## Future Enhancements

- [ ] Batch extraction of multiple apps
- [ ] IPA signing and re-packaging
- [ ] Cloud backup integration
- [ ] App icon export
- [ ] Metadata editing before extraction
- [ ] FTP/Cloud upload support
- [ ] App dependency analysis
- [ ] Patch/modification support

---

## About Developer

**Developed with ❤️ by Harsh Dhamaniya**

Connect with me:

- 🔗 **LinkedIn** - [harshdhamaniya](https://www.linkedin.com/in/harshdhamaniya/)
- 🐙 **GitHub** - [harshdhamaniya](https://github.com/harshdhamaniya)
- 📸 **Instagram** - [@damnnharsh](https://www.instagram.com/damnnharsh/)

---

**Note:** This tool should only be used for legitimate purposes such as personal app backup, security testing, and research on your own devices or with explicit permission.
