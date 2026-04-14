import Foundation

// MARK: - Data Models for Installed Apps

struct AppInfo: Identifiable, Codable {
    let id: UUID = UUID()
    let bundleID: String
    let displayName: String
    let version: String
    let bundlePath: String
    let minimumOSVersion: String?
    let executable: String

    // Computed properties
    var bundleSize: Int64 = 0
    var iconPath: String?

    enum CodingKeys: String, CodingKey {
        case bundleID, displayName, version, bundlePath
        case minimumOSVersion, executable, bundleSize, iconPath
    }
}

// MARK: - Extraction Progress State

struct ExtractionProgress {
    var totalBytes: Int64 = 0
    var processedBytes: Int64 = 0
    var currentFile: String = ""
    var isCompleted: Bool = false
    var isCancelled: Bool = false
    var error: String?

    var percentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(processedBytes) / Double(totalBytes)
    }
}

// MARK: - App Discovery Errors

enum AppDiscoveryError: LocalizedError {
    case noAppsFound
    case directoryAccessDenied
    case invalidBundleStructure
    case infoPlistNotFound
    case corruptedMetadata
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .noAppsFound:
            return "No installed apps found on device"
        case .directoryAccessDenied:
            return "Unable to access applications directory"
        case .invalidBundleStructure:
            return "Invalid app bundle structure detected"
        case .infoPlistNotFound:
            return "App configuration file (Info.plist) not found"
        case .corruptedMetadata:
            return "App metadata is corrupted or unreadable"
        case .permissionDenied:
            return "Permission denied accessing app data"
        }
    }
}

// MARK: - Extraction Errors

enum ExtractionError: LocalizedError {
    case insufficientStorage
    case permissionDenied
    case fileAlreadyExists
    case zipCreationFailed
    case sourceBundleNotFound
    case tempDirectoryCreationFailed
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .insufficientStorage:
            return "Insufficient storage space available"
        case .permissionDenied:
            return "Permission denied during extraction"
        case .fileAlreadyExists:
            return "IPA file already exists at destination"
        case .zipCreationFailed:
            return "Failed to create IPA archive"
        case .sourceBundleNotFound:
            return "Source app bundle not found"
        case .tempDirectoryCreationFailed:
            return "Failed to create temporary directory"
        case .unknownError(let message):
            return "Extraction failed: \(message)"
        }
    }
}
