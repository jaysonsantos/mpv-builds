#!/bin/bash
set -e

# Script to copy Android libraries including libc++_shared.so from NDK
# Usage: ./copy-android-libraries.sh <arch>
# Example: ./copy-android-libraries.sh aarch64

ARCH="${1:-aarch64}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/.cache/mpv/build/android/${ARCH}"
PREFIX_DIR="${PROJECT_ROOT}/.cache/prefix/android/${ARCH}"

echo "::group::Copy Android Libraries - Configuration"
echo "Architecture: ${ARCH}"
echo "Build directory: ${BUILD_DIR}"
echo "Prefix directory: ${PREFIX_DIR}"
echo "::endgroup::"

# Check if build directory exists
if [ ! -d "${BUILD_DIR}" ]; then
    echo "::error::Build directory does not exist: ${BUILD_DIR}"
    exit 1
fi

# Navigate to build directory
cd "${BUILD_DIR}"
echo "Current directory: $(pwd)"

# Debug: Show meson-info files
echo "::group::Meson Info Files"
if [ -d "meson-info" ]; then
    echo "Available meson-info files:"
    ls -lh meson-info/
else
    echo "::error::meson-info directory not found"
    exit 1
fi
echo "::endgroup::"

# Debug: Show intro-compilers.json content
echo "::group::Compilers Info (intro-compilers.json)"
if [ -f "meson-info/intro-compilers.json" ]; then
    echo "Content of intro-compilers.json:"
    cat meson-info/intro-compilers.json
else
    echo "::error::intro-compilers.json not found"
    exit 1
fi
echo "::endgroup::"

# Extract NDK bin directory from intro-compilers.json
echo "::group::Extracting NDK Binary Path"
if command -v jq &> /dev/null; then
    CPP_COMPILER=$(jq -r '.host.cpp.exelist[0]' meson-info/intro-compilers.json)
    echo "C++ compiler path: ${CPP_COMPILER}"
    NDK_BIN=$(dirname "${CPP_COMPILER}")
    echo "NDK bin directory: ${NDK_BIN}"
else
    echo "::warning::jq not found, attempting fallback method"
    # Fallback: try to parse manually
    CPP_COMPILER=$(grep -oP '"exelist":\s*\[\s*"\K[^"]+' meson-info/intro-compilers.json | head -n1)
    echo "C++ compiler path (fallback): ${CPP_COMPILER}"
    NDK_BIN=$(dirname "${CPP_COMPILER}")
    echo "NDK bin directory (fallback): ${NDK_BIN}"
fi
echo "::endgroup::"

# Determine architecture directory name in NDK
echo "::group::Determining NDK Architecture"
ARCH_DIR=""
if echo "${NDK_BIN}" | grep -q "aarch64"; then
    ARCH_DIR="aarch64-linux-android"
    echo "Detected architecture: aarch64 (ARM64)"
elif echo "${NDK_BIN}" | grep -q "x86_64"; then
    ARCH_DIR="x86_64-linux-android"
    echo "Detected architecture: x86_64"
else
    echo "::warning::Could not detect architecture from NDK bin path"
    # Fallback based on input argument
    if [ "${ARCH}" == "aarch64" ]; then
        ARCH_DIR="aarch64-linux-android"
        echo "Using fallback architecture from argument: aarch64"
    elif [ "${ARCH}" == "x86_64" ]; then
        ARCH_DIR="x86_64-linux-android"
        echo "Using fallback architecture from argument: x86_64"
    fi
fi
echo "NDK architecture directory: ${ARCH_DIR}"
echo "::endgroup::"

# Construct path to libc++_shared.so
LIBCPP_SOURCE="${NDK_BIN}/../sysroot/usr/lib/${ARCH_DIR}/libc++_shared.so"
echo "::group::Locating libc++_shared.so"
echo "Expected path: ${LIBCPP_SOURCE}"

# Resolve path and check if it exists
LIBCPP_SOURCE_RESOLVED=$(realpath "${LIBCPP_SOURCE}" 2>/dev/null || echo "${LIBCPP_SOURCE}")
echo "Resolved path: ${LIBCPP_SOURCE_RESOLVED}"

if [ -f "${LIBCPP_SOURCE_RESOLVED}" ]; then
    echo "✓ libc++_shared.so found"
    ls -lh "${LIBCPP_SOURCE_RESOLVED}"
else
    echo "::warning::libc++_shared.so NOT found at expected location"
    echo ""
    echo "Searching for libc++_shared.so in NDK..."
    find "${NDK_BIN}/.." -name "libc++_shared.so" 2>/dev/null || echo "No libc++_shared.so found in NDK"
fi
echo "::endgroup::"

# Create destination directory
echo "::group::Creating Destination Directory"
DEST_LIB_DIR="${PREFIX_DIR}/lib"
echo "Destination: ${DEST_LIB_DIR}"
mkdir -p "${DEST_LIB_DIR}"
echo "✓ Directory created/verified"
echo "::endgroup::"

# Copy libc++_shared.so
echo "::group::Copying libc++_shared.so"
if [ -f "${LIBCPP_SOURCE_RESOLVED}" ]; then
    cp -v "${LIBCPP_SOURCE_RESOLVED}" "${DEST_LIB_DIR}/"
    echo "✓ Successfully copied libc++_shared.so"
else
    echo "::error::libc++_shared.so not found, skipping copy"
fi
echo "::endgroup::"

# Show final result
echo "::group::Final Library Directory Contents"
echo "Contents of ${DEST_LIB_DIR}:"
ls -lh "${DEST_LIB_DIR}/" || echo "Directory is empty or does not exist"
echo "::endgroup::"

echo "Copy Android Libraries - Complete"
