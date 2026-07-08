import Foundation
import Sparkle

@MainActor
final class UpdateController: ObservableObject {
    private let controller: SPUStandardUpdaterController
    @Published private(set) var isConfigured = false

    init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        if let feed = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String,
           let url = URL(string: feed),
           url.scheme?.lowercased() == "https",
           Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String != nil {
            controller.startUpdater()
            isConfigured = true
        }
    }

    var currentVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }

    var canCheckForUpdates: Bool { isConfigured && controller.updater.canCheckForUpdates }

    var statusText: String {
        isConfigured ? "Signed automatic updates are enabled." : "Add a signed update feed when publishing."
    }

    var automaticallyChecks: Bool {
        get { isConfigured && controller.updater.automaticallyChecksForUpdates }
        set { if isConfigured { controller.updater.automaticallyChecksForUpdates = newValue; objectWillChange.send() } }
    }

    var automaticallyDownloads: Bool {
        get { isConfigured && controller.updater.automaticallyDownloadsUpdates }
        set { if isConfigured { controller.updater.automaticallyDownloadsUpdates = newValue; objectWillChange.send() } }
    }

    func checkForUpdates() {
        guard isConfigured else { return }
        controller.checkForUpdates(nil)
    }
}
