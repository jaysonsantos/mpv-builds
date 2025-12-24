#!/bin/bash
set -e

ARCH="${1:-x86_64}"

cd .cache/mpv

meson setup "build/windows/${ARCH}" \
  --default-library=shared \
  --buildtype=release \
  -Dwrap_mode=forcefallback \
  -Dlibmpv=true \
  -Dgpl=true \
  -Dshaderc=disabled \
  -Dharfbuzz:icu=disabled \
  -Dlibass:require-system-font-provider=false \
  -DFFmpeg:gpl=enabled \
  -DFFmpeg:version3=enabled \
  -DFFmpeg:tls_protocol=enabled \
  --prefix="$(pwd)/../prefix/windows/${ARCH}"

echo "Windows build configured for ${ARCH}"
