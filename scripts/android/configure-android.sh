#!/bin/bash
set -e

ARCH="${1:-aarch64}"

cd .cache/mpv

# Apply FFmpeg JNI fix patch for Android
PATCH_FILE="../../patches/android/ffmpeg-jni-fix.patch"
if [ ! -f "$PATCH_FILE" ]; then
  echo "::error::FFmpeg JNI patch not found at $PATCH_FILE"
  exit 1
fi

if [ ! -d "subprojects/FFmpeg" ]; then
  echo "::error::FFmpeg subproject directory not found. Please run setup-wraps.sh first."
  exit 1
fi

echo "::group::Applying FFmpeg JNI fix patch for Android"
cd subprojects/FFmpeg

# Patch path relative to FFmpeg directory
PATCH_PATH="../../../../patches/android/ffmpeg-jni-fix.patch"

# Try to apply the patch
if patch -p1 --dry-run < "$PATCH_PATH" > /dev/null 2>&1; then
  # Patch can be applied
  patch -p1 < "$PATCH_PATH"
  echo "Patch applied successfully"
else
  # Check if patch is already applied
  if patch -p1 -R --dry-run < "$PATCH_PATH" > /dev/null 2>&1; then
    echo "Patch already applied, skipping"
  else
    echo "::warning::Failed to apply FFmpeg JNI patch - it may already be applied due to caching or be incompatible"
  fi
fi

cd ../..
echo "::endgroup::"

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
