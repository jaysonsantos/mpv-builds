#!/bin/bash
set -e

ARCH="${1:-aarch64}"

cd .cache/mpv

meson setup "build/macos/${ARCH}" \
  --default-library=shared \
  --buildtype=release \
  -Dwrap_mode=forcefallback \
  -Dlibmpv=true \
  -Dtests=false \
  -Dgpl=true \
  -Dmoltenvk=enabled \
  -Dshaderc=enabled \
  -Dharfbuzz:icu=disabled \
  -Dlibass:require-system-font-provider=false \
  -DFFmpeg:gpl=enabled \
  -DFFmpeg:version3=enabled \
  -DFFmpeg:tls_protocol=enabled \
  --prefix="$(pwd)/../prefix/macos/${ARCH}"

echo "macOS build configured for ${ARCH}"
