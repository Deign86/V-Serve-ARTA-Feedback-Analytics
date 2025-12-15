<#
.SYNOPSIS
    Unified build script for V-Serve ARTA Feedback Analytics application.
    Builds Web, Windows desktop, and Android APK targets in one command.

.DESCRIPTION
    This PowerShell script automates building all three deployment targets for the
    V-Serve Flutter application:
    - Web app (Flutter web build) - includes admin features
    - Windows portable .exe (using the C# portable launcher) - includes admin features
    - Android APK (release build) - user-only mode (admin disabled)

    All build artifacts are collected into a clean 'builds/' directory at repo root.

.PARAMETER Mode
    Build mode. Currently only "Release" is supported. Default: "Release"

.PARAMETER SkipWeb
    Skip building the web target.

.PARAMETER SkipWindows
    Skip building the Windows desktop target.

.PARAMETER SkipAndroid
    Skip building the Android APK target.

.PARAMETER NoClean
    Skip running 'flutter clean' before building. By default, clean runs automatically.

.EXAMPLE
    .\scripts\build-all.ps1 -Mode Release
    Builds all three targets in Release mode.

.EXAMPLE
    .\scripts\build-all.ps1 -SkipAndroid -SkipWeb
    Builds only the Windows desktop target.

.EXAMPLE
    .\scripts\build-all.ps1 -NoClean
    Builds all targets without running flutter clean first.

.NOTES
    Requirements:
    - Windows 11 with PowerShell 5+
    - Visual Studio 2022 Build Tools (for Windows builds)
    - .NET SDK 8.0+ (for portable launcher; will auto-install if missing)
    - Android SDK and Java (for Android builds)
    - Flutter SDK (bundled at ./flutter or in PATH)

    Build modes:
    - Web/Windows: Full app with admin features
    - Android: User-only mode (admin features disabled)

    Author: V-Serve Development Team
    Last Updated: December 2025
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Release")]
    [string]$Mode = "Release",

    [Parameter()]
    [switch]$SkipWeb,

    [Parameter()]
    [switch]$SkipWindows,

    [Parameter()]
    [switch]$SkipAndroid,

    [Parameter()]
    [switch]$NoClean
)

# ==============================================================================
# STRICT MODE AND ERROR HANDLING
# ==============================================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ==============================================================================
# GLOBAL VARIABLES
# ==============================================================================
$script:RepoRoot = $null
$script:FlutterCmd = $null
$script:FrontendDir = $null
$script:BuildsDir = $null
$script:BuildResults = @{
    Web = @{ Success = $false; Path = $null; Skipped = $false }
    Windows = @{ Success = $false; Path = $null; PortablePath = $null; ZipPath = $null; Skipped = $false }
    Android = @{ Success = $false; Path = $null; Skipped = $false }
}

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

<#
.SYNOPSIS
    Writes a colored log message to the console.
#>
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "OK", "WARN", "ERROR", "SECTION")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    switch ($Level) {
        "INFO"    { Write-Host "[$timestamp] [INFO]  " -ForegroundColor Cyan -NoNewline; Write-Host $Message }
        "OK"      { Write-Host "[$timestamp] [OK]    " -ForegroundColor Green -NoNewline; Write-Host $Message }
        "WARN"    { Write-Host "[$timestamp] [WARN]  " -ForegroundColor Yellow -NoNewline; Write-Host $Message }
        "ERROR"   { Write-Host "[$timestamp] [ERROR] " -ForegroundColor Red -NoNewline; Write-Host $Message }
        "SECTION" { 
            Write-Host ""
            Write-Host ("=" * 70) -ForegroundColor Magenta
            Write-Host "  $Message" -ForegroundColor Magenta
            Write-Host ("=" * 70) -ForegroundColor Magenta
        }
    }
}

<#
.SYNOPSIS
    Safely invokes a command and captures errors.
.DESCRIPTION
    Wraps command execution with proper error handling and logging.
.PARAMETER ScriptBlock
    The script block to execute.
.PARAMETER ErrorMessage
    Custom error message to display on failure.
.PARAMETER SuggestedFix
    Suggested fix to display on failure.
