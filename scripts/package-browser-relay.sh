#!/bin/zsh
# Build a portable, ad-hoc-signed Browser Relay ZIP.
# Usage: ./scripts/package-browser-relay.sh [version]

set -euo pipefail

script_dir=${0:A:h}
repo_root=${script_dir:h}
version=${1:-dev}
build_dir="$repo_root/.build/release"
dist_dir="$repo_root/dist"
app_path="$build_dir/Build/Products/Release/BrowserRelay.app"
archive_name="BrowserRelay-${version}-macOS.zip"

rm -rf "$build_dir"
mkdir -p "$dist_dir"

xcodebuild \
  -project "$repo_root/BrowserRelay.xcodeproj" \
  -scheme BrowserRelay \
  -configuration Release \
  -derivedDataPath "$build_dir" \
  build \
  CODE_SIGNING_ALLOWED=NO

if [[ ! -d "$app_path" ]]; then
  print -u2 "Build completed without producing BrowserRelay.app."
  exit 1
fi

# Ad-hoc signing gives the bundle a consistent local signature. It is not an
# Apple Developer ID signature and does not replace notarization.
codesign --force --deep --sign - "$app_path"
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$dist_dir/$archive_name"

print "Created: $dist_dir/$archive_name"
print "SHA-256: $(shasum -a 256 "$dist_dir/$archive_name" | awk '{print $1}')"
