import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let router = BrowserRouter()
    private var hotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotKey = GlobalHotKey { [weak self] in self?.router.chooseActiveBrowser() }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        router.route(urls: urls)
    }
}