#>
function Invoke-CommandSafe {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [string]$ErrorMessage = "Command failed",
        
        [Parameter()]
        [string]$SuggestedFix = ""
    )
    
    try {
        & $ScriptBlock
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "Command exited with code $LASTEXITCODE"
        }
        return $true
    }
    catch {
        Write-Log $ErrorMessage -Level ERROR
        Write-Log "Details: $($_.Exception.Message)" -Level ERROR
        if ($SuggestedFix) {
            Write-Log "Suggested fix: $SuggestedFix" -Level WARN
        }
        return $false
    }
}

<#
.SYNOPSIS
    Detects the Flutter binary to use.
.DESCRIPTION
    Checks for bundled Flutter SDK first, then falls back to system PATH.
.RETURNS
    Path to flutter command/batch file.
#>
function Select-FlutterBinary {
    # Check for bundled Flutter first (preferred for version consistency)
    $bundledFlutter = Join-Path $script:RepoRoot "flutter\bin\flutter.bat"
    
    if (Test-Path $bundledFlutter) {
        Write-Log "Using bundled Flutter SDK at: $bundledFlutter" -Level INFO
        return $bundledFlutter
    }
    
    # Fall back to system Flutter
    $systemFlutter = Get-Command flutter -ErrorAction SilentlyContinue
    if ($systemFlutter) {
        Write-Log "Using system Flutter from PATH: $($systemFlutter.Source)" -Level INFO
        return "flutter"
    }
    
    return $null
}

<#
.SYNOPSIS
    Copies build artifacts to the output directory.
.PARAMETER Source
    Source path (file or directory).
.PARAMETER Destination
    Destination path.
.PARAMETER IsDirectory
    Whether the source is a directory.
#>
function Copy-Artifacts {
    param(
        [Parameter(Mandatory)]
        [string]$Source,
        
        [Parameter(Mandatory)]
        [string]$Destination,
        
        [Parameter()]
        [switch]$IsDirectory
    )
    
    # Ensure destination parent directory exists
    $destParent = Split-Path -Parent $Destination
    if (-not (Test-Path $destParent)) {
        New-Item -ItemType Directory -Path $destParent -Force | Out-Null
    }
    
    if ($IsDirectory) {
        if (Test-Path $Destination) {
            Remove-Item $Destination -Recurse -Force
        }
        Copy-Item -Path $Source -Destination $Destination -Recurse -Force
    }
    else {
        Copy-Item -Path $Source -Destination $Destination -Force
    }
    
    Write-Log "Copied: $Source -> $Destination" -Level OK
}

<#
.SYNOPSIS
    Checks if Visual Studio 2022 Build Tools are installed.
#>
function Test-VSBuildTools {
    $vsWherePaths = @(
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\Installer\vswhere.exe"
    )
    
    foreach ($vsWhere in $vsWherePaths) {
        if (Test-Path $vsWhere) {
            $vsInstalls = & $vsWhere -version "[17.0,18.0)" -requires Microsoft.VisualStudio.Workload.VCTools -property installationPath 2>$null
            if ($vsInstalls) {
                Write-Log "Found VS 2022 Build Tools: $vsInstalls" -Level OK
                return $true
            }
        }
    }
    
    # Also check for standalone Build Tools
    $buildToolsPaths = @(
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\BuildTools",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\Community",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\Professional",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional"
    )
    
    foreach ($path in $buildToolsPaths) {
        if (Test-Path $path) {
            Write-Log "Found VS 2022 installation: $path" -Level OK
            return $true
        }
    }
    
    return $false
}

<#
.SYNOPSIS
    Checks if Android SDK and Java are available.
