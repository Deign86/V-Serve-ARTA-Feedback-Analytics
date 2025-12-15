<#
Build and package V-Serve as a portable single EXE with embedded Release ZIP.
- Installs a local dotnet SDK if none found (uses the bundled dotnet-install.ps1)
- Ensures a multi-resolution `app_icon.ico` is copied to both the Flutter Windows runner and launcher
- Builds the Flutter Windows release (uses bundled flutter if present)
- Builds the launcher via `dotnet publish` (single-file, self-contained)
- Creates a ZIP of the Release runner and appends it with a marker to the launcher EXE
- Writes `V-Serve-Portable.exe` to the current user's Downloads folder

Usage:
  Open PowerShell (Administrator not required) and run:
    .\build_portable.ps1

Notes:
- Building Flutter Windows requires Visual Studio Build Tools and the required workloads installed.
- This script performs long-running builds; be patient.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Log { Write-Host "[build_portable] $args" }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Resolve-Path "$ScriptDir\..\.." | Select-Object -ExpandProperty Path

$LauncherDir = $ScriptDir
$LauncherProj = Join-Path $LauncherDir 'VServeLauncher.csproj'
$LauncherPublishDir = Join-Path $LauncherDir 'publish'
$LocalDotnetInstall = Join-Path $env:LOCALAPPDATA 'Microsoft\dotnet'
$DotnetInstallScript = Join-Path $LauncherDir 'dotnet-install.ps1'

$FrontendResources = Join-Path $RepoRoot 'frontend\arta_css\windows\runner\resources'
$FrontendBuildRelease = Join-Path $RepoRoot 'frontend\arta_css\build\windows\x64\runner\Release'
$FlutterBundled = Join-Path $RepoRoot 'flutter\bin\flutter.bat'

$LauncherIcon = Join-Path $LauncherDir 'app_icon.ico'
$FrontendIcon = Join-Path $FrontendResources 'app_icon.ico'

$TempZip = Join-Path $LauncherDir 'app.zip'
$Marker = 'VSSFXZIPMARKER_v1'
$OutPortable = Join-Path $env:USERPROFILE 'Downloads\V-Serve-Portable.exe'

try {
    Log "Starting portable build at $(Get-Date)"

    # Ensure icon: prefer the high-res icon already in frontend resources; if present, copy to launcher.
    if (Test-Path $FrontendIcon) {
        Log "Copying high-res icon from frontend resources to launcher"
        Copy-Item -Path $FrontendIcon -Destination $LauncherIcon -Force
    }
    elseif (Test-Path $LauncherIcon) {
        Log "Using existing launcher icon and copying to frontend resources (creating resources dir if needed)"
        if (-not (Test-Path $FrontendResources)) { New-Item -ItemType Directory -Path $FrontendResources -Force | Out-Null }
        Copy-Item -Path $LauncherIcon -Destination $FrontendIcon -Force
    }
    else {
        Write-Warning "No `app_icon.ico` found in either launcher or frontend resources. Icon embedding step will be skipped."
    }

    # Ensure dotnet SDK available; prefer system dotnet, otherwise install locally using the bundle script
    $dotnetExe = 'dotnet'
    $sdks = & $dotnetExe --list-sdks 2>$null | Out-String
    if ([string]::IsNullOrWhiteSpace($sdks)) {
        if (-not (Test-Path $DotnetInstallScript)) { throw "dotnet not found and install script missing: $DotnetInstallScript" }
        Log "No .NET SDKs detected. Installing local SDK via dotnet-install.ps1 (Channel 9.0 GA)"
        & powershell -NoProfile -ExecutionPolicy Bypass -File $DotnetInstallScript -Channel 9.0 -Quality GA -InstallDir $LocalDotnetInstall
        $dotnetExe = Join-Path $LocalDotnetInstall 'dotnet.exe'
        if (-not (Test-Path $dotnetExe)) { throw "Local dotnet install failed or dotnet.exe not found at $dotnetExe" }
    }
    else {
        Log ".NET SDK detected: $($sdks.Trim())"
    }

    # Build the Flutter Windows release if flutter is present
    $FrontendProjectDir = Join-Path $RepoRoot 'frontend\arta_css'
    if (Test-Path $FlutterBundled) {
        Log "Building Flutter Windows release using bundled flutter from project dir $FrontendProjectDir"
        Push-Location $FrontendProjectDir
        try {
            & $FlutterBundled build windows --release
            Log "Flutter build completed"
        }
        finally {
            Pop-Location
        }
    }
    elseif (Get-Command flutter -ErrorAction SilentlyContinue) {
        Log "Using system 'flutter' command to build Windows release from $FrontendProjectDir"
        Push-Location $FrontendProjectDir
        try {
            flutter build windows --release
            Log "Flutter build completed"
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Warning "Flutter not found; skipping Flutter build. Ensure `frontend/arta_css/build/windows/x64/runner/Release` exists before packaging."
    }

    if (-not (Test-Path $FrontendBuildRelease)) { throw "Release folder not found: $FrontendBuildRelease. Build the Flutter windows runner first." }

    # Create ZIP of release
    if (Test-Path $TempZip) { Remove-Item $TempZip -Force }
    Log "Creating ZIP of Release folder"
    Compress-Archive -Path (Join-Path $FrontendBuildRelease '*') -DestinationPath $TempZip -CompressionLevel Optimal -Force
    if (-not (Test-Path $TempZip)) { throw "Failed to create ZIP at $TempZip" }

    # Publish launcher
    Log "Publishing launcher (single-file, self-contained)"
    if (Test-Path $LauncherPublishDir) { Remove-Item $LauncherPublishDir -Recurse -Force }
    & $dotnetExe publish $LauncherProj -c Release -r win-x64 -p:PublishSingleFile=true -p:SelfContained=true -p:PublishTrimmed=false -o $LauncherPublishDir
    $launcherExe = Join-Path $LauncherPublishDir 'VServeLauncher.exe'
    if (-not (Test-Path $launcherExe)) { throw "Launcher publish did not produce $launcherExe" }

    # Combine launcher + marker + zip
    Log "Appending ZIP to launcher with marker and writing to $OutPortable"
    $launcherBytes = [System.IO.File]::ReadAllBytes($launcherExe)
    $markerBytes = [System.Text.Encoding]::UTF8.GetBytes($Marker)
    $zipBytes = [System.IO.File]::ReadAllBytes($TempZip)

    $combined = New-Object byte[] ($launcherBytes.Length + $markerBytes.Length + $zipBytes.Length)
    [Array]::Copy($launcherBytes,0,$combined,0,$launcherBytes.Length)
    [Array]::Copy($markerBytes,0,$combined,$launcherBytes.Length,$markerBytes.Length)
    [Array]::Copy($zipBytes,0,$combined,$launcherBytes.Length + $markerBytes.Length,$zipBytes.Length)
    [System.IO.File]::WriteAllBytes($OutPortable,$combined)

    Log "Portable exe written to: $OutPortable"
    $info = Get-Item $OutPortable | Select-Object Name,Length,FullName
    $info | Format-List

    Log "Cleaning temporary ZIP"
    Remove-Item $TempZip -Force

        # Try to refresh Windows shell icons so updated icon appears in Taskbar/Explorer
        try {
            Log "Refreshing Windows Explorer to pick up the new icon"
            Stop-Process -Name explorer -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            Start-Process explorer.exe
        }
        catch {
            Write-Warning "Failed to restart Explorer to refresh icons: $($_.Exception.Message)"
        }

    Log "Done"
}
catch {
    Write-Error "Build failed: $($_.Exception.Message)"
    exit 1
}

exit 0
