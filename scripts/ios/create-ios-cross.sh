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

# Setup iOS-specific pkgconfig directory with vulkan.pc
"${PROJECT_ROOT}/scripts/common/setup-macios-pkgconfig.sh" ios "${SYS_ROOT}"

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
CMAKE_C_FLAGS='-miphoneos-version-min=14.0 -miphonesimulator-version-min=14.0'
CMAKE_CXX_FLAGS='-miphoneos-version-min=14.0 -miphonesimulator-version-min=14.0'
CMAKE_SYSTEM_NAME = 'iOS'
# Force static libraries only - avoids Meson CMake soversion issues
BUILD_SHARED_LIBS = 'OFF'
# Shaderc options - skip tests/examples/install to avoid gmock dependency
SHADERC_SKIP_TESTS = 'ON'
SHADERC_SKIP_EXAMPLES = 'ON'
SHADERC_SKIP_INSTALL = 'ON'
SHADERC_SKIP_COPYRIGHT_CHECK = 'ON'
# glslang options - disable install to avoid export errors
GLSLANG_ENABLE_INSTALL = 'OFF'
GLSLANG_TESTS = 'OFF'
ENABLE_GLSLANG_BINARIES = 'OFF'
# SPIRV-Tools options - disable install
SKIP_SPIRV_TOOLS_INSTALL = 'ON'
SPIRV_SKIP_TESTS = 'ON'
EOF

echo "Created ios-cross.txt"
cat ios-cross.txt
