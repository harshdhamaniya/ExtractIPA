import Foundation

// MARK: - App Lister Service

class AppLister {
    // Standard iOS app directories
    private let appDirectories = [
        "/var/containers/Bundle/Application",
        "/Applications" // For system apps and jailbroken apps
    ]

    // MARK: - Public Methods

    /// Scans device for installed applications
    func listInstalledApps() async throws -> [AppInfo] {
        var apps: [AppInfo] = []

        for directory in appDirectories {
            let path = directory
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: path)

                for bundleFolder in contents {
                    let bundlePath = (path as NSString).appendingPathComponent(bundleFolder)

                    // Skip if it's a file, not a directory
                    var isDir: ObjCBool = false
                    guard FileManager.default.fileExists(atPath: bundlePath, isDirectory: &isDir),
                          isDir.boolValue else {
                        continue
                    }

                    if let appInfo = try parseAppBundle(at: bundlePath) {
                        apps.append(appInfo)
                    }
                }
            } catch {
                // Continue scanning other directories if one fails
                continue
            }
        }

        guard !apps.isEmpty else {
            throw AppDiscoveryError.noAppsFound
        }

        // Sort alphabetically by display name
        return apps.sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Private Methods

    /// Parses an individual app bundle
    private func parseAppBundle(at bundlePath: String) throws -> AppInfo? {
        let fileManager = FileManager.default

        // Resolve symlinks
        let resolvedPath: String
        do {
            resolvedPath = try fileManager.destinationOfSymbolicLink(atPath: bundlePath)
        } catch {
            resolvedPath = bundlePath
        }

        // Look for .app bundles inside
        var appBundlePath = resolvedPath

        if !resolvedPath.hasSuffix(".app") {
            // Find .app bundle inside directory
            let contents = try fileManager.contentsOfDirectory(atPath: resolvedPath)
            if let appFolder = contents.first(where: { $0.hasSuffix(".app") }) {
                appBundlePath = (resolvedPath as NSString).appendingPathComponent(appFolder)
            } else {
                return nil
            }
        }

        // Read Info.plist
        let infoPlistPath = (appBundlePath as NSString).appendingPathComponent("Info.plist")
        guard let infoPlist = NSDictionary(contentsOfFile: infoPlistPath) else {
            throw AppDiscoveryError.infoPlistNotFound
        }

        // Extract required information
        guard let bundleID = infoPlist["CFBundleIdentifier"] as? String else {
            throw AppDiscoveryError.corruptedMetadata
        }

        let displayName = (infoPlist["CFBundleDisplayName"] ?? infoPlist["CFBundleName"] ?? "Unknown") as? String ?? "Unknown"
        let version = (infoPlist["CFBundleShortVersionString"] ?? "1.0") as? String ?? "1.0"
        let minimumOS = infoPlist["MinimumOSVersion"] as? String
        let executable = (infoPlist["CFBundleExecutable"] ?? bundleID) as? String ?? bundleID

        // Calculate bundle size
        let bundleSize = calculateDirectorySize(at: appBundlePath)

        // Try to find app icon
        let iconPath = extractAppIcon(from: appBundlePath)

        let appInfo = AppInfo(
            bundleID: bundleID,
            displayName: displayName,
            version: version,
            bundlePath: appBundlePath,
            minimumOSVersion: minimumOS,
            executable: executable
        )

        var app = appInfo
        app.bundleSize = bundleSize
        app.iconPath = iconPath

        return app
    }

    /// Calculates total directory size
    private func calculateDirectorySize(at path: String) -> Int64 {
        let fileManager = FileManager.default
        var size: Int64 = 0

        if let enumerator = fileManager.enumerator(atPath: path) {
            for file in enumerator {
                let filePath = (path as NSString).appendingPathComponent(file as? String ?? "")
                if let attributes = try? fileManager.attributesOfItem(atPath: filePath),
                   let fileSize = attributes[.size] as? NSNumber {
                    size += fileSize.int64Value
                }
            }
        }

        return size
    }

    /// Extracts app icon path from bundle
    private func extractAppIcon(from bundlePath: String) -> String? {
        let fileManager = FileManager.default
        let assetCatalogPath = (bundlePath as NSString).appendingPathComponent("Assets.car")

        if fileManager.fileExists(atPath: assetCatalogPath) {
            return assetCatalogPath
        }

        // Look for common icon files
        let iconPatterns = ["AppIcon", "Icon", "icon"]
        let bundleContents = try? fileManager.contentsOfDirectory(atPath: bundlePath)

        for pattern in iconPatterns {
            if let icon = bundleContents?.first(where: { $0.contains(pattern) }) {
                let iconPath = (bundlePath as NSString).appendingPathComponent(icon)
                if fileManager.fileExists(atPath: iconPath) {
                    return iconPath
                }
            }
        }

        return nil
    }
}
