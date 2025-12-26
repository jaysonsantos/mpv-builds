#!/bin/bash
set -e

ARCH="${1:-aarch64}"

cd .cache/mpv

meson setup "build/ios/${ARCH}" \
  --default-library=static \
  --buildtype=release \
  -Dwrap_mode=forcefallback \
  -Dlibmpv=true \
  -Dtests=false \
  -Dgpl=true \
  -Dmoltenvk=enabled \
  -Dharfbuzz:icu=disabled \
  -Dlibass:require-system-font-provider=false \
  -Dlibplacebo:lcms=enabled \
  -DFFmpeg:gpl=enabled \
  -DFFmpeg:version3=enabled \
  -DFFmpeg:mbedtls=enabled \
  -DFFmpeg:tls_protocol=enabled \
  --cross-file ../../ios-cross.txt \
  --prefix="$(pwd)/../prefix/ios/${ARCH}"

echo "iOS build configured for ${ARCH}"
