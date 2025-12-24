#!/bin/bash
set -e

PLATFORM="${1:-macos}"

if [ "$PLATFORM" != "macos" ] && [ "$PLATFORM" != "ios" ]; then
  echo "Usage: $0 [macos|ios]"
  exit 1
fi

PATCH_FILE="patches/macios/macios.patch"

if [ ! -f "$PATCH_FILE" ]; then
  echo "Warning: Patch file not found: $PATCH_FILE"
  exit 0
fi

cd .cache/mpv

patch -p1 < "../../$PATCH_FILE"
echo "Patch applied successfully"

cd ../..
