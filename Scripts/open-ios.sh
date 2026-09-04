#!/usr/bin/env bash
# Generates and opens the Nuke Unit Tracker Xcode project without Homebrew.
# Run from the repository root with: bash Scripts/open-ios.sh

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Xcode is required. Install Xcode from the App Store, open it once, then run this script again."
  exit 1
fi

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
else
  xcodegen_version="2.46.0"
  xcodegen_cache="$HOME/Library/Caches/NukeUnitTracker/XcodeGen-$xcodegen_version"

  if [[ ! -d "$xcodegen_cache/.git" ]]; then
    mkdir -p "$(dirname "$xcodegen_cache")"
    git clone --depth 1 --branch "$xcodegen_version" https://github.com/yonaskolb/XcodeGen.git "$xcodegen_cache"
  fi

  swift run --package-path "$xcodegen_cache" xcodegen generate
fi

open "$project_root/NukeUnitTracker.xcodeproj"
