import SwiftUI

// MARK: - Main ContentView

struct ContentView: View {
    @EnvironmentObject var appListViewModel: AppListViewModel
    @State private var showDeveloperInfo = false

    var body: some View {
        NavigationStack {
            AppListView()
                .navigationTitle("Extract IPA")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showDeveloperInfo = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 16))
                        }
                    }
                }
        }
        .sheet(isPresented: $showDeveloperInfo) {
            DeveloperInfoView(isPresented: $showDeveloperInfo)
        }
        .task {
            await appListViewModel.loadApps()
        }
    }
}

// MARK: - App List View

struct AppListView: View {
    @EnvironmentObject var appListViewModel: AppListViewModel
    @State private var selectedApp: AppInfo?

    var body: some View {
        ZStack {
            if appListViewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5, anchor: .center)
                    Text("Discovering installed apps...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = appListViewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Error")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button(action: {
                        Task {
                            await appListViewModel.loadApps()
                        }
                    }) {
                        Text("Retry")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            } else if appListViewModel.filteredApps.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No Apps Found")
                        .font(.headline)
                    if !appListViewModel.searchText.isEmpty {
                        Text("No apps match your search")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(appListViewModel.filteredApps) { app in
                        NavigationLink(destination: AppDetailView(app: app)) {
                            AppListCell(app: app)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .searchable(
            text: $appListViewModel.searchText,
            prompt: "Search apps"
        )
        .refreshable {
            await appListViewModel.loadApps()
        }
    }
}

// MARK: - App List Cell

struct AppListCell: View {
    let app: AppInfo
    @State private var appIcon: Image?

    var body: some View {
        HStack(spacing: 12) {
            // App Icon Placeholder
            Image(systemName: "app.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(app.displayName)
                    .font(.headline)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 2) {
                    Text("v\(app.version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(app.bundleID)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(DocumentsManager.shared.formatBytes(app.bundleSize))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - App Detail View

struct AppDetailView: View {
    let app: AppInfo
    @StateObject private var extractionViewModel = ExtractionViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // App Header
                    HStack(spacing: 16) {
                        Image(systemName: "app.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(app.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(app.bundleID)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // App Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Version", value: app.version)
                        DetailRow(label: "Bundle ID", value: app.bundleID)
                        DetailRow(label: "Size", value: DocumentsManager.shared.formatBytes(app.bundleSize))
                        if let minOS = app.minimumOSVersion {
                            DetailRow(label: "Minimum iOS", value: minOS)
                        }
                        DetailRow(label: "Executable", value: app.executable)
                    }

                    Spacer()
                }
                .padding()
            }

            // Action Buttons
            VStack(spacing: 12) {
                if extractionViewModel.isExtracting {
                    ExtractionProgressView(viewModel: extractionViewModel)
                } else if extractionViewModel.isCompleted {
                    SuccessView(viewModel: extractionViewModel)
                        .onDisappear {
                            extractionViewModel.resetState()
                        }
                } else if let errorMessage = extractionViewModel.errorMessage {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.callout)
                                .lineLimit(2)
                        }
                        .padding()
                        .background(Color(.systemRed).opacity(0.1))
                        .cornerRadius(8)

                        Button(action: {
                            extractionViewModel.resetState()
                        }) {
                            Text("Try Again")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                } else {
                    Button(action: {
                        extractionViewModel.extractIPA(for: app)
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.doc")
                            Text("Extract IPA")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("App Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Detail Row Component

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Extraction Progress View

struct ExtractionProgressView: View {
    @ObservedObject var viewModel: ExtractionViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Extracting...")
                        .font(.headline)
                    Text(viewModel.progress.currentFile)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(Int(viewModel.progress.percentage * 100))%")
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            ProgressView(value: viewModel.progress.percentage)
                .tint(.blue)

            HStack(spacing: 12) {
                Text(DocumentsManager.shared.formatBytes(viewModel.progress.processedBytes))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(DocumentsManager.shared.formatBytes(viewModel.progress.totalBytes))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(role: .destructive, action: {
                viewModel.cancelExtraction()
            }) {
                Text("Cancel Extraction")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding()
    }
}

// MARK: - Success View

struct SuccessView: View {
    @ObservedObject var viewModel: ExtractionViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Extraction Successful!")
                        .font(.headline)
                    if let fileName = viewModel.extractedFileURL?.lastPathComponent {
                        Text(fileName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemGreen).opacity(0.1))
            .cornerRadius(8)

            HStack(spacing: 12) {
                Button(action: {
                    viewModel.openExtractedIPA()
                }) {
                    HStack {
                        Image(systemName: "folder")
                        Text("Open in Files")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button(action: {
                    viewModel.resetState()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Extract Another")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding()
    }
}

// MARK: - Developer Info View

struct DeveloperInfoView: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Developer Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)

                    VStack(spacing: 4) {
                        Text("Harsh Dhamaniya")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Mobile App Developer")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text("Developed with ❤️")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Social Links
                VStack(spacing: 12) {
                    Text("Connect With Me")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    SocialLinkButton(
                        icon: "link.circle.fill",
                        platform: "LinkedIn",
                        url: "https://www.linkedin.com/in/harshdhamaniya/",
                        color: .blue
                    )

                    SocialLinkButton(
                        icon: "globe",
                        platform: "GitHub",
                        url: "https://github.com/harshdhamaniya",
                        color: .black
                    )

                    SocialLinkButton(
                        icon: "camera.circle.fill",
                        platform: "Instagram",
                        url: "https://www.instagram.com/damnnharsh/",
                        color: .pink
                    )
                }
                .padding()

                // App Info
                VStack(spacing: 12) {
                    Text("About ExtractIPA")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "book.circle.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("A powerful tool for extracting IPA files from installed apps on jailbroken iOS devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "gear.circle.fill")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            Text("Built with Swift, SwiftUI, and modern iOS development practices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "lock.circle.fill")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("For personal backup, testing, and research purposes only")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding()

                Spacer()

                // Version Info
                VStack(spacing: 4) {
                    Text("Version 1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("© 2024 Harsh Dhamaniya")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: { isPresented = false })
                }
            }
        }
    }
}

// MARK: - Social Link Button Component

struct SocialLinkButton: View {
    let icon: String
    let platform: String
    let url: String
    let color: Color

    var body: some View {
        Link(destination: URL(string: url) ?? URL(fileURLWithPath: "")) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(platform)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("Open profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
