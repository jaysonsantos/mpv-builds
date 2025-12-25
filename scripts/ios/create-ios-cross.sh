#!/bin/bash
set -e

# Create iOS cross file
cat > ios-cross.txt << 'EOF'
[binaries]
c = ['xcrun', '-sdk', 'iphoneos', 'clang']
cpp = ['xcrun', '-sdk', 'iphoneos', 'clang++']
objc = ['xcrun', '-sdk', 'iphoneos', 'clang']
objcpp = ['xcrun', '-sdk', 'iphoneos', 'clang++']
ar = ['xcrun', '-sdk', 'iphoneos', 'ar']
strip = ['xcrun', '-sdk', 'iphoneos', 'strip']

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
