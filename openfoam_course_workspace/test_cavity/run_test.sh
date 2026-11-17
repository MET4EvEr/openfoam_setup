#!/usr/bin/env bash
# ==============================================================================
# OpenFOAM Beginner Tutorial Script: 2D Lid-Driven Cavity Case
# ==============================================================================
#
# PURPOSE:
# Guides a complete beginner through the entire end-to-end CFD simulation workflow:
#   1. Mesh generation from parametric dictionary (blockMesh)
#   2. Mesh quality and geometric topology verification (checkMesh)
#   3. Navier-Stokes finite-volume solver execution (icoFoam)
#   4. Post-processing marker generation for ParaView (cavity.foam)
#   5. Automated Python convergence plotting via uv (plot_residuals.py)
# ==============================================================================

set -euo pipefail

# ANSI Color formatting
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_CYAN="\033[1;36m"
C_BLUE="\033[1;34m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${C_CYAN}====================================================================${C_RESET}"
echo -e "${C_CYAN}  Step-by-Step OpenFOAM Simulation: 2D Lid-Driven Cavity Flow        ${C_RESET}"
echo -e "${C_CYAN}====================================================================${C_RESET}"

# ------------------------------------------------------------------------------
# STEP 1: Clean Old Simulation Data
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BOLD}[Step 1/6] Cleaning previous simulation results...${C_RESET}"
echo "Removing old time directories (0.1, 0.2, etc.), log files, and old plots..."

# Remove old time step directories (e.g., 0.1, 0.2, 0.3) without deleting initial condition '0'
find . -maxdepth 1 -type d -name "0.*" ! -name "0" -exec rm -rf {} +
find . -maxdepth 1 -type d -regextype posix-extended -regex "./[1-9][0-9]*.*" -exec rm -rf {} +
rm -rf constant/polyMesh log.* *.foam residuals.png postProcessing

echo -e "${C_GREEN}[OK] Workspace cleaned.${C_RESET}"

# ------------------------------------------------------------------------------
# STEP 2: Generate Computational Mesh (blockMesh)
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BOLD}[Step 2/6] Generating mesh with blockMesh...${C_RESET}"
echo "Reading system/blockMeshDict to construct 20x20 2D hex grid (400 cells)..."

blockMesh | tee log.blockMesh

if [ ! -d "constant/polyMesh" ]; then
    echo -e "\033[1;31mError: blockMesh failed to generate constant/polyMesh!\033[0m"
    exit 1
fi
echo -e "${C_GREEN}[OK] Mesh successfully generated in constant/polyMesh.${C_RESET}"

# ------------------------------------------------------------------------------
# STEP 3: Verify Mesh Quality (checkMesh)
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BOLD}[Step 3/6] Validating mesh topology with checkMesh...${C_RESET}"
echo "Checking mesh non-orthogonality, aspect ratio, and skewness..."

checkMesh | tee log.checkMesh
echo -e "${C_GREEN}[OK] Mesh validation passed.${C_RESET}"

# ------------------------------------------------------------------------------
# STEP 4: Solve Navier-Stokes Equations (icoFoam)
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BOLD}[Step 4/6] Solving Navier-Stokes equations with icoFoam...${C_RESET}"
echo "Simulating laminar flow from t=0.0s to t=0.5s (deltaT=0.005s, 100 time-steps)..."

icoFoam | tee log.icoFoam
echo -e "${C_GREEN}[OK] Simulation completed successfully.${C_RESET}"

# ------------------------------------------------------------------------------
# STEP 5: Create Marker File for ParaView
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BOLD}[Step 5/6] Creating ParaView marker file (cavity.foam)...${C_RESET}"
touch cavity.foam
echo -e "${C_GREEN}[OK] Created cavity.foam.${C_RESET}"

# ------------------------------------------------------------------------------
# STEP 6: Automated Python Residual Analysis
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BOLD}[Step 6/6] Plotting solver convergence with Python (uv)...${C_RESET}"
echo "Parsing log.icoFoam with pandas and generating residuals.png..."

python plot_residuals.py

echo ""
echo -e "${C_GREEN}====================================================================${C_RESET}"
echo -e "${C_GREEN} Simulation and Post-Processing Complete!                           ${C_RESET}"
echo -e "${C_GREEN}====================================================================${C_RESET}"
echo -e "Outputs generated inside ${C_CYAN}test_cavity/${C_RESET}:"
echo "  1. Time result folders: 0.1, 0.2, 0.3, 0.4, 0.5 (Fields: p, U)"
echo "  2. Solver convergence: residuals.png"
echo "  3. Solver log files:   log.blockMesh, log.checkMesh, log.icoFoam"
echo "  4. ParaView marker:    cavity.foam"
echo ""
echo -e "${C_BOLD}HOW TO VIEW 3D RESULTS ON YOUR COMPUTER:${C_RESET}"
echo "Exit or switch to your host terminal and run:"
echo -e "  - On Windows:      ${C_YELLOW}.\\open_paraview.bat${C_RESET}"
echo -e "  - On macOS/Linux:  ${C_YELLOW}./open_paraview.sh${C_RESET}"
echo "--------------------------------------------------------------------"
