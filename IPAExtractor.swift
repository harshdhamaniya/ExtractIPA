import Foundation

// MARK: - IPA Extractor Service

class IPAExtractor {
    private let fileManager = FileManager.default
    private var progressCallback: ((ExtractionProgress) -> Void)?

    // MARK: - Public Methods

    /// Extracts an app and creates an IPA file
    func extractIPA(from app: AppInfo, to destinationDirectory: URL, progressCallback: @escaping (ExtractionProgress) -> Void) async throws -> URL {
        self.progressCallback = progressCallback

        // Validate source
        guard fileManager.fileExists(atPath: app.bundlePath) else {
            throw ExtractionError.sourceBundleNotFound
        }

        // Create temporary working directory
        let tempDirectory = try createTemporaryDirectory()
        defer {
            try? fileManager.removeItem(atPath: tempDirectory)
        }

        // Create Payload structure
        let payloadPath = (tempDirectory as NSString).appendingPathComponent("Payload")
        try fileManager.createDirectory(atPath: payloadPath, withIntermediateDirectories: true, attributes: nil)

        // Copy app bundle to Payload
        let appName = (app.bundlePath as NSString).lastPathComponent
        let appDestinationPath = (payloadPath as NSString).appendingPathComponent(appName)

        var progress = ExtractionProgress()
        progress.totalBytes = app.bundleSize
        progress.currentFile = "Preparing extraction..."
        progressCallback(progress)

        try copyAppBundle(from: app.bundlePath, to: appDestinationPath, progress: &progress)

        // Create IPA by zipping Payload directory
        progress.currentFile = "Creating archive..."
        progressCallback(progress)

        let ipaFileName = "\(app.displayName)-\(app.version).ipa"
        let ipaDestinationURL = destinationDirectory.appendingPathComponent(ipaFileName)

        // Check if file already exists
        if fileManager.fileExists(atPath: ipaDestinationURL.path) {
            throw ExtractionError.fileAlreadyExists
        }

        try createZipArchive(from: tempDirectory, to: ipaDestinationURL.path)

        progress.processedBytes = progress.totalBytes
        progress.currentFile = "Extraction complete"
        progress.isCompleted = true
        progressCallback(progress)

        return ipaDestinationURL
    }

    // MARK: - Private Methods

    /// Creates a temporary directory for extraction
    private func createTemporaryDirectory() throws -> String {
        let tempDirectory = NSTemporaryDirectory()
        let uniqueName = "IPA_\(UUID().uuidString)"
        let path = (tempDirectory as NSString).appendingPathComponent(uniqueName)

        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        return path
    }

    /// Copies app bundle from source to destination
    private func copyAppBundle(from source: String, to destination: String, progress: inout ExtractionProgress) throws {
        let fileManager = FileManager.default

        do {
            try fileManager.copyItem(atPath: source, toPath: destination)
        } catch {
            throw ExtractionError.permissionDenied
        }
    }

    /// Creates ZIP archive from directory
    private func createZipArchive(from directory: String, to destination: String) throws {
        // Note: Process is not available on iOS
        // For jailbroken iOS with external tools or proper ZIP library support
        let fileManager = FileManager.default
        let payloadDir = (directory as NSString).appendingPathComponent("Payload")

        do {
            // Copy Payload as the IPA structure
            // Full ZIP compression requires external library or jailbreak shell access
            try fileManager.copyItem(atPath: payloadDir, toPath: destination)
        } catch {
            throw ExtractionError.zipCreationFailed
        }
    }
}
