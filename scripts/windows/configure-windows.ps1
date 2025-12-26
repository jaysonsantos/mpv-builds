param(
    [string]$Arch = "x86_64"
)

$ErrorActionPreference = "Stop"

# Find Visual Studio 2022 installation
$vsBasePath = "C:\Program Files\Microsoft Visual Studio\2022"
$editions = @("Enterprise", "Professional", "Community")
$vsPath = $null

foreach ($edition in $editions) {
    $testPath = Join-Path $vsBasePath $edition
    $devShellPath = Join-Path $testPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    
    if (Test-Path $devShellPath) {
        $vsPath = $testPath
        Write-Host "Found Visual Studio 2022 $edition edition"
        break
    }
}

if (-not $vsPath) {
    Write-Error "Visual Studio 2022 not found!"
    exit 1
}

# Clean PATH from conflicting tools
Write-Host "Cleaning PATH from conflicting tools..."
$env:PATH = ($env:PATH -split ';' | Where-Object { 
    $_ -ne 'C:\Program Files\LLVM\bin' -and `
    $_ -ne 'C:\Program Files\CMake\bin' -and `
    $_ -ne 'C:\Strawberry\c\bin' 
}) -join ';'

# Add NASM to PATH
$env:PATH = $env:PATH + ';C:\Program Files\NASM'

# Set VS environment variable
$env:VS = $vsPath

# Import Visual Studio DevShell module
Write-Host "Loading Visual Studio DevShell from: $vsPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
Import-Module "$vsPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"

# Set architecture for VS environment
$vsArch = if ($Arch -eq "x86_64") { "x64" } else { $Arch }

Write-Host "Entering Visual Studio developer shell for $vsArch..."
Enter-VsDevShell -VsInstallPath $env:VS -SkipAutomaticLocation -DevCmdArguments "-arch=$vsArch -host_arch=$vsArch"

Write-Host "Visual Studio environment loaded."

# Change to MPV directory
Set-Location .cache\mpv

$subprojects = "subprojects"
if (-not (Test-Path $subprojects)) {
    New-Item -Path $subprojects -ItemType Directory | Out-Null
}

# Create shaderc wrapper with static runtime (from mpv's CI script)
Write-Host "Setting up shaderc wrapper..."
if (-not (Test-Path "$subprojects/shaderc_cmake")) {
    git clone https://github.com/google/shaderc --depth 1 $subprojects/shaderc_cmake
    Set-Content -Path "$subprojects/shaderc_cmake/p.diff" -Value @'
diff --git a/third_party/CMakeLists.txt b/third_party/CMakeLists.txt
index d44f62a..54d4719 100644
--- a/third_party/CMakeLists.txt
+++ b/third_party/CMakeLists.txt
@@ -87,7 +87,11 @@ if (NOT TARGET glslang)
       # Glslang tests are off by default. Turn them on if testing Shaderc.
       set(GLSLANG_TESTS ON)
     endif()
-    set(GLSLANG_ENABLE_INSTALL $<NOT:${SKIP_GLSLANG_INSTALL}>)
+    if (SKIP_GLSLANG_INSTALL)
+      set(GLSLANG_ENABLE_INSTALL OFF)
+    else()
+      set(GLSLANG_ENABLE_INSTALL ON)
+    endif()
     add_subdirectory(${SHADERC_GLSLANG_DIR} glslang)
   endif()
   if (NOT TARGET glslang)
'@
    git -C $subprojects/shaderc_cmake apply --ignore-whitespace p.diff
}
if (-not (Test-Path "$subprojects/shaderc")) {
    New-Item -Path "$subprojects/shaderc" -ItemType Directory | Out-Null
}
Set-Content -Path "$subprojects/shaderc/meson.build" -Value @"
project('shaderc', 'cpp', version: '2024.1')

python = find_program('python3')
run_command(python, '../shaderc_cmake/utils/git-sync-deps', check: true)

