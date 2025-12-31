#!/bin/bash
set -e

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if [ "$1" == "no-xcode" ]
then
    echo "Skipping Xcode selection"
else
    sudo xcode-select -s /Applications/Xcode_26.2.app/Contents/Developer
fi

SDK_PLATFORM_PATH="$(xcrun -v -sdk iphoneos --show-sdk-platform-path)"
SYS_ROOT="${SDK_PLATFORM_PATH}/Developer/SDKs/iPhoneOS.sdk"
RELATIVE_PATH="$(python3 -c "root='${SYS_ROOT}'; print('../' * root.count('/'))")"

# Create pkgconfig directory for iOS (this will be the ONLY place pkg-config searches)
mkdir -p "${PROJECT_ROOT}/.cache/ios-pkgconfig"

# Create a vulkan.pc that points to libplacebo's bundled Vulkan headers
# Note: For iOS, MoltenVK provides the Vulkan implementation at runtime
# We only need the headers for compilation
# Use absolute path directly in Cflags to avoid sysroot path mangling
# TODO: sys_root will append to this path which will then be wrong, this is just a hack to make it work

VULKAN_HEADERS_DIR="/${RELATIVE_PATH}${PROJECT_ROOT}/.cache/mpv/subprojects/libplacebo/3rdparty/Vulkan-Headers/include"

cat > "${PROJECT_ROOT}/.cache/ios-pkgconfig/vulkan.pc" << EOF
Name: Vulkan-Headers
Description: Vulkan Headers for iOS (headers only, MoltenVK provides implementation)
Version: 1.3.283
Cflags: -DVK_USE_PLATFORM_METAL_EXT -isystem ${VULKAN_HEADERS_DIR}
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
pkg-config = '${PROJECT_ROOT}/.cache/ios-pkgconfig/pkg-config-ios'

[built-in options]
pkg_config_path = '${PROJECT_ROOT}/.cache/ios-pkgconfig'
c_args = ['-miphoneos-version-min=11.0']
cpp_args = ['-miphoneos-version-min=11.0']
c_link_args = ['-miphoneos-version-min=11.0']
cpp_link_args = ['-miphoneos-version-min=11.0']
objc_args = ['-miphoneos-version-min=11.0']
objcpp_args = ['-miphoneos-version-min=11.0']


[properties]
sys_root = '${SYS_ROOT}'
needs_exe_wrapper = true

[host_machine]
system = 'darwin'
subsystem = 'ios'
cpu_family = 'aarch64'
cpu = 'arm64'
endian = 'little'

[cmake]
CMAKE_POSITION_INDEPENDENT_CODE='ON'
EOF

echo "Created ios-cross.txt"
cat ios-cross.txt
