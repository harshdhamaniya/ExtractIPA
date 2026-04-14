import SwiftUI

@main
struct ExtractIPAApp: App {
    @StateObject private var appListViewModel = AppListViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appListViewModel)
        }
    }
}