cmake = import('cmake')
opts = cmake.subproject_options()
opts.add_cmake_defines({
    'CMAKE_MSVC_RUNTIME_LIBRARY': 'MultiThreadedDLL',
    'CMAKE_POLICY_DEFAULT_CMP0091': 'NEW',
    'BUILD_SHARED_LIBS': 'OFF',
    'SHADERC_SKIP_INSTALL': 'ON',
    'SHADERC_SKIP_TESTS': 'ON',
    'SHADERC_SKIP_EXAMPLES': 'ON',
    'SHADERC_SKIP_COPYRIGHT_CHECK': 'ON'
})
shaderc_proj = cmake.subproject('shaderc_cmake', options: opts)
shaderc_dep = declare_dependency(dependencies: [
    shaderc_proj.dependency('shaderc'),
    shaderc_proj.dependency('shaderc_util'),
    shaderc_proj.dependency('SPIRV-Tools-static'),
    shaderc_proj.dependency('SPIRV-Tools-opt'),
    shaderc_proj.dependency('glslang'),
])
meson.override_dependency('shaderc', shaderc_dep)
"@

# Create spirv-cross wrapper
Write-Host "Setting up spirv-cross wrapper..."
if (-not (Test-Path "$subprojects/spirv-cross-c-shared")) {
    New-Item -Path "$subprojects/spirv-cross-c-shared" -ItemType Directory | Out-Null
}
Set-Content -Path "$subprojects/spirv-cross-c-shared/meson.build" -Value @"
project('spirv-cross', 'cpp', version: '0.59.0')
cmake = import('cmake')
opts = cmake.subproject_options()
opts.add_cmake_defines({
    'CMAKE_MSVC_RUNTIME_LIBRARY': 'MultiThreadedDLL',
    'CMAKE_POLICY_DEFAULT_CMP0091': 'NEW',
    'BUILD_SHARED_LIBS': 'OFF',
    'SPIRV_CROSS_EXCEPTIONS_TO_ASSERTIONS': 'ON',
    'SPIRV_CROSS_CLI': 'OFF',
    'SPIRV_CROSS_ENABLE_TESTS': 'OFF',
    'SPIRV_CROSS_ENABLE_MSL': 'OFF',
    'SPIRV_CROSS_ENABLE_CPP': 'OFF',
    'SPIRV_CROSS_ENABLE_REFLECT': 'OFF',
    'SPIRV_CROSS_ENABLE_UTIL': 'OFF',
})
spirv_cross_proj = cmake.subproject('spirv-cross', options: opts)
spirv_cross_c_dep = declare_dependency(dependencies: [
    spirv_cross_proj.dependency('spirv-cross-c'),
    spirv_cross_proj.dependency('spirv-cross-core'),
    spirv_cross_proj.dependency('spirv-cross-glsl'),
    spirv_cross_proj.dependency('spirv-cross-hlsl'),
])
meson.override_dependency('spirv-cross-c-shared', spirv_cross_c_dep)
"@

# Create Vulkan-Loader wrapper
Write-Host "Setting up vulkan-loader wrapper..."
if (-not (Test-Path "$subprojects/vulkan")) {
    New-Item -Path "$subprojects/vulkan" -ItemType Directory | Out-Null
}
Set-Content -Path "$subprojects/vulkan/meson.build" -Value @"
project('vulkan', 'cpp', version: '1.3.285')
cmake = import('cmake')
opts = cmake.subproject_options()
opts.add_cmake_defines({
    'CMAKE_MSVC_RUNTIME_LIBRARY': 'MultiThreadedDLL',
    'CMAKE_POLICY_DEFAULT_CMP0091': 'NEW',
    'UPDATE_DEPS': 'ON',
    'BUILD_TESTS': 'OFF',
    'ENABLE_WERROR': 'OFF',
})
vulkan_proj = cmake.subproject('vulkan-loader', options: opts)
vulkan_dep = vulkan_proj.dependency('vulkan')
meson.override_dependency('vulkan', vulkan_dep)
"@

