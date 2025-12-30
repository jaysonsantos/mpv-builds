#!/bin/bash
set -e

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Create pkgconfig directory for iOS (this will be the ONLY place pkg-config searches)
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

# Create a pkg-config wrapper that ONLY searches our iOS pkgconfig directory
# This prevents finding host system libraries like lcms2 from homebrew
cat > "${PROJECT_ROOT}/.cache/ios-pkgconfig/pkg-config-ios" << 'WRAPPER'
#!/bin/bash
# iOS pkg-config wrapper - only searches iOS-specific pkgconfig directory
export PKG_CONFIG_PATH=""
export PKG_CONFIG_LIBDIR="$(dirname "$0")"
exec pkg-config "$@"
WRAPPER
chmod +x "${PROJECT_ROOT}/.cache/ios-pkgconfig/pkg-config-ios"

echo "Created pkg-config wrapper at ${PROJECT_ROOT}/.cache/ios-pkgconfig/pkg-config-ios"

# Create iOS cross file
cat > ios-cross.txt << EOF
[binaries]
c = ['/usr/bin/xcrun', '-sdk', 'iphoneos', 'sccache', 'clang']
cpp = ['/usr/bin/xcrun', '-sdk', 'iphoneos', 'sccache', 'clang++']
objc = ['/usr/bin/xcrun', '-sdk', 'iphoneos', 'sccache', 'clang']
objcpp = ['/usr/bin/xcrun', '-sdk', 'iphoneos', 'sccache', 'clang++']
ar = ['/usr/bin/xcrun', '-sdk', 'iphoneos', 'ar']
strip = ['/usr/bin/xcrun', '-sdk', 'iphoneos', 'strip']
ranlib = ['/usr/bin/xcrun', '-sdk', 'iphoneos', 'ranlib']
pkgconfig = '${PROJECT_ROOT}/.cache/ios-pkgconfig/pkg-config-ios'

[built-in options]
pkg_config_path = '${PROJECT_ROOT}/.cache/ios-pkgconfig'

[properties]
sys_root = '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk'
needs_exe_wrapper = true

[host_machine]
system = 'darwin'
cpu_family = 'aarch64'
cpu = 'arm64'
endian = 'little'

[cmake]
CMAKE_POSITION_INDEPENDENT_CODE='ON'
EOF

echo "Created ios-cross.txt"