#>
function Test-AndroidEnvironment {
    $hasJava = $false
    $hasAndroidSdk = $false
    
    # Check Java - first try system PATH
    try {
        $javaVersion = & java -version 2>&1 | Out-String
        if ($javaVersion) {
            $hasJava = $true
            Write-Log "Java found in PATH" -Level OK
        }
    }
    catch {
        # Check if Flutter's bundled JDK exists (Android Studio or Flutter SDK)
        $flutterJdkPaths = @(
            "$env:LOCALAPPDATA\Android\Sdk\jdk",
            "$env:ANDROID_HOME\jdk",
            (Join-Path $script:RepoRoot "flutter\jre"),
            "$env:ProgramFiles\Android\Android Studio\jre",
            "$env:ProgramFiles\Android\Android Studio\jbr"
        )
        
        foreach ($jdkPath in $flutterJdkPaths) {
            if ($jdkPath -and (Test-Path $jdkPath)) {
                $hasJava = $true
                Write-Log "Java found (bundled): $jdkPath" -Level OK
                break
            }
        }
        
        if (-not $hasJava) {
            # Flutter uses Gradle which bundles its own JDK - build will likely work
            Write-Log "Java not in PATH (Flutter/Gradle may use bundled JDK)" -Level INFO
            $hasJava = $true  # Assume it will work via Gradle
        }
    }
    
    # Check ANDROID_HOME or ANDROID_SDK_ROOT
    $androidHome = $env:ANDROID_HOME
    if (-not $androidHome) {
        $androidHome = $env:ANDROID_SDK_ROOT
    }
    
    if ($androidHome -and (Test-Path $androidHome)) {
        $hasAndroidSdk = $true
        Write-Log "Android SDK found at: $androidHome" -Level OK
    }
    else {
        # Check common locations
        $commonPaths = @(
            "$env:LOCALAPPDATA\Android\Sdk",
            "$env:USERPROFILE\AppData\Local\Android\Sdk",
            "C:\Android\sdk"
        )
        foreach ($path in $commonPaths) {
            if (Test-Path $path) {
                $hasAndroidSdk = $true
                Write-Log "Android SDK found at: $path" -Level OK
                break
            }
        }
    }
    
    if (-not $hasAndroidSdk) {
        Write-Log "Android SDK not found" -Level WARN
    }
    
    return ($hasJava -and $hasAndroidSdk)
}

<#
.SYNOPSIS
    Ensures .NET SDK is available for portable launcher build.
.RETURNS
    Path to dotnet executable.
