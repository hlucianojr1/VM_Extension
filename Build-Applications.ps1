# Build-Applications.ps1
# This script builds both the Windows Service and Web Application projects

param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Building .NET 4.8 Applications" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Get the script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$solutionRoot = Split-Path -Parent $scriptPath

# Paths
$windowsServiceProject = Join-Path $solutionRoot "SampleWindowsService\MyWindowsService.csproj"
$webAppProject = Join-Path $solutionRoot "SampleWebApp\MyWebApp.csproj"
$deploymentSourceRoot = "C:\code\DeploymentSource"

Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Solution Root: $solutionRoot" -ForegroundColor Yellow
Write-Host ""

# Check if MSBuild is available
Write-Host "Checking for MSBuild..." -ForegroundColor Yellow
$msbuildPath = $null

# Try to find MSBuild
$msbuildPaths = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
)

foreach ($path in $msbuildPaths) {
    if (Test-Path $path) {
        $msbuildPath = $path
        break
    }
}

if (-not $msbuildPath) {
    # Try to use vswhere to find MSBuild
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
        if ($vsPath) {
            $msbuildPath = Join-Path $vsPath "MSBuild\Current\Bin\MSBuild.exe"
            if (-not (Test-Path $msbuildPath)) {
                $msbuildPath = Join-Path $vsPath "MSBuild\15.0\Bin\MSBuild.exe"
            }
        }
    }
}

if (-not $msbuildPath -or -not (Test-Path $msbuildPath)) {
    Write-Host "  [ERROR] MSBuild not found. Please install Visual Studio 2019 or 2022." -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: Try using 'dotnet' command if .NET SDK is installed:" -ForegroundColor Yellow
    Write-Host "  dotnet build SampleWindowsService\MyWindowsService.csproj -c Release" -ForegroundColor Cyan
    exit 1
}

Write-Host "  [OK] Found MSBuild at: $msbuildPath" -ForegroundColor Green
Write-Host ""

# Build Windows Service
Write-Host "Building Windows Service..." -ForegroundColor Yellow
try {
    & $msbuildPath $windowsServiceProject /p:Configuration=$Configuration /t:Rebuild /v:minimal /nologo
    if ($LASTEXITCODE -ne 0) {
        throw "MSBuild failed with exit code $LASTEXITCODE"
    }
    Write-Host "  [OK] Windows Service built successfully" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Failed to build Windows Service: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Build Web Application
Write-Host "Building Web Application..." -ForegroundColor Yellow
try {
    & $msbuildPath $webAppProject /p:Configuration=$Configuration /t:Rebuild /v:minimal /nologo
    if ($LASTEXITCODE -ne 0) {
        throw "MSBuild failed with exit code $LASTEXITCODE"
    }
    Write-Host "  [OK] Web Application built successfully" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Failed to build Web Application: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Create deployment source directories
Write-Host "Creating deployment source directories..." -ForegroundColor Yellow
$windowsServiceDeployPath = Join-Path $deploymentSourceRoot "WindowsService"
$webAppDeployPath = Join-Path $deploymentSourceRoot "WebApp"

New-Item -Path $windowsServiceDeployPath -ItemType Directory -Force | Out-Null
New-Item -Path $webAppDeployPath -ItemType Directory -Force | Out-Null

Write-Host "  [OK] Created deployment directories" -ForegroundColor Green
Write-Host ""

# Copy Windows Service binaries
Write-Host "Copying Windows Service binaries..." -ForegroundColor Yellow
$serviceBinPath = Join-Path $solutionRoot "SampleWindowsService\bin\$Configuration"
if (Test-Path $serviceBinPath) {
    Copy-Item -Path "$serviceBinPath\*" -Destination $windowsServiceDeployPath -Recurse -Force
    $fileCount = (Get-ChildItem -Path $windowsServiceDeployPath -File).Count
    Write-Host "  [OK] Copied $fileCount files to $windowsServiceDeployPath" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Service binaries not found at: $serviceBinPath" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Copy Web Application files
Write-Host "Copying Web Application files..." -ForegroundColor Yellow
$webAppBinPath = Join-Path $solutionRoot "SampleWebApp\bin"
$webAppSourcePath = Join-Path $solutionRoot "SampleWebApp"

# Copy all necessary web files
if (Test-Path $webAppSourcePath) {
    # Copy bin folder
    if (Test-Path $webAppBinPath) {
        Copy-Item -Path $webAppBinPath -Destination $webAppDeployPath -Recurse -Force
    }
    
    # Copy ASPX files, configs, and styles
    $filesToCopy = @("*.aspx", "*.asax", "*.config", "Styles")
    foreach ($pattern in $filesToCopy) {
        $items = Get-ChildItem -Path $webAppSourcePath -Filter $pattern -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            Copy-Item -Path $item.FullName -Destination $webAppDeployPath -Recurse -Force
        }
    }
    
    $fileCount = (Get-ChildItem -Path $webAppDeployPath -File -Recurse).Count
    Write-Host "  [OK] Copied $fileCount files to $webAppDeployPath" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Web application source not found at: $webAppSourcePath" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "============================================" -ForegroundColor Green
Write-Host "Build and Packaging Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Deployment packages created at:" -ForegroundColor Cyan
Write-Host "  Windows Service: $windowsServiceDeployPath" -ForegroundColor White
Write-Host "  Web Application: $webAppDeployPath" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review the deployment packages" -ForegroundColor White
Write-Host "  2. Run the DSC deployment: cd DSC; .\DeployConfiguration.ps1" -ForegroundColor White
Write-Host ""
