# GitHub Copilot Instructions for mpv-builds

## Project Overview

This repository builds `libmpv` and its dependencies for multiple platforms (Android, iOS, macOS, Windows) to be consumed by C#/MAUI applications like Jellyfin media players. It uses Meson build system with platform-specific cross-compilation.

**Key Purpose**: Provide native libmpv libraries that can be embedded in applications via P/Invoke or native bindings.

## Code Conventions

### Shell Scripts (Bash)
- Always start with `#!/bin/bash` and `set -e`
- Use UPPERCASE for environment/global variables: `MPV_VERSION`, `ARCH`, `PLATFORM`
- Use lowercase for local variables: `dirname`, `ext`
- Quote all variable expansions in paths: `"${OUTPUT_DIR}"`
- Use `${}` syntax for variable expansion: `"${ARCH}"`
- Default parameters: `ARCH="${1:-aarch64}"`
- Use heredocs for multi-line file generation
- Add `# shellcheck disable=SC####` comments when needed (e.g., `# shellcheck disable=SC2086`)

### PowerShell Scripts
- Start with `$ErrorActionPreference = "Stop"`
- Use `param()` blocks at the top for parameters
- Use PascalCase for parameters: `-Arch`, `-BuildType`
- Use `Write-Host` for progress messages

### YAML Workflows
- Use clear, descriptive job and step names
- Use platform conditions: `if: inputs.platform == 'android'` or `if: runner.os == 'Linux'`
- Cache keys should include platform, architecture, and relevant file hashes

### Meson Build Configuration
- Prefix subproject options with project name: `-Dlibass:asm=disabled`
- Standard options: `-Dwrap_mode=forcefallback -Dlibmpv=true -Dgpl=true -Dcplayer=false -Dtests=false`
- Use cross-files for Android/iOS, native files for macOS

### C/Objective-C Code (Patches)
- Follow mpv's existing code style
- Use LGPL 2.1+ license headers for new files
- Use proper null checks before dereferencing pointers

## Build Process

### Standard Build Sequence
1. Download mpv source: `./scripts/common/download-mpv.sh`
2. Setup wraps: `./scripts/common/setup-wraps.sh`
3. Create cross/native file: `./scripts/<platform>/create-<platform>-cross.sh <arch>`
4. Apply patches (macOS/iOS): `./scripts/common/apply-macos-patch.sh <platform>`
5. Configure: `./scripts/<platform>/configure-<platform>.sh <arch>`
6. Build: `cd .cache/mpv/build/<platform>/<arch> && ninja install`

### Output Locations
- Build artifacts: `.cache/mpv/build/<platform>/<arch>/`
- Installed libraries: `.cache/prefix/<platform>/<arch>/`

## Architecture

### Directory Structure
- `.github/workflows/`: CI/CD pipelines (reusable workflows)
- `patches/`: Platform-specific source code patches
  - `android/`: FFmpeg JNI fixes
  - `macios/`: MoltenVK Vulkan context for Metal rendering
  - `windows/`: Windows CI modifications
- `scripts/`: Build scripts organized by platform
  - `common/`: Shared utilities (download, setup, patch)
  - `<platform>/`: Platform-specific scripts (cross file creation, configuration)
- `wraps/`: Meson wrap files for dependencies (FFmpeg, libplacebo, etc.)
- `.cache/`: Build cache (gitignored)

### Key Dependencies
- **FFmpeg** (7.1.1): Media decoding/encoding
- **libplacebo** (v7.351.0): GPU-accelerated rendering
- **libass** (0.17.4): Subtitle rendering
- **lcms2** (2.17): Color management
- **mbedtls** (3.6.3.1): TLS for Android/iOS

### Platform-Specific Notes
- **Android**: Uses NDK r27, builds shared (.so) and static (.a) libraries, requires `libc++_shared.so`
- **iOS**: Static libraries only (.a), uses bundled Vulkan headers, custom pkg-config wrapper
- **macOS**: Native build, requires Homebrew packages (molten-vk, vulkan-headers, vulkan-loader)
- **Windows**: Uses mpv's CI build script with modifications, requires Visual Studio 2022 with Clang

## Testing and Validation

- No automated tests in this repository (build system only)
- Validation is done by:
  1. Successful build completion (`ninja install`)
  2. Library artifacts generated in output directories
  3. Integration testing in consuming applications (Jellyfin)

## Common Tasks

### Adding a New Platform
1. Create `scripts/<platform>/` directory
2. Add cross/native file creation script
3. Add configuration script
4. Create workflow in `.github/workflows/<platform>.yml`
5. Update `build-common.yml` with platform-specific steps

### Updating Dependencies
1. Modify wrap files in `wraps/` or update Meson wrap commands
2. Test build on all platforms
3. Update version numbers in documentation

### Creating Patches
1. Make changes in `.cache/mpv/` or dependency source
2. Generate patch: `git diff > patches/<platform>/<name>.patch`
3. Apply in build scripts before configuration
4. Document patch purpose in this file

## Important Files

- `AGENTS.md`: Comprehensive documentation (more detailed than this file)
- `scripts/common/download-mpv.sh`: Downloads mpv source (check script for current version)
- `scripts/common/setup-wraps.sh`: Installs Meson wrap dependencies
- `patches/macios/macios.patch`: Adds MoltenVK Vulkan context for macOS/iOS
- `.github/workflows/build-common.yml`: Reusable workflow for all platforms

## Tips for Copilot

- When modifying build scripts, always maintain the existing error handling (`set -e`, `$ErrorActionPreference = "Stop"`)
- Platform-specific code should use conditional logic rather than duplicating files
- Cache configuration in workflows is critical for build performance
- Always test cross-platform changes on all relevant platforms
- Consult `AGENTS.md` for detailed technical information
