#!/bin/bash
set -ex

ARCH="${1:-aarch64}"

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
  -Dshaderc=disabled \
  -Dlibplacebo:lcms=enabled \
  -Dharfbuzz:icu=disabled \
  -Dlibass:require-system-font-provider=false \
  -DFFmpeg:gpl=enabled \
  -DFFmpeg:version3=enabled \
  -DFFmpeg:tls_protocol=enabled \
  -DFFmpeg:tests=disabled \
  -Dswift-flags='-target arm64-apple-macosx10.15' \
  --prefix="$(pwd)/../prefix/macos/${ARCH}"

echo "macOS build configured for ${ARCH}"
