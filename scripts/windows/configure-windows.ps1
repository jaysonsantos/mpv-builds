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

# Apply Windows build patch
Write-Host "Applying Windows build patch..."
if (Test-Path "..\..\patches\windows\windows-build.patch") {
    patch -p1 -i "..\..\patches\windows\windows-build.patch"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Patch already applied or failed to apply"
    }
}

meson wrap update-db

$wraps = @("expat", "harfbuzz", "libpng", "zlib")
foreach ($wrap in $wraps) {
    meson wrap install $wrap
}

# Run mpv's build script
Write-Host "Running mpv build script for Windows $Arch..."
.\ci\build-win32.ps1

Write-Host "Windows build configured for $Arch"
