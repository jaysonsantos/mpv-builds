#!/bin/bash
set -e

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Setup macOS-specific pkgconfig directory with vulkan.pc
"${PROJECT_ROOT}/scripts/common/setup-macios-pkgconfig.sh" macos

# Create macOS native file
cat > macos-native.txt << EOF
[binaries]
c = ['sccache', 'clang']
cpp = ['sccache', 'clang++']
objc = ['sccache', 'clang']
objcpp = ['sccache', 'clang++']

[properties]

[built-in options]
pkg_config_path = '${PROJECT_ROOT}/.cache/macos-pkgconfig'

[cmake]
CMAKE_POSITION_INDEPENDENT_CODE='ON'
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

echo "Created macos-native.txt"
cat macos-native.txt
