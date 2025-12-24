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

# Import Visual Studio DevShell module
$devShellDll = Join-Path $vsPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
Write-Host "Loading Visual Studio DevShell from: $devShellDll"
Import-Module $devShellDll

# Set architecture for VS environment
$vsArch = if ($Arch -eq "x86_64") { "amd64" } else { $Arch }

Write-Host "Entering Visual Studio developer shell for $vsArch..."
Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation -DevCmdArguments "-arch=$vsArch -host_arch=amd64"

Write-Host "Visual Studio environment loaded."

# Change to MPV directory
Set-Location .cache\mpv

# Get current directory for prefix
$prefixPath = (Get-Location).Path + "\..\prefix\windows\$Arch"

# Run meson setup
Write-Host "Configuring build for Windows $Arch..."
meson setup "build\windows\$Arch" `
    --default-library=shared `
    --buildtype=release `
    -Dwrap_mode=forcefallback `
    -Dlibmpv=true `
    -Dgpl=true `
    -Dshaderc=disabled `
    -Dharfbuzz:icu=disabled `
    -Dlibass:require-system-font-provider=false `
    -DFFmpeg:gpl=enabled `
    -DFFmpeg:version3=enabled `
    -DFFmpeg:tls_protocol=enabled `
    --prefix="$prefixPath"

Write-Host "Windows build configured for $Arch"