#>
function Get-DotNetSdk {
    $dotnetExe = "dotnet"
    
    # Check if dotnet is available
    try {
        $sdks = & $dotnetExe --list-sdks 2>$null | Out-String
        if (-not [string]::IsNullOrWhiteSpace($sdks)) {
            Write-Log ".NET SDK found: $($sdks.Trim().Split("`n")[0])" -Level OK
            return $dotnetExe
        }
    }
    catch { }
    
    # Try to install locally using the bundled script
    $installScript = Join-Path $script:RepoRoot "tools\portable_launcher_cs\dotnet-install.ps1"
    $localDotnet = Join-Path $env:LOCALAPPDATA "Microsoft\dotnet\dotnet.exe"
    
    if (Test-Path $localDotnet) {
        Write-Log "Using locally installed .NET SDK" -Level INFO
        return $localDotnet
    }
    
    if (Test-Path $installScript) {
        Write-Log "Installing .NET SDK locally..." -Level INFO
        & powershell -NoProfile -ExecutionPolicy Bypass -File $installScript -Channel 8.0 -Quality GA -InstallDir (Join-Path $env:LOCALAPPDATA "Microsoft\dotnet")
        
        if (Test-Path $localDotnet) {
            Write-Log ".NET SDK installed successfully" -Level OK
            return $localDotnet
        }
    }
    
    return $null
}

# ==============================================================================
# BUILD FUNCTIONS
# ==============================================================================

<#
.SYNOPSIS
    Builds the Flutter web application.
#>
function Invoke-WebAppBuild {
    Write-Log "Building Web Application" -Level SECTION
    
    if ($SkipWeb) {
        Write-Log "Web build skipped by user request" -Level WARN
        $script:BuildResults.Web.Skipped = $true
        return $true
    }
    
    Push-Location $script:FrontendDir
    try {
        Write-Log "Running: flutter build web --release" -Level INFO
        
        $result = Invoke-CommandSafe -ScriptBlock {
            & $script:FlutterCmd build web --release
        } -ErrorMessage "Web build failed" -SuggestedFix "Run 'flutter doctor' to diagnose issues"
        
        if (-not $result) {
            return $false
        }
        
        # Copy web build to builds/web
        $webSource = Join-Path $script:FrontendDir "build\web"
        $webDest = Join-Path $script:BuildsDir "web"
        
        if (-not (Test-Path $webSource)) {
            Write-Log "Web build output not found at: $webSource" -Level ERROR
            return $false
        }
        
        Copy-Artifacts -Source $webSource -Destination $webDest -IsDirectory
        
        # Verify firebase-messaging-sw.js is present
        $swFile = Join-Path $webDest "firebase-messaging-sw.js"
        if (Test-Path $swFile) {
            Write-Log "Firebase service worker preserved: firebase-messaging-sw.js" -Level OK
        }
        else {
            Write-Log "Note: firebase-messaging-sw.js not found (may not be needed)" -Level WARN
        }
        
        $script:BuildResults.Web.Success = $true
        $script:BuildResults.Web.Path = $webDest
        
        Write-Log "Web build completed successfully!" -Level OK
        return $true
    }
    finally {
        Pop-Location
    }
}

<#
.SYNOPSIS
    Builds the Windows desktop application and portable launcher.
#>
function Invoke-WindowsAppBuild {
    Write-Log "Building Windows Desktop Application" -Level SECTION
    
    if ($SkipWindows) {
        Write-Log "Windows build skipped by user request" -Level WARN
        $script:BuildResults.Windows.Skipped = $true
        return $true
    }
    
    # Check VS Build Tools
    if (-not (Test-VSBuildTools)) {
        Write-Log "Visual Studio 2022 Build Tools not found!" -Level ERROR
        Write-Log "Install from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022" -Level WARN
        Write-Log "Required workload: 'Desktop development with C++'" -Level WARN
        return $false
    }
    
    Push-Location $script:FrontendDir
    try {
        # Add bundled NuGet to PATH to suppress "Nuget.exe not found" warning
        $nugetDir = Join-Path $script:RepoRoot "tools\nuget"
        if (Test-Path (Join-Path $nugetDir "nuget.exe")) {
            $env:PATH = "$nugetDir;$env:PATH"
            Write-Log "Using bundled NuGet from: $nugetDir" -Level INFO
        }
        
        # Windows always builds with admin enabled (no USER_ONLY_MODE)
        Write-Log "Running: flutter build windows --release" -Level INFO
        
        $result = Invoke-CommandSafe -ScriptBlock {
            & $script:FlutterCmd build windows --release
        } -ErrorMessage "Windows build failed" -SuggestedFix "Ensure VS 2022 Build Tools are installed with C++ workload"
        
        if (-not $result) {
            return $false
        }
        
        # Locate the built exe
        $releaseDir = Join-Path $script:FrontendDir "build\windows\x64\runner\Release"
        $exeSource = Join-Path $releaseDir "V-Serve.exe"
        
        if (-not (Test-Path $exeSource)) {
            Write-Log "Windows exe not found at: $exeSource" -Level ERROR
            return $false
        }
        
        # Create windows output directory
        $windowsDest = Join-Path $script:BuildsDir "windows"
        if (-not (Test-Path $windowsDest)) {
            New-Item -ItemType Directory -Path $windowsDest -Force | Out-Null
        }
        
        # Copy entire Release folder contents (exe + DLLs + data)
        Write-Log "Copying Windows release files..." -Level INFO
        Get-ChildItem -Path $releaseDir | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $windowsDest -Recurse -Force
        }
        
        $exeDest = Join-Path $windowsDest "V-Serve.exe"
        $script:BuildResults.Windows.Path = $exeDest
        
        Write-Log "V-Serve.exe copied to: $exeDest" -Level OK
        
        # Build portable launcher
        Write-Log "Building portable launcher..." -Level INFO
        $portableResult = Invoke-PortableLauncherBuild -ReleaseDir $releaseDir -OutputDir $windowsDest
        
        if ($portableResult) {
            $script:BuildResults.Windows.PortablePath = Join-Path $windowsDest "V-Serve-Portable.exe"
        }
        
        # Create ZIP archive
        Write-Log "Creating Windows ZIP archive..." -Level INFO
        $zipPath = Join-Path $script:BuildsDir "windows\V-Serve-windows.zip"
        if (Test-Path $zipPath) {
            Remove-Item $zipPath -Force
        }
        
        # Create a temp folder with just the app files for zipping
        $tempZipSource = Join-Path $env:TEMP "VServe-zip-temp"
        if (Test-Path $tempZipSource) {
            Remove-Item $tempZipSource -Recurse -Force
        }
        New-Item -ItemType Directory -Path $tempZipSource -Force | Out-Null
        
        # Copy release files to temp (excluding the portable exe and zip)
        Get-ChildItem -Path $releaseDir | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $tempZipSource -Recurse -Force
        }
        
        Compress-Archive -Path (Join-Path $tempZipSource "*") -DestinationPath $zipPath -CompressionLevel Optimal -Force
        Remove-Item $tempZipSource -Recurse -Force
        
        if (Test-Path $zipPath) {
            $script:BuildResults.Windows.ZipPath = $zipPath
            Write-Log "ZIP archive created: $zipPath" -Level OK
        }
        
        $script:BuildResults.Windows.Success = $true
        Write-Log "Windows build completed successfully!" -Level OK
        return $true
    }
    finally {
        Pop-Location
    }
}

<#
.SYNOPSIS
    Builds the portable launcher executable.
.PARAMETER ReleaseDir
    Path to the Flutter Windows release directory.
.PARAMETER OutputDir
    Output directory for the portable exe.
#>
function Invoke-PortableLauncherBuild {
    param(
        [Parameter(Mandatory)]
        [string]$ReleaseDir,
        
        [Parameter(Mandatory)]
        [string]$OutputDir
    )
    
    $launcherDir = Join-Path $script:RepoRoot "tools\portable_launcher_cs"
    $launcherProj = Join-Path $launcherDir "VServeLauncher.csproj"
    
    if (-not (Test-Path $launcherProj)) {
        Write-Log "Portable launcher project not found at: $launcherProj" -Level WARN
        return $false
    }
    
    # Get .NET SDK
    $dotnetExe = Get-DotNetSdk
    if (-not $dotnetExe) {
        Write-Log ".NET SDK not available for portable launcher build" -Level WARN
        Write-Log "Install .NET 8.0+ SDK from: https://dotnet.microsoft.com/download" -Level WARN
        return $false
    }
    
    try {
        # Create temp ZIP of release folder
        $tempZip = Join-Path $launcherDir "app.zip"
        if (Test-Path $tempZip) {
            Remove-Item $tempZip -Force
        }
        
        Write-Log "Creating temporary ZIP of release folder..." -Level INFO
        Compress-Archive -Path (Join-Path $ReleaseDir "*") -DestinationPath $tempZip -CompressionLevel Optimal -Force
        
        # Publish the launcher
        $publishDir = Join-Path $launcherDir "publish"
        if (Test-Path $publishDir) {
            Remove-Item $publishDir -Recurse -Force
        }
        
        Write-Log "Publishing launcher (single-file, self-contained)..." -Level INFO
        $publishResult = Invoke-CommandSafe -ScriptBlock {
            & $dotnetExe publish $launcherProj -c Release -r win-x64 -p:PublishSingleFile=true -p:SelfContained=true -p:PublishTrimmed=false -o $publishDir
        } -ErrorMessage "Launcher publish failed" -SuggestedFix "Ensure .NET 8.0+ SDK is installed"
        
        if (-not $publishResult) {
            return $false
        }
        
        $launcherExe = Join-Path $publishDir "VServeLauncher.exe"
        if (-not (Test-Path $launcherExe)) {
            Write-Log "Launcher exe not found after publish" -Level ERROR
            return $false
        }
        
        # Combine launcher + marker + zip
        $marker = "VSSFXZIPMARKER_v1"
        $outPortable = Join-Path $OutputDir "V-Serve-Portable.exe"
        
        Write-Log "Creating portable executable..." -Level INFO
        $launcherBytes = [System.IO.File]::ReadAllBytes($launcherExe)
        $markerBytes = [System.Text.Encoding]::UTF8.GetBytes($marker)
        $zipBytes = [System.IO.File]::ReadAllBytes($tempZip)
        
        $combined = New-Object byte[] ($launcherBytes.Length + $markerBytes.Length + $zipBytes.Length)
        [Array]::Copy($launcherBytes, 0, $combined, 0, $launcherBytes.Length)
        [Array]::Copy($markerBytes, 0, $combined, $launcherBytes.Length, $markerBytes.Length)
        [Array]::Copy($zipBytes, 0, $combined, $launcherBytes.Length + $markerBytes.Length, $zipBytes.Length)
        [System.IO.File]::WriteAllBytes($outPortable, $combined)
        
        # Cleanup
        Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
        
        if (Test-Path $outPortable) {
            $fileInfo = Get-Item $outPortable
            Write-Log "Portable exe created: $outPortable ($([math]::Round($fileInfo.Length / 1MB, 2)) MB)" -Level OK
            return $true
        }
        
        return $false
    }
    catch {
        Write-Log "Portable launcher build failed: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

<#
.SYNOPSIS
    Builds the Android APK.
#>
function Invoke-AndroidApkBuild {
    Write-Log "Building Android APK" -Level SECTION
    
    if ($SkipAndroid) {
        Write-Log "Android build skipped by user request" -Level WARN
        $script:BuildResults.Android.Skipped = $true
        return $true
    }
    
    # Check Android environment (informational only - Flutter handles most of it)
    $null = Test-AndroidEnvironment
    
    Push-Location $script:FrontendDir
    try {
        # Build Flutter Android APK - always in user-only mode (admin disabled)
        Write-Log "Building with USER_ONLY_MODE=true (admin features disabled)" -Level INFO
        Write-Log "Running: flutter build apk --release --dart-define=USER_ONLY_MODE=true" -Level INFO
        
        $result = Invoke-CommandSafe -ScriptBlock {
            & $script:FlutterCmd build apk --release --dart-define=USER_ONLY_MODE=true
        } -ErrorMessage "Android APK build failed" -SuggestedFix "Run 'flutter doctor' and ensure Android SDK is configured"
        
        if (-not $result) {
            return $false
        }
        
        # Locate the built APK
        $apkSource = Join-Path $script:FrontendDir "build\app\outputs\flutter-apk\app-release.apk"
        
        if (-not (Test-Path $apkSource)) {
            Write-Log "APK not found at: $apkSource" -Level ERROR
            return $false
        }
        
        # Copy APK to builds/android
        $androidDest = Join-Path $script:BuildsDir "android"
        if (-not (Test-Path $androidDest)) {
            New-Item -ItemType Directory -Path $androidDest -Force | Out-Null
        }
        
        $apkDest = Join-Path $androidDest "app-release.apk"
        Copy-Artifacts -Source $apkSource -Destination $apkDest
        
        # Also copy with version name if desired
        $versionedApk = Join-Path $androidDest "V-Serve-release.apk"
        Copy-Item -Path $apkSource -Destination $versionedApk -Force
        
        $script:BuildResults.Android.Success = $true
        $script:BuildResults.Android.Path = $apkDest
        
        $apkInfo = Get-Item $apkDest
        Write-Log "APK size: $([math]::Round($apkInfo.Length / 1MB, 2)) MB" -Level INFO
        Write-Log "Android build completed successfully!" -Level OK
        return $true
    }
    finally {
        Pop-Location
    }
}

<#
.SYNOPSIS
    Prints a summary of build results.
#>
function Write-BuildSummary {
    Write-Log "Build Summary" -Level SECTION
    
    $totalTime = (Get-Date) - $script:StartTime
    Write-Log "Total build time: $($totalTime.ToString('hh\:mm\:ss'))" -Level INFO
    Write-Log "Mode: $Mode" -Level INFO
    Write-Host ""
    
    # Build results table
    Write-Host "  Target       Status        Output Path" -ForegroundColor White
    Write-Host "  ------       ------        -----------" -ForegroundColor Gray
    
    # Web
    if ($script:BuildResults.Web.Skipped) {
        Write-Host "  Web          " -NoNewline; Write-Host "SKIPPED" -ForegroundColor Yellow -NoNewline; Write-Host "       (by request)"
    }
    elseif ($script:BuildResults.Web.Success) {
        Write-Host "  Web          " -NoNewline; Write-Host "SUCCESS" -ForegroundColor Green -NoNewline; Write-Host "       $($script:BuildResults.Web.Path)"
    }
    else {
        Write-Host "  Web          " -NoNewline; Write-Host "FAILED" -ForegroundColor Red
    }
    
    # Windows
    if ($script:BuildResults.Windows.Skipped) {
        Write-Host "  Windows      " -NoNewline; Write-Host "SKIPPED" -ForegroundColor Yellow -NoNewline; Write-Host "       (by request)"
    }
    elseif ($script:BuildResults.Windows.Success) {
        Write-Host "  Windows      " -NoNewline; Write-Host "SUCCESS" -ForegroundColor Green -NoNewline; Write-Host "       $($script:BuildResults.Windows.Path)"
        if ($script:BuildResults.Windows.PortablePath -and (Test-Path $script:BuildResults.Windows.PortablePath)) {
            Write-Host "               " -NoNewline; Write-Host "         " -NoNewline; Write-Host "       $($script:BuildResults.Windows.PortablePath)" -ForegroundColor Cyan
        }
        if ($script:BuildResults.Windows.ZipPath -and (Test-Path $script:BuildResults.Windows.ZipPath)) {
            Write-Host "               " -NoNewline; Write-Host "         " -NoNewline; Write-Host "       $($script:BuildResults.Windows.ZipPath)" -ForegroundColor Cyan
        }
    }
    else {
        Write-Host "  Windows      " -NoNewline; Write-Host "FAILED" -ForegroundColor Red
    }
    
    # Android
    if ($script:BuildResults.Android.Skipped) {
        Write-Host "  Android      " -NoNewline; Write-Host "SKIPPED" -ForegroundColor Yellow -NoNewline; Write-Host "       (by request)"
    }
    elseif ($script:BuildResults.Android.Success) {
        Write-Host "  Android      " -NoNewline; Write-Host "SUCCESS" -ForegroundColor Green -NoNewline; Write-Host "       $($script:BuildResults.Android.Path)"
    }
    else {
        Write-Host "  Android      " -NoNewline; Write-Host "FAILED" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Final status
    $enabledTargets = @()
    $failedTargets = @()
    
    if (-not $SkipWeb) { 
        $enabledTargets += "Web"
        if (-not $script:BuildResults.Web.Success) { $failedTargets += "Web" }
    }
    if (-not $SkipWindows) { 
        $enabledTargets += "Windows"
        if (-not $script:BuildResults.Windows.Success) { $failedTargets += "Windows" }
    }
    if (-not $SkipAndroid) { 
        $enabledTargets += "Android"
        if (-not $script:BuildResults.Android.Success) { $failedTargets += "Android" }
    }
    
    if ($failedTargets.Count -eq 0) {
        Write-Host "  All enabled builds completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Output directory: $script:BuildsDir" -ForegroundColor Cyan
    }
    else {
        Write-Host "  Failed targets: $($failedTargets -join ', ')" -ForegroundColor Red
    }
    
    Write-Host ""
    
    return ($failedTargets.Count -eq 0)
}

# ==============================================================================
# MAIN SCRIPT EXECUTION
# ==============================================================================

$script:StartTime = Get-Date

Write-Host ""
Write-Host "  +=====================================================================+" -ForegroundColor Cyan
Write-Host "  |                                                                     |" -ForegroundColor Cyan
Write-Host "  |       V-Serve ARTA Feedback Analytics - Build All Targets           |" -ForegroundColor Cyan
Write-Host "  |                                                                     |" -ForegroundColor Cyan
Write-Host "  +=====================================================================+" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# STEP 1: VALIDATE ENVIRONMENT
# ==============================================================================
Write-Log "Validating Environment" -Level SECTION

# Determine repo root (script should be in scripts/ folder)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:RepoRoot = Resolve-Path (Join-Path $scriptDir "..") | Select-Object -ExpandProperty Path

# Validate we're in the right repo
$pubspecPath = Join-Path $script:RepoRoot "frontend\arta_css\pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    Write-Log "Not running from V-Serve repo root!" -Level ERROR
    Write-Log "Expected to find: $pubspecPath" -Level ERROR
    Write-Log "Please run this script from the repository root directory" -Level WARN
    exit 1
}
Write-Log "Repo root: $script:RepoRoot" -Level OK

# Set other paths
$script:FrontendDir = Join-Path $script:RepoRoot "frontend\arta_css"
$script:BuildsDir = Join-Path $script:RepoRoot "builds"

# Ensure builds directory exists
if (-not (Test-Path $script:BuildsDir)) {
    New-Item -ItemType Directory -Path $script:BuildsDir -Force | Out-Null
    Write-Log "Created builds directory: $script:BuildsDir" -Level OK
}

# Find Flutter
$script:FlutterCmd = Select-FlutterBinary
if (-not $script:FlutterCmd) {
    Write-Log "Flutter SDK not found!" -Level ERROR
    Write-Log "Either install Flutter to PATH or ensure bundled SDK exists at: $script:RepoRoot\flutter" -Level WARN
    exit 1
}

# Verify Flutter works
Write-Log "Verifying Flutter installation..." -Level INFO
try {
    $flutterVersion = & $script:FlutterCmd --version 2>&1 | Select-Object -First 1
    Write-Log "Flutter: $flutterVersion" -Level OK
}
catch {
    Write-Log "Failed to run Flutter: $($_.Exception.Message)" -Level ERROR
    exit 1
}

# Display build configuration
Write-Host ""
Write-Host "  Build Configuration:" -ForegroundColor White
Write-Host "  - Mode:          $Mode" -ForegroundColor Gray
Write-Host "  - Build Web:     $(-not $SkipWeb)  (includes admin)" -ForegroundColor Gray
Write-Host "  - Build Win:     $(-not $SkipWindows)  (includes admin)" -ForegroundColor Gray
Write-Host "  - Build APK:     $(-not $SkipAndroid)  (user-only, no admin)" -ForegroundColor Gray
Write-Host ""

# ==============================================================================
# STEP 2: COMMON SETUP
# ==============================================================================
Write-Log "Common Setup" -Level SECTION

Push-Location $script:FrontendDir
try {
    # Clean unless -NoClean is specified
    if (-not $NoClean) {
        Write-Log "Running: flutter clean" -Level INFO
        $cleanResult = Invoke-CommandSafe -ScriptBlock {
            & $script:FlutterCmd clean
        } -ErrorMessage "flutter clean failed"
        
        if (-not $cleanResult) {
            Write-Log "Clean failed but continuing..." -Level WARN
        }
    }
    else {
        Write-Log "Skipping flutter clean (-NoClean specified)" -Level INFO
    }
    
    # Get dependencies
    Write-Log "Running: flutter pub get" -Level INFO
    $pubGetResult = Invoke-CommandSafe -ScriptBlock {
        & $script:FlutterCmd pub get
    } -ErrorMessage "flutter pub get failed" -SuggestedFix "Check your internet connection and pubspec.yaml"
    
    if (-not $pubGetResult) {
        Write-Log "Failed to get dependencies" -Level ERROR
        exit 1
    }
    
    Write-Log "Dependencies resolved" -Level OK
}
finally {
    Pop-Location
}

# ==============================================================================
# STEP 3: BUILD TARGETS
# ==============================================================================

$null = Invoke-WebAppBuild
$null = Invoke-WindowsAppBuild
$null = Invoke-AndroidApkBuild

# ==============================================================================
# STEP 4: SUMMARY AND EXIT
# ==============================================================================

$allSuccess = Write-BuildSummary

if ($allSuccess) {
    Write-Log "Build completed successfully!" -Level OK
    exit 0
}
else {
    Write-Log "Some builds failed. See above for details." -Level ERROR
    exit 1
}
