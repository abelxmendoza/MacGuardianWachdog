import SwiftUI

@main
struct MacGuardianSuiteUIApp: App {
    @StateObject private var workspace = WorkspaceState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workspace)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
