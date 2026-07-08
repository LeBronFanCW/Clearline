import SwiftUI

@main
struct ClearlineApp: App {
    @StateObject private var scanner = DeviceScanner()
    @StateObject private var updates = UpdateController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(scanner)
                .environmentObject(updates)
                .frame(minWidth: 880, minHeight: 620)
                .task { scanner.start() }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1040, height: 720)

        Settings {
            SettingsView()
                .environmentObject(updates)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { updates.checkForUpdates() }
                    .disabled(!updates.isConfigured || !updates.canCheckForUpdates)
            }
        }
    }
}
