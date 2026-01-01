#!/bin/bash
set -e

ARCH="${1:-aarch64}"

# Setup shaderc for iOS (must run before cd to .cache/mpv)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/setup-shaderc.sh" ]; then
  echo "Setting up shaderc for iOS..."
  "${SCRIPT_DIR}/setup-shaderc.sh"
fi

cd .cache/mpv

grep moltenvk meson.build || (cd ../../ && ./scripts/common/apply-macos-patch.sh)

  # -Dcoreaudio=disabled \
meson setup "build/ios/${ARCH}" \
  --default-library=static \
  --buildtype=release \
  -Dwrap_mode=forcefallback \
  -Dcoreaudio=disabled \
  -Dlibmpv=true \
  -Dcplayer=false \
  -Dtests=false \
  -Dswift-flags='-target arm64-apple-ios' \
  -Dcocoa=disabled \
  -Dios-gl=disabled \
  -Davfoundation=disabled \
  -Dgpl=true \
  -Dmoltenvk=enabled \
  -Dharfbuzz:icu=disabled \
  -Dlibass:require-system-font-provider=false \
  -Dlibplacebo:shaderc=enabled \
  -Dlibplacebo:lcms=disabled \
  -DFFmpeg:gpl=enabled \
  -DFFmpeg:version3=enabled \
  -DFFmpeg:mbedtls=enabled \
  -DFFmpeg:tls_protocol=enabled \
  -DFFmpeg:tests=disabled \
  --cross-file ../../ios-cross.txt \
  --prefix="$(pwd)/../prefix/ios/${ARCH}"

echo "iOS build configured for ${ARCH}"
