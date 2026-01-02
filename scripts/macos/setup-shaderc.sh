#!/bin/bash
set -e

# Setup shaderc and its dependencies for macOS builds
# This script should be run after setup-wraps.sh
#
# shaderc expects its dependencies in third_party/ with specific directory names.
# This script downloads them as Meson subprojects and copies them there.

cd .cache/mpv

# Copy macOS-specific wraps (shaderc and dependencies)
echo "Copying macOS shaderc wraps..."
for wrap in shaderc glslang SPIRV-Tools SPIRV-Headers; do
  if [ -f "../../wraps/macos/${wrap}.wrap" ]; then
    cp "../../wraps/macos/${wrap}.wrap" subprojects/
  fi
done

# Copy packagefiles for patches
if [ -d "../../patches/shaderc" ]; then
  mkdir -p subprojects/packagefiles/shaderc
  cp ../../patches/shaderc/*.patch subprojects/packagefiles/shaderc/ 2>/dev/null || true
fi

# Remove existing shaderc to ensure patches are applied fresh
if [ -d "subprojects/shaderc" ]; then
  echo "Removing existing shaderc to apply fresh patches..."
  rm -rf subprojects/shaderc
fi

# Download the shaderc-related subprojects
echo "Downloading shaderc subprojects..."
meson subprojects download shaderc glslang SPIRV-Tools SPIRV-Headers || true

# Setup shaderc third_party dependencies by copying (not symlinking)
# Meson's CMake integration doesn't handle symlinks outside the subproject
if [ -d "subprojects/shaderc" ]; then
  echo "Setting up shaderc dependencies in third_party/..."
  SHADERC_THIRD_PARTY="subprojects/shaderc/third_party"
  mkdir -p "$SHADERC_THIRD_PARTY"
  
  # Copy glslang
  if [ -d "subprojects/glslang" ] && [ ! -e "$SHADERC_THIRD_PARTY/glslang" ]; then
    cp -r subprojects/glslang "$SHADERC_THIRD_PARTY/glslang"
    echo "  - Copied glslang"
  fi
  
  # Copy SPIRV-Tools (shaderc expects spirv-tools lowercase)
  if [ -d "subprojects/SPIRV-Tools" ] && [ ! -e "$SHADERC_THIRD_PARTY/spirv-tools" ]; then
    cp -r subprojects/SPIRV-Tools "$SHADERC_THIRD_PARTY/spirv-tools"
    echo "  - Copied SPIRV-Tools as spirv-tools"
  fi
  
  # Copy SPIRV-Headers (shaderc expects spirv-headers lowercase)
  if [ -d "subprojects/SPIRV-Headers" ] && [ ! -e "$SHADERC_THIRD_PARTY/spirv-headers" ]; then
    cp -r subprojects/SPIRV-Headers "$SHADERC_THIRD_PARTY/spirv-headers"
    echo "  - Copied SPIRV-Headers as spirv-headers"
  fi
  
  echo "shaderc third_party dependencies configured"
fi

echo "shaderc setup complete"
