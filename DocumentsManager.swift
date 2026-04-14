import Foundation

// MARK: - Documents Manager

class DocumentsManager {
    private let fileManager = FileManager.default

    // MARK: - Public Properties

    static let shared = DocumentsManager()

    var documentsDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    var extractedIPAsDirectory: URL {
        let ipaDirectory = documentsDirectory.appendingPathComponent("ExtractedIPAs", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: ipaDirectory.path) {
            try? fileManager.createDirectory(at: ipaDirectory, withIntermediateDirectories: true, attributes: nil)
        }

        return ipaDirectory
    }

    // MARK: - Public Methods

    /// Gets available storage space in bytes
    func getAvailableSpace() -> Int64 {
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: documentsDirectory.path)
            if let freeSize = attributes[.systemFreeSize] as? NSNumber {
                return freeSize.int64Value
            }
        } catch {
            return -1
        }
        return -1
    }

    /// Checks if there's enough space for a file
    func hasEnoughSpace(for size: Int64) -> Bool {
        return getAvailableSpace() > size
    }

    /// Lists all extracted IPAs
    func listExtractedIPAs() -> [URL] {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: extractedIPAsDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            return contents.filter { $0.pathExtension.lowercased() == "ipa" }
        } catch {
            return []
        }
    }

    /// Gets file size in bytes
    func getFileSize(at url: URL) -> Int64 {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? NSNumber {
                return size.int64Value
            }
        } catch {
            return 0
        }
        return 0
    }

    /// Formats bytes to human readable size
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Deletes an IPA file
    func deleteIPA(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    /// Gets unique filename with conflict resolution
    func getUniqueFileName(_ originalName: String) -> String {
        let destinationPath = extractedIPAsDirectory.appendingPathComponent(originalName).path

        guard fileManager.fileExists(atPath: destinationPath) else {
            return originalName
        }

        let fileNameWithoutExtension = (originalName as NSString).deletingPathExtension
        let fileExtension = (originalName as NSString).pathExtension

        var counter = 1
        var newName = "\(fileNameWithoutExtension) (\(counter)).\(fileExtension)"
        var newPath = extractedIPAsDirectory.appendingPathComponent(newName).path

        while fileManager.fileExists(atPath: newPath) {
            counter += 1
            newName = "\(fileNameWithoutExtension) (\(counter)).\(fileExtension)"
            newPath = extractedIPAsDirectory.appendingPathComponent(newName).path
        }

        return newName
    }
}
