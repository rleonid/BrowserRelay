import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var router: BrowserRouter
    @State private var showDefaultConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Browser Relay").font(.largeTitle.weight(.semibold))
            Text("A small default-browser router for project-separated browsing.")
                .foregroundStyle(.secondary)

            GroupBox("Link routing") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("When macOS opens a web link", selection: $router.routingMode) {
                        ForEach(BrowserRouter.RoutingMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Active browser", selection: $router.activeBrowserID) {
                        ForEach(router.browsers) { browser in Text(browser.name).tag(Optional(browser.id)) }
                    }
                    Button("Refresh Browsers") { router.refreshBrowsers() }
                }.padding(.vertical, 4)
            }

            GroupBox("Keyboard shortcut") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Press ⌘⇧B anywhere to choose the active browser.")
                    Text("The selected browser is used automatically when “Use active browser” is selected above.")
                        .foregroundStyle(.secondary)
                }.padding(.vertical, 4)
            }

            GroupBox("System default browser") {
                VStack(alignment: .leading, spacing: 10) {
                    Label(router.isSystemDefault ? "Browser Relay is your default browser." : "Browser Relay is not your default browser.", systemImage: router.isSystemDefault ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .foregroundStyle(router.isSystemDefault ? .green : .secondary)
                    HStack {
                        Button("Make Browser Relay My Default") { showDefaultConfirmation = true }
                        Button("Check Again") { router.refreshDefaultStatus() }
                    }
                    if let error = router.defaultSetupError {
                        Text(error).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
                    }
                    Text("This makes Browser Relay receive web links, then it forwards each one to the browser you select.")
                        .foregroundStyle(.secondary)
                }.padding(.vertical, 4)
            }
        }
        .padding(24)
        .frame(width: 560)
        .alert("Make Browser Relay your default browser?", isPresented: $showDefaultConfirmation) {
            Button("Make Default") { router.makeSystemDefault() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Browser Relay will handle http and https links, then route them to your chosen browser.")
        }
    }
}
