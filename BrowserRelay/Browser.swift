import AppKit
import Foundation

struct Browser: Identifiable, Hashable {
    let bundleIdentifier: String
    let name: String
    let appURL: URL

    var id: String { bundleIdentifier }
    var icon: NSImage { NSWorkspace.shared.icon(forFile: appURL.path) }
}

@MainActor
final class BrowserRouter: ObservableObject {
    enum RoutingMode: String, CaseIterable, Identifiable {
        case ask = "Ask every time"
        case active = "Use active browser"
        var id: String { rawValue }
    }

    @Published private(set) var browsers: [Browser] = []
    @Published var activeBrowserID: String? { didSet { save() } }
    @Published var routingMode: RoutingMode { didSet { save() } }
    @Published private(set) var isSystemDefault = false
    @Published private(set) var defaultSetupError: String?

    private let activeKey = "activeBrowserID"
    private let modeKey = "routingMode"
    private let chooser = BrowserChooserController()

    init() {
        activeBrowserID = UserDefaults.standard.string(forKey: activeKey)
        routingMode = RoutingMode(rawValue: UserDefaults.standard.string(forKey: modeKey) ?? "") ?? .ask
        refreshBrowsers()
        refreshDefaultStatus()
    }

    var activeBrowser: Browser? { browsers.first { $0.id == activeBrowserID } }

    func refreshBrowsers() {
        let candidates: [(String, String)] = [
            ("com.apple.Safari", "Safari"),
            ("com.google.Chrome", "Google Chrome"),
            ("com.google.Chrome.canary", "Chrome Canary"),
            ("com.brave.Browser", "Brave"),
            ("com.duckduckgo.macos.browser", "DuckDuckGo"),
            ("org.mozilla.firefox", "Firefox"),
            ("company.thebrowser.Browser", "Arc"),
            ("com.microsoft.edgemac", "Microsoft Edge"),
            ("com.vivaldi.Vivaldi", "Vivaldi"),
            ("com.kagi.kagimacOS", "Orion")
        ]

        browsers = candidates.compactMap { id, fallbackName in
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return nil }
            let name = (Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                ?? (Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String)
                ?? fallbackName
            return Browser(bundleIdentifier: id, name: name, appURL: url)
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if activeBrowser == nil { activeBrowserID = browsers.first?.id }
    }

    func route(urls: [URL]) {
        let webURLs = urls.filter { ["http", "https"].contains($0.scheme?.lowercased() ?? "") }
        guard !webURLs.isEmpty else { return }
        if routingMode == .active, let browser = activeBrowser {
            open(webURLs, in: browser)
        } else {
            chooser.show(urls: webURLs, browsers: browsers, onPick: { [weak self] browser in
                self?.open(webURLs, in: browser)
            })
        }
    }

    func chooseActiveBrowser() {
        refreshBrowsers()
        chooser.show(urls: [], browsers: browsers, selectedID: activeBrowserID, onPick: { [weak self] browser in
            self?.activeBrowserID = browser.id
        })
    }

    func open(_ urls: [URL], in browser: Browser) {
        activeBrowserID = browser.id
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        for url in urls {
            NSWorkspace.shared.open([url], withApplicationAt: browser.appURL, configuration: configuration)
        }
    }

    /// macOS presents its own confirmation before changing the default handler.
    func makeSystemDefault() {
        defaultSetupError = nil
        Task {
            do {
                try await NSWorkspace.shared.setDefaultApplication(
                    at: Bundle.main.bundleURL,
                    toOpenURLsWithScheme: "http"
                )
                refreshDefaultStatus()
            } catch {
                defaultSetupError = "macOS could not make Browser Relay the default browser: \(error.localizedDescription)"
            }
        }
    }

    func refreshDefaultStatus() {
        guard let testURL = URL(string: "https://example.com"),
              let applicationURL = NSWorkspace.shared.urlForApplication(toOpen: testURL) else {
            isSystemDefault = false
            return
        }
        isSystemDefault = applicationURL.standardizedFileURL == Bundle.main.bundleURL.standardizedFileURL
    }

    private func save() {
        UserDefaults.standard.set(activeBrowserID, forKey: activeKey)
        UserDefaults.standard.set(routingMode.rawValue, forKey: modeKey)
    }
}
