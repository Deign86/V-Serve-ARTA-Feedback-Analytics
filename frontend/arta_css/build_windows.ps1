# build_windows.ps1 - Build script for Windows that excludes Firebase
# Firebase C++ SDK has compatibility issues - requires Visual Studio Build Tools 2022
# This script temporarily modifies pubspec.yaml and main.dart to exclude Firebase

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pubspecPath = Join-Path $projectDir "pubspec.yaml"
$mainDartPath = Join-Path $projectDir "lib\main.dart"
$firebaseOptionsPath = Join-Path $projectDir "lib\firebase_options.dart"
$pubspecBackup = Join-Path $projectDir "pubspec.yaml.bak"
$mainDartBackup = Join-Path $projectDir "lib\main.dart.bak"
$firebaseOptionsBackup = Join-Path $projectDir "lib\firebase_options.dart.bak"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Building V-Serve for Windows" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Note: Firebase disabled (using HTTP services)" -ForegroundColor Yellow
Write-Host ""

# Backup original files
Write-Host "Backing up original files..." -ForegroundColor Gray
Copy-Item $pubspecPath $pubspecBackup -Force
Copy-Item $mainDartPath $mainDartBackup -Force
Copy-Item $firebaseOptionsPath $firebaseOptionsBackup -Force

# Modify pubspec.yaml - comment out Firebase dependencies
$pubspec = Get-Content $pubspecPath -Raw
$pubspec = $pubspec -replace '(\s+)(firebase_core:\s+\^[\d.]+)', '$1# $2  # Disabled for Windows'
$pubspec = $pubspec -replace '(\s+)(cloud_firestore:\s+\^[\d.]+)', '$1# $2  # Disabled for Windows'
Set-Content $pubspecPath $pubspec

# Modify main.dart - comment out Firebase imports and initialization
$mainDart = Get-Content $mainDartPath -Raw
$mainDart = $mainDart -replace "import 'package:firebase_core/firebase_core.dart';", "// import 'package:firebase_core/firebase_core.dart';  // Disabled for Windows"
$mainDart = $mainDart -replace "import 'firebase_options.dart';", "// import 'firebase_options.dart';  // Disabled for Windows"
Set-Content $mainDartPath $mainDart

# Create a minimal firebase_options.dart stub
$stubContent = @"
// Stub file for Windows build - Firebase disabled
// Firebase C++ SDK requires Visual Studio Build Tools 2022

class DefaultFirebaseOptions {
  static dynamic get currentPlatform => null;
}
"@
Set-Content $firebaseOptionsPath $stubContent

try {
    # Clean and get dependencies
    Write-Host "Cleaning project..." -ForegroundColor Gray
    & "$projectDir\..\..\flutter\bin\flutter.bat" clean
    
    Write-Host "Getting dependencies..." -ForegroundColor Gray
    & "$projectDir\..\..\flutter\bin\flutter.bat" pub get
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get dependencies"
    }
    
    # Build Windows release
    Write-Host "Building Windows release..." -ForegroundColor Gray
    & "$projectDir\..\..\flutter\bin\flutter.bat" build windows --release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "======================================" -ForegroundColor Green
        Write-Host "Build successful!" -ForegroundColor Green
        Write-Host "======================================" -ForegroundColor Green
        Write-Host "Output: $projectDir\build\windows\x64\runner\Release" -ForegroundColor Green
    } else {
        throw "Build failed with exit code $LASTEXITCODE"
    }
}
catch {
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Red
    Write-Host "Build failed: $_" -ForegroundColor Red
    Write-Host "======================================" -ForegroundColor Red
}
finally {
    # Restore original files
    Write-Host ""
    Write-Host "Restoring original files..." -ForegroundColor Gray
    Move-Item $pubspecBackup $pubspecPath -Force
    Move-Item $mainDartBackup $mainDartPath -Force
    Move-Item $firebaseOptionsBackup $firebaseOptionsPath -Force
    
    # Restore dependencies for other platforms
    Write-Host "Restoring dependencies..." -ForegroundColor Gray
    & "$projectDir\..\..\flutter\bin\flutter.bat" pub get 2>$null | Out-Null
    Write-Host "Done." -ForegroundColor Gray
}

