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

# Check if patch is already applied
if patch -p1 --dry-run < "../../$PATCH_FILE" > /dev/null 2>&1; then
  # Patch can be applied (not yet applied)
  patch -p1 < "../../$PATCH_FILE"
  echo "Patch applied successfully"
else
  # Patch cannot be applied - check if it's already applied or failed
  if patch -p1 -R --dry-run < "../../$PATCH_FILE" > /dev/null 2>&1; then
    echo "Patch already applied, skipping"
  else
    echo "::warning file=$PATCH_FILE,title=Patch Application Failed::Patch cannot be applied and is not already applied. Build will continue but may have issues."
    echo "Warning: Patch cannot be applied and is not already applied"
  fi
fi

cd ../..
