#!/bin/bash
set -e

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Create pkgconfig directory for iOS
mkdir -p "${PROJECT_ROOT}/.cache/ios-pkgconfig"

# Create a vulkan.pc that points to libplacebo's bundled Vulkan headers
# Note: For iOS, MoltenVK provides the Vulkan implementation at runtime
# We only need the headers for compilation
# Use absolute path directly in Cflags to avoid sysroot path mangling
VULKAN_HEADERS_DIR="${PROJECT_ROOT}/.cache/mpv/subprojects/libplacebo/3rdparty/Vulkan-Headers/include"

cat > "${PROJECT_ROOT}/.cache/ios-pkgconfig/vulkan.pc" << EOF
Name: Vulkan-Headers
Description: Vulkan Headers for iOS (headers only, MoltenVK provides implementation)
Version: 1.3.283
Cflags: -isystem ${VULKAN_HEADERS_DIR}
EOF

echo "Created vulkan.pc at ${PROJECT_ROOT}/.cache/ios-pkgconfig/vulkan.pc"

# Create iOS cross file
cat > ios-cross.txt << EOF
[binaries]
c = ['xcrun', '-sdk', 'iphoneos', 'clang']
cpp = ['xcrun', '-sdk', 'iphoneos', 'clang++']
objc = ['xcrun', '-sdk', 'iphoneos', 'clang']
objcpp = ['xcrun', '-sdk', 'iphoneos', 'clang++']
ar = ['xcrun', '-sdk', 'iphoneos', 'ar']
strip = ['xcrun', '-sdk', 'iphoneos', 'strip']
pkgconfig = ['pkg-config']

[built-in options]
pkg_config_path = '${PROJECT_ROOT}/.cache/ios-pkgconfig'

[properties]
sys_root = '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk'

[host_machine]
system = 'darwin'
cpu_family = 'aarch64'
cpu = 'arm64'
endian = 'little'

[cmake]
CMAKE_POSITION_INDEPENDENT_CODE='ON'
EOF

echo "Created ios-cross.txt"
