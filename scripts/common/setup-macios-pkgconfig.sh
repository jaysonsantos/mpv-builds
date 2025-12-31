#!/bin/bash
set -e

# This script creates a platform-specific pkgconfig directory with vulkan.pc
# for macOS and iOS builds. It prevents finding host system libraries like lcms2 from homebrew.
#
# Usage: setup-macios-pkgconfig.sh <platform> [sys_root]
#   platform: "macos" or "ios"
#   sys_root: (optional) System root path for iOS (required for iOS builds)

PLATFORM="$1"
SYS_ROOT="$2"

if [ -z "${PLATFORM}" ]; then
    echo "Error: Platform argument required (macos or ios)"
    exit 1
fi

if [ "${PLATFORM}" != "macos" ] && [ "${PLATFORM}" != "ios" ]; then
    echo "Error: Platform must be 'macos' or 'ios'"
    exit 1
fi

if [ "${PLATFORM}" == "ios" ] && [ -z "${SYS_ROOT}" ]; then
    echo "Error: sys_root argument required for iOS builds"
    exit 1
fi

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

PKGCONFIG_DIR="${PROJECT_ROOT}/.cache/${PLATFORM}-pkgconfig"

# Create pkgconfig directory
mkdir -p "${PKGCONFIG_DIR}"

# For iOS, calculate relative path from sys_root to project root
if [ "${PLATFORM}" == "ios" ]; then
    RELATIVE_PATH="$(python3 -c "root='${SYS_ROOT}'; print('../' * root.count('/'))")"
    VULKAN_HEADERS_DIR="/${RELATIVE_PATH}${PROJECT_ROOT}/.cache/mpv/subprojects/libplacebo/3rdparty/Vulkan-Headers/include"
else
    # For macOS, use direct path
    VULKAN_HEADERS_DIR="${PROJECT_ROOT}/.cache/mpv/subprojects/libplacebo/3rdparty/Vulkan-Headers/include"
fi

# Create a vulkan.pc that points to libplacebo's bundled Vulkan headers
# Note: For iOS/macOS, MoltenVK provides the Vulkan implementation at runtime
# We only need the headers for compilation
cat > "${PKGCONFIG_DIR}/vulkan.pc" << EOF
Name: Vulkan-Headers
Description: Vulkan Headers for ${PLATFORM} (headers only, MoltenVK provides implementation)
Version: 1.3.283
Cflags: -DVK_USE_PLATFORM_METAL_EXT -isystem ${VULKAN_HEADERS_DIR}
EOF

echo "Created vulkan.pc at ${PKGCONFIG_DIR}/vulkan.pc"

# Create a pkg-config wrapper that ONLY searches our platform-specific pkgconfig directory
# This prevents finding host system libraries like lcms2 from homebrew
cat > "${PKGCONFIG_DIR}/pkg-config-${PLATFORM}" << 'WRAPPER'
#!/bin/bash
# Platform-specific pkg-config wrapper - only searches platform-specific pkgconfig directory
export PKG_CONFIG_PATH=""
export PKG_CONFIG_LIBDIR="$(dirname "$0")"
exec pkg-config "$@"
WRAPPER
chmod +x "${PKGCONFIG_DIR}/pkg-config-${PLATFORM}"

echo "Created pkg-config wrapper at ${PKGCONFIG_DIR}/pkg-config-${PLATFORM}"
echo "PKGCONFIG_DIR=${PKGCONFIG_DIR}"
