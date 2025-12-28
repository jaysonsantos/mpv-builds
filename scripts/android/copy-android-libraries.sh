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

# Extract NDK bin directory from intro-compilers.json or use 'which'
echo "::group::Extracting NDK Binary Path"
if command -v jq &> /dev/null; then
    CPP_COMPILER=$(jq -r '.host.cpp.exelist[0]' meson-info/intro-compilers.json)
    echo "C++ compiler from meson: ${CPP_COMPILER}"
else
    echo "::warning::jq not found, attempting fallback method"
    # Fallback: try to parse manually
    CPP_COMPILER=$(grep -oP '"exelist":\s*\[\s*"\K[^"]+' meson-info/intro-compilers.json | head -n1)
    echo "C++ compiler from meson (fallback): ${CPP_COMPILER}"
fi

# If the compiler path is relative (just the binary name), resolve it using 'which'
if [[ "${CPP_COMPILER}" != /* ]]; then
    echo "Compiler path is relative, resolving using 'which'..."
    CPP_COMPILER_FULL=$(which "${CPP_COMPILER}" 2>/dev/null || echo "")
    if [ -n "${CPP_COMPILER_FULL}" ]; then
        echo "Resolved full compiler path: ${CPP_COMPILER_FULL}"
        CPP_COMPILER="${CPP_COMPILER_FULL}"
    else
        echo "::warning::Could not resolve compiler path using 'which'"
    fi
fi

echo "Final C++ compiler path: ${CPP_COMPILER}"
NDK_BIN=$(dirname "${CPP_COMPILER}")
echo "NDK bin directory: ${NDK_BIN}"
echo "::endgroup::"

# Determine architecture directory name in NDK
echo "::group::Determining NDK Architecture"
ARCH_DIR=""

# Try to detect from compiler path
if echo "${CPP_COMPILER}" | grep -q "aarch64"; then
    ARCH_DIR="aarch64-linux-android"
    echo "Detected architecture from compiler path: aarch64 (ARM64)"
elif echo "${CPP_COMPILER}" | grep -q "x86_64"; then
    ARCH_DIR="x86_64-linux-android"
    echo "Detected architecture from compiler path: x86_64"
else
    echo "::warning::Could not detect architecture from compiler path"
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
echo "::group::Locating libc++_shared.so"

# Try multiple possible paths
LIBCPP_CANDIDATES=(
    "${NDK_BIN}/../sysroot/usr/lib/${ARCH_DIR}/libc++_shared.so"
    "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${ARCH_DIR}/libc++_shared.so"
)

LIBCPP_SOURCE=""
for candidate in "${LIBCPP_CANDIDATES[@]}"; do
    echo "Checking: ${candidate}"
    if [ -f "${candidate}" ]; then
        LIBCPP_SOURCE="${candidate}"
        echo "✓ Found libc++_shared.so at: ${LIBCPP_SOURCE}"
        ls -lh "${LIBCPP_SOURCE}"
        break
    fi
done

if [ -z "${LIBCPP_SOURCE}" ]; then
    echo "::warning::libc++_shared.so NOT found at expected locations"
    echo "Searching for libc++_shared.so in ANDROID_NDK_HOME..."
    if [ -n "${ANDROID_NDK_HOME}" ]; then
        find "${ANDROID_NDK_HOME}" -name "libc++_shared.so" -path "*/sysroot/usr/lib/${ARCH_DIR}/*" 2>/dev/null | head -n 1 | while read -r found_path; do
            echo "Found via search: ${found_path}"
            LIBCPP_SOURCE="${found_path}"
        done
    fi
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
if [ -n "${LIBCPP_SOURCE}" ] && [ -f "${LIBCPP_SOURCE}" ]; then
    cp -v "${LIBCPP_SOURCE}" "${DEST_LIB_DIR}/"
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
