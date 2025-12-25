#!/bin/bash
set -e

# Create macOS native file
cat > macos-native.txt << 'EOF'
[binaries]
c = ['clang']
cpp = ['clang++']
objc = ['clang']
objcpp = ['clang++']

[properties]

[built-in options]
EOF

echo "Created macos-native.txt"