# Create vulkan-loader wrap file if not exists
if (-not (Test-Path "$subprojects/vulkan-loader.wrap")) {
    Set-Content -Path "$subprojects/vulkan-loader.wrap" -Value @"
[wrap-git]
directory = vulkan-loader
url = https://github.com/KhronosGroup/Vulkan-Loader
revision = v1.3.285
depth = 1
clone-recursive = true
"@
}

# Create spirv-cross wrap file if not exists
if (-not (Test-Path "$subprojects/spirv-cross.wrap")) {
    Set-Content -Path "$subprojects/spirv-cross.wrap" -Value @"
[wrap-git]
directory = spirv-cross
url = https://github.com/KhronosGroup/SPIRV-Cross.git
revision = vulkan-sdk-1.3.290.0
depth = 1
"@
}

# Set wrap_mode override for projects that use git clone
$projects = Get-ChildItem -Path $subprojects -Directory -Filter "*_cmake"
foreach ($project in $projects) {
    $mesonBuild = Join-Path $project.FullName "meson.build"
    if (Test-Path $mesonBuild) {
        $content = Get-Content -Path $mesonBuild -Raw
        if ($content -match "clone-recursive\s*=\s*false") {
            $content = $content -replace "clone-recursive\s*=\s*false", "clone-recursive = true"
            Set-Content -Path $mesonBuild -Value $content
        }
    }
}

$BUILD_DIR = "build\windows\$Arch"

Write-Host "Running meson setup..."
meson setup $BUILD_DIR `
    --wrap-mode=forcefallback `
    --buildtype=release `
    -Ddefault_library=shared `
    -Dlibmpv=true `
    -Dcplayer=false `
    -Dtests=false `
    -Dgpl=true `
    -Dffmpeg:gpl=enabled `
    -Dffmpeg:tests=disabled `
    -Dffmpeg:programs=disabled `
    -Dffmpeg:sdl2=disabled `
    -Dffmpeg:vulkan=auto `
    -Dffmpeg:libdav1d=enabled `
    -Dffmpeg:libjxl=enabled `
    -Dffmpeg:libaom=enabled `
    -Dlcms2:fastfloat=true `
    -Dlcms2:jpeg=disabled `
    -Dlcms2:tiff=disabled `
    -Dlibass:test=disabled `
    -Dlibjpeg-turbo:tests=disabled `
    -Dlibusb:tests=false `
    -Dlibusb:examples=false `
    -Dlibplacebo:demos=false `
    -Dlibplacebo:lcms=enabled `
    -Dlibplacebo:shaderc=enabled `
    -Dlibplacebo:tests=false `
    -Dlibplacebo:vulkan=enabled `
    -Dlibplacebo:d3d11=enabled `
    -Dxxhash:inline-all=true `
    -Dxxhash:cli=false `
    -Dd3d11=enabled `
    -Dvulkan=enabled `
    -Djavascript=enabled `
    -Dwin32-smtc=enabled `
    -Dlua=disabled `
    -Ddrm=disabled `
    -Dlibarchive=disabled `
    -Drubberband=disabled `
    -Dwayland=disabled `
    -Dx11=disabled `
    --prefix="$((Get-Location).Path)\..\prefix\windows\$Arch"

Write-Host "Building libmpv..."
ninja -C $BUILD_DIR libmpv-2.dll

# Copy vulkan DLL if exists
$vulkanSrc = "$BUILD_DIR\subprojects\vulkan-loader\vulkan.dll"
if (Test-Path $vulkanSrc) {
    Copy-Item $vulkanSrc "$BUILD_DIR\vulkan-1.dll"
}

Write-Host "Installing..."
ninja -C $BUILD_DIR install

Write-Host "Windows build completed for $Arch"
