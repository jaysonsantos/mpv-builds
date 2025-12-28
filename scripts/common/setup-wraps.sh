#!/bin/bash
set -e

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
  cp ../../wraps/*.wrap subprojects/ || true
fi

# Download all subprojects
echo "Downloading subprojects..."
meson subprojects download || true

echo "Wraps configured"
