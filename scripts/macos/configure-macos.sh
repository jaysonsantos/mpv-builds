#!/bin/bash
set -ex

ARCH="${1:-aarch64}"

# Setup shaderc for macOS (must run before cd to .cache/mpv)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/setup-shaderc.sh" ]; then
  echo "Setting up shaderc for macOS..."
  "${SCRIPT_DIR}/setup-shaderc.sh"
fi

cd .cache/mpv

grep moltenvk meson.build || (cd ../../ && ./scripts/common/apply-macos-patch.sh)

meson setup "build/macos/${ARCH}" \
  --native-file ../../macos-native.txt \
  --default-library=shared \
  --buildtype=release \
  -Dwrap_mode=forcefallback \
  -Dlibmpv=true \
  -Dcplayer=false \
  -Dtests=false \
  -Dgpl=true \
  -Dmoltenvk=enabled \
  -Dlibplacebo:shaderc=enabled \
  -Dlibplacebo:lcms=enabled \
  -Dlibplacebo:vk-proc-addr=enabled \
  -Dharfbuzz:icu=disabled \
  -Dlibass:require-system-font-provider=false \
  -Dfreetype2:brotli=disabled \
  -DFFmpeg:gpl=enabled \
  -DFFmpeg:version3=enabled \
  -DFFmpeg:tls_protocol=enabled \
  -DFFmpeg:tests=disabled \
  -DFFmpeg:libxcb=disabled \
  -DFFmpeg:libxcb_shm=disabled \
  -DFFmpeg:libxcb_shape=disabled \
  -DFFmpeg:libxcb_xfixes=disabled \
  -Dswift-flags='-target arm64-apple-macosx10.15' \
  --prefix="$(pwd)/../prefix/macos/${ARCH}"

echo "macOS build configured for ${ARCH}"
