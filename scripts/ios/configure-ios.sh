#!/bin/bash
set -e

ARCH="${1:-aarch64}"

cd .cache/mpv

meson setup "build/ios/${ARCH}" \
  --default-library=static \
  --buildtype=release \
  -Dwrap_mode=forcefallback \
  -Dcoreaudio=disabled \
  -Dlibmpv=true \
  -Dcplayer=false \
  -Dtests=false \
  -Dgpl=true \
  -Dmoltenvk=enabled \
  -Dshaderc=disabled \
  -Dharfbuzz:icu=disabled \
  -Dlibass:require-system-font-provider=false \
  -Dlibplacebo:lcms=disabled \
  -DFFmpeg:gpl=enabled \
  -DFFmpeg:version3=enabled \
  -DFFmpeg:mbedtls=enabled \
  -DFFmpeg:tls_protocol=enabled \
  --cross-file ../../ios-cross.txt \
  --prefix="$(pwd)/../prefix/ios/${ARCH}"

echo "iOS build configured for ${ARCH}"
