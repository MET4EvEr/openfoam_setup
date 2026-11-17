# ==============================================================================
# One-Click OpenFOAM Environment Launcher (Windows PowerShell Engine)
# ==============================================================================
#
# PURPOSE:
# Handles environment setup, Docker health verification, ParaView auto-detection,
# container startup, and interactive OpenFOAM shell connection on Windows systems.
# ==============================================================================

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# Ensure working directory is the repository root
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "       OpenFOAM (Docker) + Python (uv) Course Environment           " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. Verify Docker Daemon is Running
# ------------------------------------------------------------------------------
Write-Host -NoNewline "Checking Docker daemon status... "
try {
    $null = docker info 2>&1
    Write-Host "[RUNNING]" -ForegroundColor Green
} catch {
    Write-Host "[FAILED]" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: Docker Desktop is not running or not accessible." -ForegroundColor Red
    Write-Host "Please start Docker Desktop on your machine and wait until it finishes starting."
    Write-Host "Download Docker Desktop: https://www.docker.com/products/docker-desktop"
    Write-Host ""
    exit 1
}

# ------------------------------------------------------------------------------
# 2. Ensure .env Exists
# ------------------------------------------------------------------------------
$EnvFile = Join-Path $RepoRoot ".env"
$EnvExample = Join-Path $RepoRoot ".env.example"

if (-not (Test-Path $EnvFile)) {
    Write-Host "Creating .env from template .env.example..." -ForegroundColor Gray
    Copy-Item -Path $EnvExample -Destination $EnvFile
}

# ------------------------------------------------------------------------------
# 3. Detect and Validate Local ParaView Installation
# ------------------------------------------------------------------------------
$ParaviewPath = $null

# Read existing configuration if present
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match "^\s*PARAVIEW_PATH\s*=\s*(.*)$") {
            $val = $matches[1].Trim().Trim('"').Trim("'")
            if ($val -ne "" -and (Test-Path $val)) {
                $ParaviewPath = $val
            }
        }
    }
}

# Auto-detect if not configured or invalid
if (-not $ParaviewPath) {
    $searchPatterns = @(
        "C:\Program Files\ParaView*\bin\paraview.exe",
        "C:\Program Files (x86)\ParaView*\bin\paraview.exe"
    )
    foreach ($pattern in $searchPatterns) {
        $matches = Get-Item -Path $pattern -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        if ($matches -and $matches.Count -gt 0) {
            $ParaviewPath = $matches[0].FullName
            break
        }
    }
}

if ($ParaviewPath) {
    Write-Host "Host ParaView: " -NoNewline
    Write-Host "[OK]" -ForegroundColor Green -NoNewline
    Write-Host " ($ParaviewPath)"
} else {
    Write-Host "Host ParaView: " -NoNewline
    Write-Host "[WARNING]" -ForegroundColor Yellow -NoNewline
    Write-Host " Not detected in standard Program Files paths."
    Write-Host "  -> You can still run all simulations inside Docker without ParaView!" -ForegroundColor Yellow
    Write-Host "  -> To view 3D results locally, download ParaView from https://www.paraview.org/download/"
    Write-Host "     and set PARAVIEW_PATH in your .env file."
}

# ------------------------------------------------------------------------------
# 4. Start Container with Docker Compose
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "Building / Starting OpenFOAM container service..." -ForegroundColor Gray
docker compose up -d --build

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start Docker Compose service." -ForegroundColor Red
    exit $LASTEXITCODE
}

# ------------------------------------------------------------------------------
# 5. Welcome Banner & Drop into Interactive Shell
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host " Container is ready! Entering interactive OpenFOAM shell...         " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "You are now in /workspace inside the container."
Write-Host "Try running the beginner test case right now:"
Write-Host "  cd test_cavity" -ForegroundColor Yellow
Write-Host "  ./run_test.sh" -ForegroundColor Yellow
Write-Host ""
Write-Host "Type 'exit' whenever you want to return to your Windows terminal."
Write-Host "--------------------------------------------------------------------"

# Execute interactive bash session inside the running container
docker compose exec openfoam bash
