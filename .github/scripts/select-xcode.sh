#!/usr/bin/env bash
# Switch the CI runner to the newest stable Xcode it has installed.
# Runner images ship several Xcode versions and the default is often not the newest.
set -euo pipefail

newest=$(ls -d /Applications/Xcode_*.app 2>/dev/null \
  | grep -viE 'beta|release_candidate|_rc' \
  | sort -V | tail -n 1 || true)

if [ -n "$newest" ]; then
  sudo xcode-select -s "$newest/Contents/Developer"
fi

xcodebuild -version
swift --version
