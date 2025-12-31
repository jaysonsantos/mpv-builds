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
EOF

echo "Created macos-native.txt"
