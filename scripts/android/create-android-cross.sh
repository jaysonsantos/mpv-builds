#!/bin/bash
set -e

ARCH="${1:-aarch64}"

# Set architecture-specific values
if [ "$ARCH" == "aarch64" ]; then
  ANDROID_ABI="aarch64-linux-android21"
  CPU_FAMILY="aarch64"
  CPU="aarch64"
  # Add 16k page size support for aarch64
  PAGE_SIZE_FLAGS="-Wl,-z,max-page-size=16384"
elif [ "$ARCH" == "x86_64" ]; then
  ANDROID_ABI="x86_64-linux-android21"
  CPU_FAMILY="x86_64"
  CPU="x86_64"
  PAGE_SIZE_FLAGS=""
else
  echo "Unsupported architecture: $ARCH"
  echo "Usage: $0 [aarch64|x86_64]"
  exit 1
fi

cat > "android-${ARCH}-cross.txt" <<EOF
[binaries]
c = '${ANDROID_ABI}-clang'
cpp = '${ANDROID_ABI}-clang++'
ar = 'llvm-ar'
nm = 'llvm-nm'
strip = 'llvm-strip'
pkg-config = 'pkg-config'

[host_machine]
system = 'android'
cpu_family = '${CPU_FAMILY}'
cpu = '${CPU}'
endian = 'little'

[properties]
needs_exe_wrapper = true
c_link_args = ['${PAGE_SIZE_FLAGS}']
cpp_link_args = ['${PAGE_SIZE_FLAGS}']

[cmake]
CMAKE_POSITION_INDEPENDENT_CODE='ON'
EOF

echo "Created android-${ARCH}-cross.txt"
