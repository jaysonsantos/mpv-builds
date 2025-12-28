#!/bin/bash
set -e

PLATFORM="${1:-}"

cd .cache/mpv
mkdir -p subprojects

# Install basic wraps
for wrap in expat harfbuzz libpng zlib; do
  meson wrap install "$wrap" || true
done

# Download Gstreamer wraps
GSTREAMER_WRAP_URL=https://gitlab.freedesktop.org/gstreamer/gstreamer/-/raw/main/subprojects
for wrap in freetype2 fribidi fontconfig libjpeg-turbo; do
  curl -Lsqo "subprojects/${wrap}.wrap" "${GSTREAMER_WRAP_URL}/${wrap}.wrap" || true
done

# Copy local wraps
if [ -d "../../wraps" ]; then
  # Define exclusion list per platform
  EXCLUDE_WRAPS=()
  if [ "$PLATFORM" = "macos" ]; then
    EXCLUDE_WRAPS+=("lcms2.wrap")
    echo "Excluding wraps for macOS: ${EXCLUDE_WRAPS[*]}"
  fi
  
  # Copy wraps, excluding those in the exclusion list
  for wrap_file in ../../wraps/*.wrap; do
    wrap_name=$(basename "$wrap_file")
    if [[ ! " ${EXCLUDE_WRAPS[@]} " =~ " ${wrap_name} " ]]; then
      cp "$wrap_file" subprojects/ || true
    else
      echo "Skipping excluded wrap: $wrap_name"
    fi
  done
fi

# Download all subprojects
echo "Downloading subprojects..."
meson subprojects download || true

echo "Wraps configured"
