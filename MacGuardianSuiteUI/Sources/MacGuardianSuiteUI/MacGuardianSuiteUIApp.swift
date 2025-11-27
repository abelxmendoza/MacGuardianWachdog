import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct MacGuardianSuiteUIApp: App {
    @StateObject private var workspace = WorkspaceState()

    init() {
        #if os(macOS)
        // Configure NSApplication for proper app behavior
        NSApplication.shared.setActivationPolicy(.regular)
        
        // Ensure app appears in Dock and can be activated
        if NSApp.activationPolicy() == .accessory {
            NSApp.setActivationPolicy(.regular)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workspace)
                .onAppear {
                    #if os(macOS)
                    // Activate the app to bring it to front
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    #endif
                    
                    // Initialize EventPipeline to start listening for events
                    _ = EventPipeline.shared
                    // Start LiveUpdateService for real-time WebSocket events
                    LiveUpdateService.shared.start()
                }
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
