#!/bin/zsh
# Build and safely redeploy Browser Relay to /Applications.
# Usage: ./scripts/redeploy-browser-relay.sh [--no-launch]

set -euo pipefail

script_dir=${0:A:h}
repo_root=${script_dir:h}
build_dir="$repo_root/.build/redeploy"
app_name="BrowserRelay.app"
built_app="$build_dir/Build/Products/Release/$app_name"
installed_app="/Applications/$app_name"
launch_after_install=true

if [[ ${1:-} == "--no-launch" ]]; then
  launch_after_install=false
elif [[ $# -ne 0 ]]; then
  print -u2 "Usage: $0 [--no-launch]"
  exit 64
fi

print "Building Browser Relay (Release)…"
rm -rf "$build_dir"
xcodebuild \
  -project "$repo_root/BrowserRelay.xcodeproj" \
  -scheme BrowserRelay \
  -configuration Release \
  -derivedDataPath "$build_dir" \
  build \
  CODE_SIGNING_ALLOWED=NO

if [[ ! -d "$built_app" ]]; then
  print -u2 "Build did not produce $built_app"
  exit 1
fi

# This is suitable for local/private deployment. Public distribution should use
# a Developer ID certificate and notarization instead.
codesign --force --deep --sign - "$built_app"
codesign --verify --deep --strict "$built_app"

# /Applications is protected. Prompt once before moving the current version.
sudo -v
backup_dir=$(mktemp -d /private/tmp/browser-relay-backup.XXXXXX)
backup_app="$backup_dir/$app_name"

# The installed app is intentionally a single instance. Quit it before the
# bundle swap so `open` starts the newly installed executable, not the old one.
if pgrep -x BrowserRelay >/dev/null 2>&1; then
  print "Quitting the currently running Browser Relay…"
  osascript -e 'tell application id "com.local.browserrelay" to quit' || true
  for _ in {1..20}; do
    pgrep -x BrowserRelay >/dev/null 2>&1 || break
    sleep 0.2
  done
  if pgrep -x BrowserRelay >/dev/null 2>&1; then
    print -u2 "Browser Relay is still running. Quit it, then run this script again."
    exit 1
  fi
fi

if [[ -d "$installed_app" ]]; then
  print "Saving the current app to $backup_app"
  sudo mv "$installed_app" "$backup_app"
fi

if ! sudo ditto "$built_app" "$installed_app"; then
  print -u2 "Installation failed. Restoring the previous app."
  if [[ -d "$backup_app" ]]; then
    sudo mv "$backup_app" "$installed_app"
  fi
  exit 1
fi

print "Installed: $installed_app"
if [[ -d "$backup_app" ]]; then
  print "Previous version backup: $backup_app"
fi

if $launch_after_install; then
  open -a "$installed_app"
fi
