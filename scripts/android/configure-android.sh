#!/bin/bash
set -e

ARCH="${1:-aarch64}"

cd .cache/mpv

ASM_FLAGS=""
if [ "$ARCH" == "x86_64" ]; then
  ASM_FLAGS="-Dlibass:asm=disabled -DFFmpeg:x86asm=disabled"
fi

# Configure meson build
# Note: -DFFmpeg:pthreads=enabled is required for JNI support (see patches/android/ffmpeg-jni-fix.patch)
# shellcheck disable=SC2086
meson setup "build/android/${ARCH}" \
  --default-library=both \
  --buildtype=release \
  -Dwrap_mode=forcefallback \
  -Dlibmpv=true \
  -Dgpl=true \
  -Dshaderc=disabled \
  -Dharfbuzz:icu=disabled \
  -Dlibass:require-system-font-provider=false \
  ${ASM_FLAGS} \
  -DFFmpeg:gpl=enabled \
  -DFFmpeg:version3=enabled \
  -DFFmpeg:mbedtls=enabled \
  -DFFmpeg:tls_protocol=enabled \
  -DFFmpeg:jni=enabled \
  -DFFmpeg:pthreads=enabled \
  --cross-file "../../android-${ARCH}-cross.txt" \
  --prefix="$(pwd)/../prefix/android/${ARCH}"

echo "Android build configured for ${ARCH}"
