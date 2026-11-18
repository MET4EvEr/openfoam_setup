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
$dockerRunning = $false
$dockerVersion = ""
try {
    # Check if Docker daemon is running by querying ServerVersion.
    # Note: Silencing stderr prevents PowerShell from treating non-fatal kernel/driver
    # warnings (e.g. blkio throttle warnings on WSL2) as terminating errors.
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    $dockerVersion = (& docker info --format "{{.ServerVersion}}" 2>$null)
    if ($LASTEXITCODE -eq 0 -and $dockerVersion) {
        $dockerRunning = $true
    }
    $ErrorActionPreference = $prevEAP
} catch {
    $dockerRunning = $false
}

if ($dockerRunning) {
    Write-Host "[RUNNING]" -ForegroundColor Green -NoNewline
    Write-Host " (Docker Server v$dockerVersion)"
} else {
    Write-Host "[FAILED]" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: Docker Desktop is not running or not accessible." -ForegroundColor Red
    Write-Host "Please start Docker Desktop on your machine and wait until it finishes starting."
    Write-Host "Download Docker Desktop: https://www.docker.com/products/docker-desktop"
    Write-Host ""
    Write-Host "Press any key to close this window..." -ForegroundColor Gray
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch {}
    [System.Environment]::Exit(1)
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
# 3. Start Container with Docker Compose
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "Building / Starting OpenFOAM container service..." -ForegroundColor Gray
docker compose up -d --build

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start Docker Compose service." -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to close this window..." -ForegroundColor Gray
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch {}
    [System.Environment]::Exit($LASTEXITCODE)
}

# ------------------------------------------------------------------------------
# 4. Welcome Banner & Drop into Interactive Shell
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

# Execute interactive login bash session inside the running container
docker compose exec openfoam bash -l

Write-Host ""
Write-Host "OpenFOAM shell session ended." -ForegroundColor Cyan
Write-Host "The container is still running in the background." -ForegroundColor Gray
Write-Host "To shut down the container completely, run: .\stop_openfoam.bat" -ForegroundColor Gray
