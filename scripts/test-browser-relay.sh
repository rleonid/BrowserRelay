#!/bin/zsh
# Test Browser Relay through macOS's normal default-browser path.
# Usage: ./scripts/test-browser-relay.sh [URL]

set -euo pipefail

app_path="/Applications/BrowserRelay.app"
test_url="${1:-https://example.com/?browser-relay-test=$(date +%s)}"

if [[ ! -d "$app_path" ]]; then
  print -u2 "Browser Relay is not installed at $app_path"
  print -u2 "Build it in Xcode, then copy BrowserRelay.app to /Applications and run it once."
  exit 1
fi

# NSWorkspace is the same Launch Services API used by macOS to decide where
# `open https://…` goes. This does not launch Browser Relay by itself.
handler=$(swift -e '
import AppKit
let url = URL(string: "https://example.com")!
print(NSWorkspace.shared.urlForApplication(toOpen: url)?.path ?? "")
' 2>/dev/null)

if [[ "$handler" == "$app_path" ]]; then
  print "✓ Browser Relay is the current default web handler."
else
  print -u2 "Browser Relay is not the current default web handler."
  print -u2 "macOS currently resolves web links to: ${handler:-unknown}"
  print -u2 "Open /Applications/BrowserRelay.app and click ‘Make Browser Relay My Default’, then run this again."
  exit 2
fi

print "Opening $test_url"
print "If Browser Relay was not running, macOS should launch it now and show its browser picker."
open "$test_url"
