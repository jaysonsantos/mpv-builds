#!/bin/bash
set -e

ARCH="${1:-aarch64}"
NDK_PATH=""

if [ -n "$ANDROID_NDK_ROOT" ]; then
    NDK_PATH="$(dirname "$(find "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt" -iname clang++)")/"
fi
PAGE_SIZE_FLAGS="-Wl,-z,max-page-size=16384"

# Set architecture-specific values
if [ "$ARCH" == "aarch64" ]; then
  ANDROID_ABI="aarch64-linux-android21"
  CPU_FAMILY="aarch64"
  CPU="aarch64"
elif [ "$ARCH" == "x86_64" ]; then
  ANDROID_ABI="x86_64-linux-android21"
  CPU_FAMILY="x86_64"
  CPU="x86_64"
else
  echo "Unsupported architecture: $ARCH"
  echo "Usage: $0 [aarch64|x86_64]"
  exit 1
fi

cat > "android-${ARCH}-cross.txt" <<EOF
[binaries]
c = ['sccache', '${NDK_PATH}${ANDROID_ABI}-clang']
cpp = ['sccache', '${NDK_PATH}${ANDROID_ABI}-clang++']
ar = '${NDK_PATH}llvm-ar'
nm = '${NDK_PATH}llvm-nm'
strip = '${NDK_PATH}llvm-strip'
pkg-config = '${NDK_PATH}pkg-config'

[host_machine]
system = 'android'
cpu_family = '${CPU_FAMILY}'
cpu = '${CPU}'
endian = 'little'

[properties]
needs_exe_wrapper = true

[built-in options]
c_link_args = ['${PAGE_SIZE_FLAGS}']
cpp_link_args = ['${PAGE_SIZE_FLAGS}']

[cmake]
CMAKE_POSITION_INDEPENDENT_CODE='ON'
EOF

echo "Created android-${ARCH}-cross.txt"
