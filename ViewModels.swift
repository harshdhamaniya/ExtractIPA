import Foundation
import SwiftUI

// MARK: - App List ViewModel

@MainActor
class AppListViewModel: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""

    private let appLister = AppLister()

    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return apps
        }
        return apps.filter { app in
            app.displayName.localizedCaseInsensitiveContains(searchText) ||
                app.bundleID.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Public Methods

    func loadApps() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let discoveredApps = try await appLister.listInstalledApps()
            DispatchQueue.main.async {
                self.apps = discoveredApps
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Extraction ViewModel

@MainActor
class ExtractionViewModel: ObservableObject {
    @Published var selectedApp: AppInfo?
    @Published var progress = ExtractionProgress()
    @Published var isExtracting = false
    @Published var isCompleted = false
    @Published var extractedFileURL: URL?
    @Published var errorMessage: String?

    private let extractor = IPAExtractor()
    private let documentsManager = DocumentsManager.shared
    private var extractionTask: Task<Void, Never>?

    // MARK: - Public Methods

    func extractIPA(for app: AppInfo) {
        self.selectedApp = app
        self.isExtracting = true
        self.progress = ExtractionProgress()
        self.errorMessage = nil
        self.isCompleted = false

        extractionTask = Task {
            do {
                // Check storage space
                guard documentsManager.hasEnoughSpace(for: app.bundleSize) else {
                    self.errorMessage = ExtractionError.insufficientStorage.localizedDescription
                    self.isExtracting = false
                    return
                }

                // Start extraction
                let ipaURL = try await extractor.extractIPA(
                    from: app,
                    to: documentsManager.extractedIPAsDirectory
                ) { progress in
                    DispatchQueue.main.async {
                        self.progress = progress
                    }
                }

                self.extractedFileURL = ipaURL
                self.isCompleted = true
            } catch {
                self.errorMessage = error.localizedDescription
            }

            self.isExtracting = false
        }
    }

    func cancelExtraction() {
        extractionTask?.cancel()
        isExtracting = false
        errorMessage = "Extraction cancelled by user"
    }

    func resetState() {
        selectedApp = nil
        progress = ExtractionProgress()
        isExtracting = false
        isCompleted = false
        extractedFileURL = nil
        errorMessage = nil
        extractionTask?.cancel()
    }

    func openExtractedIPA() {
        guard let url = extractedFileURL else { return }

        #if os(iOS)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}
