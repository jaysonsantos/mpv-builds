#!/bin/bash
set -e

# Create macOS native file
cat > macos-native.txt << 'EOF'
[binaries]
c = ['sccache', 'clang']
cpp = ['sccache', 'clang++']
objc = ['sccache', 'clang']
objcpp = ['sccache', 'clang++']

[properties]

[built-in options]
EOF

echo "Created macos-native.txt"
