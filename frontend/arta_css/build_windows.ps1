# build_windows.ps1 - Build script for Windows
# Requires Visual Studio Build Tools 2022 with "Desktop development with C++"
# The codebase uses HTTP services and doesn't require Firebase

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Building V-Serve for Windows" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Using HTTP backend services (Firebase-free architecture)" -ForegroundColor Yellow
Write-Host ""

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
    exit 1
}

