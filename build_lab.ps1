# ==============================================================================
# IIS Single-Site Lab Build Script
# ==============================================================================
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " [1/4] Checking build prerequisites..." -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Error "dotnet CLI not found. Please install .NET 8 SDK."
    exit 1
}
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "npm CLI not found. Please install Node.js."
    exit 1
}

$FrontendDir = Join-Path $ScriptDir "lab-web"
$BackendDir = Join-Path $ScriptDir "LabApi"
$TempBackendPublish = Join-Path $ScriptDir ".temp_backend_publish"
$DeployModeA = Join-Path $ScriptDir "Deploy_ModeA_SubApp"
$DeployModeB = Join-Path $ScriptDir "Deploy_ModeB_UnifiedWwwroot"

# ------------------------------------------------------------------------------
# 1. Build Frontend (lab-web)
# ------------------------------------------------------------------------------
Write-Host "`n[2/4] Building React + Vite frontend (lab-web)..." -ForegroundColor Yellow
Push-Location $FrontendDir
try {
    if (-not (Test-Path "node_modules")) {
        Write-Host "Installing npm dependencies..." -ForegroundColor Gray
        npm install
    }
    Write-Host "Building production bundle (npm run build)..." -ForegroundColor Gray
    npm run build
}
finally {
    Pop-Location
}

$FrontendDist = Join-Path $FrontendDir "dist"
if (-not (Test-Path $FrontendDist)) {
    Write-Error "Frontend build failed: dist folder not found!"
    exit 1
}

# ------------------------------------------------------------------------------
# 2. Build Backend (LabApi)
# ------------------------------------------------------------------------------
Write-Host "`n[3/4] Publishing ASP.NET Core 8 Web API (LabApi)..." -ForegroundColor Yellow
if (Test-Path $TempBackendPublish) {
    Remove-Item -Recurse -Force $TempBackendPublish
}
New-Item -ItemType Directory -Path $TempBackendPublish -Force | Out-Null

Push-Location $BackendDir
try {
    Write-Host "Publishing backend (dotnet publish -c Release)..." -ForegroundColor Gray
    dotnet publish -c Release -o $TempBackendPublish
}
finally {
    Pop-Location
}

# ------------------------------------------------------------------------------
# 3. Assemble Deploy Packages
# ------------------------------------------------------------------------------
Write-Host "`n[4/4] Assembling deployment packages..." -ForegroundColor Green

# --- Mode A: Sub-Application (/api) ---
Write-Host "-> Generating Mode A: Deploy_ModeA_SubApp..." -ForegroundColor Gray
if (Test-Path $DeployModeA) {
    Remove-Item -Recurse -Force $DeployModeA
}
New-Item -ItemType Directory -Path $DeployModeA -Force | Out-Null

Copy-Item -Path "$FrontendDist\*" -Destination $DeployModeA -Recurse -Force

$ModeASubAppDir = Join-Path $DeployModeA "api"
New-Item -ItemType Directory -Path $ModeASubAppDir -Force | Out-Null
Copy-Item -Path "$TempBackendPublish\*" -Destination $ModeASubAppDir -Recurse -Force

Copy-Item -Path (Join-Path $ScriptDir "IIS_SETUP_GUIDE_ModeA.md") -Destination (Join-Path $DeployModeA "README_IIS_SETUP.md") -Force


# --- Mode B: Unified wwwroot ---
Write-Host "-> Generating Mode B: Deploy_ModeB_UnifiedWwwroot..." -ForegroundColor Gray
if (Test-Path $DeployModeB) {
    Remove-Item -Recurse -Force $DeployModeB
}
New-Item -ItemType Directory -Path $DeployModeB -Force | Out-Null

Copy-Item -Path "$TempBackendPublish\*" -Destination $DeployModeB -Recurse -Force

$ModeBWwwrootDir = Join-Path $DeployModeB "wwwroot"
New-Item -ItemType Directory -Path $ModeBWwwrootDir -Force | Out-Null
Copy-Item -Path "$FrontendDist\*" -Destination $ModeBWwwrootDir -Recurse -Force

$RedundantConfig = Join-Path $ModeBWwwrootDir "web.config"
if (Test-Path $RedundantConfig) {
    Remove-Item -Force $RedundantConfig
}

Copy-Item -Path (Join-Path $ScriptDir "IIS_SETUP_GUIDE_ModeB.md") -Destination (Join-Path $DeployModeB "README_IIS_SETUP.md") -Force

# Cleanup temp folder
if (Test-Path $TempBackendPublish) {
    Remove-Item -Recurse -Force $TempBackendPublish
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " [SUCCESS] Build completed successfully!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Two deployment packages are ready:"
Write-Host " 1. Mode A (Sub-App)         : $DeployModeA" -ForegroundColor Cyan
Write-Host " 2. Mode B (Unified wwwroot) : $DeployModeB" -ForegroundColor Cyan
Write-Host "`nRefer to README_IIS_SETUP.md in each folder for 3-minute IIS setup instructions." -ForegroundColor Yellow
