# AGENTS.md - mpv-builds

Cross-platform build system for libmpv libraries, designed for embedding mpv in native applications like Jellyfin media players built with C#/MAUI.

## Project Overview

This repository builds `libmpv` and its dependencies for multiple platforms:
- **Android** (aarch64, x86_64) - shared libraries (.so)
- **iOS** (aarch64) - static libraries (.a)
- **macOS** (aarch64) - shared libraries (.dylib)
- **Windows** (x86_64) - shared libraries (.dll)

The output libraries can be consumed by C#/MAUI applications via P/Invoke or native bindings.

## Build Commands

### Prerequisites
- Python 3.12 with `meson` (`pip install meson`)
- Ninja build system
- NASM assembler
- pkg-config
- Platform-specific: Android NDK r27, Xcode, Visual Studio 2022

### Full Build Sequence

```bash
# 1. Download mpv source (v0.41.0)
./scripts/common/download-mpv.sh

# 2. Setup Meson wrap dependencies
./scripts/common/setup-wraps.sh

# 3. Create platform cross/native file
./scripts/android/create-android-cross.sh aarch64   # Android
./scripts/ios/create-ios-cross.sh                    # iOS
./scripts/macos/create-macos-native.sh               # macOS

# 4. Apply patches (macOS/iOS only)
./scripts/common/apply-macos-patch.sh macos          # or 'ios'

# 5. Configure build
./scripts/android/configure-android.sh aarch64
./scripts/ios/configure-ios.sh aarch64
./scripts/macos/configure-macos.sh aarch64
# Windows: .\scripts\windows\configure-windows.ps1 -Arch x86_64

# 6. Build
cd .cache/mpv/build/<platform>/<arch>
ninja install
```

### Output Locations
- Build artifacts: `.cache/mpv/build/<platform>/<arch>/`
- Installed libraries: `.cache/prefix/<platform>/<arch>/`

## Code Style Guidelines

### Shell Scripts (Bash)
- Always start with `#!/bin/bash` and `set -e`
- Use UPPERCASE for environment/global variables: `MPV_VERSION`, `ARCH`, `PLATFORM`
- Use lowercase for local variables: `dirname`, `ext`
- Quote all variable expansions in paths: `"${OUTPUT_DIR}"`
- Use `${}` syntax for variable expansion: `"${ARCH}"`
- Default parameters: `ARCH="${1:-aarch64}"`
- Use heredocs for multi-line file generation: `cat > file << 'EOF'`
- Use `shellcheck` directive comments when needed: `# shellcheck disable=SC2086`

### PowerShell Scripts
- Start with `$ErrorActionPreference = "Stop"`
- Use `param()` blocks at the top for parameters
- Use PascalCase for parameters: `-Arch`, `-BuildType`
- Use `Write-Host` for progress messages

### YAML Workflows
- Use clear, descriptive job and step names
- Use platform conditions: `if: inputs.platform == 'android'` or `if: runner.os == 'Linux'`
- Cache keys should include platform, architecture, and relevant file hashes

### Meson Options
- Prefix subproject options with project name: `-Dlibass:asm=disabled`
- Standard options: `-Dwrap_mode=forcefallback -Dlibmpv=true -Dgpl=true -Dcplayer=false -Dtests=false`

### C/Objective-C Code (Patches)
- Follow mpv's existing code style
- Use LGPL 2.1+ license headers for new files
- Use proper null checks before dereferencing pointers

## Directory Structure

```
mpv-builds/
├── .github/workflows/     # CI/CD pipelines
├── patches/               # Platform-specific source patches
│   ├── android/           # FFmpeg JNI fixes
│   ├── macios/            # MoltenVK Vulkan context
│   └── windows/           # Windows CI modifications
├── scripts/               # Build scripts by platform
│   ├── common/            # Shared utilities
│   └── <platform>/        # Platform-specific scripts
├── wraps/                 # Meson wrap files for dependencies
└── .cache/                # Build cache (gitignored)
```

## Key Dependencies (via Meson wraps)

| Dependency   | Version      | Purpose                    |
|--------------|--------------|----------------------------|
| FFmpeg       | 7.1.1        | Media decoding/encoding    |
| libplacebo   | v7.351.0     | GPU-accelerated rendering  |
| libass       | 0.17.4       | Subtitle rendering         |
| lcms2        | 2.17         | Color management           |
| mbedtls      | 3.6.3.1      | TLS (Android/iOS)          |

## Integration with C#/MAUI (Jellyfin)

### Library Loading
- Android: Load `libmpv.so` and `libc++_shared.so` from native libs
- iOS: Link static `libmpv.a` in Xcode project
- macOS: Bundle `libmpv.dylib` in app resources
- Windows: Bundle `libmpv-2.dll` and `vulkan-1.dll` with your application

### MoltenVK Context (macOS/iOS)
The `macios.patch` adds a `moltenvk` Vulkan context that accepts a `CAMetalLayer` pointer via `WinID`. This enables embedding mpv in MAUI views:
- Create a `CAMetalLayer` in your MAUI view
- Pass the layer pointer to mpv via the `--wid` option
- mpv renders directly to your Metal layer

### Android JNI
FFmpeg is built with JNI support (`-DFFmpeg:jni=enabled`) for hardware acceleration via MediaCodec.

## Platform-Specific Notes

### Android
- Uses NDK r27 with 16K page size support for newer devices
- Shared libraries required; include `libc++_shared.so` from NDK
- ASM disabled on x86_64 due to compatibility issues

### iOS
- Static library only (App Store requirements)
- Uses bundled Vulkan headers from libplacebo
- Custom pkg-config wrapper avoids host system conflicts

### macOS
- Native build (no cross-compilation needed)
- Requires Homebrew: `molten-vk`, `vulkan-headers`, `vulkan-loader`

### Windows
- Uses mpv's own CI build script with modifications
- Requires Visual Studio 2022 with Clang
- PATH cleaning needed to avoid tool conflicts

## Troubleshooting

- **sccache issues**: Check cache paths per OS in `build-common.yml`
- **Patch failures**: May already be applied; check with `patch --dry-run`
- **Missing dependencies**: Wraps auto-download; check network connectivity
- **Build failures**: Check Meson logs in `.cache/mpv/build/<platform>/<arch>/meson-logs/`
