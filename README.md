# Browser Relay

A native macOS URL router for people who keep separate projects in separate browsers.

## What it does

- Claims `http` and `https` links when selected as the macOS default browser.
- Prompts for the destination browser, or forwards directly to the saved **active browser**.
- Finds Safari, Chrome (and Canary), Brave, DuckDuckGo, Firefox, Arc, Edge, Vivaldi, and Orion.
- Registers `Command-Shift-B` globally to change the active browser without leaving your current app.

## Run it

Open `BrowserRelay.xcodeproj` in Xcode, select the **BrowserRelay** scheme, and Run. Use **Make Browser Relay My Default** in the app and accept macOS’s confirmation. You can also select it in **System Settings → Desktop & Dock → Default web browser**.

The app has no network access and does not inspect URLs beyond their scheme; it simply hands each received URL to the browser you choose.

## Test the installed app

With the app installed in `/Applications` and set as the default browser, run:

```zsh
./scripts/test-browser-relay.sh
```

The script confirms the handler that macOS will use, then opens a fresh `https` URL through the same default-browser path used by `open`, CLI login flows, and other applications. Browser Relay does **not** need to be running beforehand.

## Package for another Mac

Build a shareable ZIP from a Mac with Xcode installed:

```zsh
./scripts/package-browser-relay.sh 1.0.0
```

This creates `dist/BrowserRelay-1.0.0-macOS.zip` and prints its SHA-256 checksum. The recipient unzips it, moves `BrowserRelay.app` to `/Applications`, opens it once, and uses the app’s **Make Browser Relay My Default** button.

The generated ZIP is **ad-hoc signed**, which is appropriate for trusted personal/internal sharing. On another Mac, Gatekeeper may require the recipient to Control-click the app and choose **Open** the first time. For public distribution without that warning, enroll in the Apple Developer Program and sign with a Developer ID certificate and notarize the release.

## GitHub releases

Pushing a tag such as `v1.0.0` triggers the included GitHub Actions workflow. It packages an ad-hoc-signed ZIP and attaches it to a GitHub Release.

## Notes

`Command-Shift-B` is deliberately a fixed shortcut in this first version. If another app owns it, macOS will leave that app’s shortcut in place. The app’s main window always offers the same browser selection.
