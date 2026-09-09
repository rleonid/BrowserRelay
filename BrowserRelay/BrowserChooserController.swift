import AppKit
import SwiftUI

@MainActor
final class BrowserChooserController: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show(urls: [URL], browsers: [Browser], selectedID: String? = nil, onPick: @escaping (Browser) -> Void) {
        guard !browsers.isEmpty else {
            NSAlert(error: NSError(domain: "BrowserRelay", code: 1, userInfo: [NSLocalizedDescriptionKey: "No supported browsers were found."])).runModal()
            return
        }
        let view = BrowserChooserView(urlCount: urls.count, browsers: browsers, selectedID: selectedID) { [weak self] browser in
            self?.window?.close()
            onPick(browser)
        }
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 420, height: 0), styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
        panel.title = urls.isEmpty ? "Choose Active Browser" : "Open Link In"
        panel.contentView = NSHostingView(rootView: view)
        panel.isReleasedWhenClosed = false
        panel.center()
        panel.delegate = self
        window = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
}

private struct BrowserChooserView: View {
    let urlCount: Int
    let browsers: [Browser]
    let selectedID: String?
    let onPick: (Browser) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(urlCount == 0 ? "Which browser should be active?" : "Where should this link open?")
                .font(.headline)
            if urlCount > 1 { Text("\(urlCount) links will open together.").foregroundStyle(.secondary) }
            ForEach(browsers) { browser in
                Button { onPick(browser) } label: {
                    HStack(spacing: 12) {
                        Image(nsImage: browser.icon).resizable().frame(width: 28, height: 28)
                        Text(browser.name)
                        Spacer()
                        if browser.id == selectedID { Image(systemName: "checkmark").foregroundStyle(.tint) }
                    }.padding(.vertical, 4)
                }.buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
