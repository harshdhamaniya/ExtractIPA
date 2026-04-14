// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ExtractIPA",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ExtractIPA",
            targets: ["ExtractIPA"]
        )
    ],
    targets: [
        .target(
            name: "ExtractIPA",
            dependencies: [],
            path: "Sources",
            sources: [
                "ExtractIPAApp.swift",
                "Models.swift",
                "AppLister.swift",
                "IPAExtractor.swift",
                "DocumentsManager.swift",
                "ViewModels.swift",
                "ContentView.swift"
            ]
        )
    ]
)
