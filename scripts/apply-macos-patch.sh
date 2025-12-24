#!/bin/bash
set -e

PLATFORM="${1:-macos}"

if [ "$PLATFORM" != "macos" ] && [ "$PLATFORM" != "ios" ]; then
  echo "Usage: $0 [macos|ios]"
  exit 1
fi

PATCH_FILE="patches/macios.patch"

if [ ! -f "$PATCH_FILE" ]; then
  echo "Warning: Patch file not found: $PATCH_FILE"
  exit 0
fi

cd .cache/mpv

# Check if patch is already applied
if git apply --check "../../$PATCH_FILE" 2>/dev/null; then
  echo "Applying macOS/iOS patch..."
  git apply "../../$PATCH_FILE"
  echo "Patch applied successfully"
else
  echo "Patch already applied or cannot be applied"
fi

for i in meson.build meson.options
do
    echo "Patched $i"
    cat $i ||true
    echo -e "\n\n\n"
done

cd ../..
