# ==============================================================================
# Native Host ParaView Launcher (Windows PowerShell Engine)
# ==============================================================================
#
# PURPOSE:
# Automatically locates the local ParaView executable on Windows, creates the
# required .foam case marker file, and launches ParaView with the simulation case.
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$CasePath = "openfoam_course_workspace\test_cavity"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

# ------------------------------------------------------------------------------
# 1. Resolve Case Directory and Target .foam File
# ------------------------------------------------------------------------------
if ([System.IO.Path]::IsPathRooted($CasePath)) {
    $ResolvedCaseDir = $CasePath
} else {
    $ResolvedCaseDir = Join-Path $RepoRoot $CasePath
}

if (-not (Test-Path $ResolvedCaseDir)) {
    Write-Host "Error: Target case directory does not exist: $ResolvedCaseDir" -ForegroundColor Red
    exit 1
}

$CaseFolderItem = Get-Item $ResolvedCaseDir
$CaseName = $CaseFolderItem.Name
$FoamFilePath = Join-Path $ResolvedCaseDir "$CaseName.foam"

# ParaView reads OpenFOAM cases via an empty dummy .foam file
if (-not (Test-Path $FoamFilePath)) {
    Write-Host "Creating OpenFOAM reader marker: $FoamFilePath" -ForegroundColor Gray
    New-Item -ItemType File -Path $FoamFilePath -Force | Out-Null
}

# ------------------------------------------------------------------------------
# 2. Locate ParaView Executable on Windows Host
# ------------------------------------------------------------------------------
$EnvFile = Join-Path $RepoRoot ".env"
$ParaviewExe = $null

# Check .env first
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match "^\s*PARAVIEW_PATH\s*=\s*(.*)$") {
            $val = $matches[1].Trim().Trim('"').Trim("'")
            if ($val -ne "" -and (Test-Path $val)) {
                $ParaviewExe = $val
            }
        }
    }
}

# Auto-detect if not configured
if (-not $ParaviewExe) {
    $searchPatterns = @(
        "C:\Program Files\ParaView*\bin\paraview.exe",
        "C:\Program Files (x86)\ParaView*\bin\paraview.exe"
    )
    foreach ($pattern in $searchPatterns) {
        $found = Get-Item -Path $pattern -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        if ($found -and $found.Count -gt 0) {
            $ParaviewExe = $found[0].FullName
            break
        }
    }
}

if (-not $ParaviewExe) {
    Write-Host "Error: ParaView was not found on your Windows computer." -ForegroundColor Red
    Write-Host "Please download and install ParaView from: https://www.paraview.org/download/"
    Write-Host "After installing, specify the path in .env: PARAVIEW_PATH=`"C:\Program Files\ParaView...\bin\paraview.exe`""
    exit 1
}

# ------------------------------------------------------------------------------
# 3. Launch ParaView with Target Case
# ------------------------------------------------------------------------------
Write-Host "Launching ParaView:" -ForegroundColor Cyan -NoNewline
Write-Host " $ParaviewExe"
Write-Host "Loading Case:     " -ForegroundColor Cyan -NoNewline
Write-Host " $FoamFilePath"
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host " Quick ParaView Inspection Checklist:                               " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "1. Look at the 'Properties' panel on the left and click the blue 'Apply' button."
Write-Host "2. In the top toolbar, change the display dropdown from 'Solid Color' to 'p' (Pressure) or 'U' (Velocity)."
Write-Host "3. Click the green Play button in the top VCR controls to animate through time steps."
Write-Host "--------------------------------------------------------------------"

Start-Process -FilePath $ParaviewExe -ArgumentList "`"$FoamFilePath`""
Write-Host "ParaView launched successfully." -ForegroundColor Green
