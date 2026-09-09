import SwiftUI

@main
struct BrowserRelayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Browser Relay") {
            ContentView()
                .environmentObject(appDelegate.router)
        }
        .windowResizability(.contentSize)
    }
}
