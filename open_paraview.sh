#!/usr/bin/env bash
# ==============================================================================
# Native Host ParaView Launcher (macOS / Linux)
# ==============================================================================
#
# PURPOSE:
# Launches ParaView locally on the host machine to inspect simulation results.
# Running ParaView natively on the host gives:
#   1. Full hardware GPU OpenGL/Vulkan rendering speed.
#   2. Zero lag compared to slow X11/VNC network tunneling inside containers.
#   3. Direct access to files in openfoam_course_workspace/.
#
# USAGE:
#   ./open_paraview.sh                           # Opens default test_cavity case
#   ./open_paraview.sh path/to/another_case      # Opens a specific case folder
# ==============================================================================

set -euo pipefail

# ANSI color codes
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[1;31m"
COLOR_CYAN="\033[1;36m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ------------------------------------------------------------------------------
# 1. Resolve Target Case Directory
# ------------------------------------------------------------------------------
CASE_INPUT="${1:-openfoam_course_workspace/test_cavity}"

# Handle relative or absolute paths
if [[ "$CASE_INPUT" = /* ]]; then
    CASE_DIR="$CASE_INPUT"
else
    CASE_DIR="$SCRIPT_DIR/$CASE_INPUT"
fi

if [ ! -d "$CASE_DIR" ]; then
    echo -e "${COLOR_RED}Error: Case directory does not exist:${COLOR_RESET} $CASE_DIR"
    exit 1
fi

CASE_NAME="$(basename "$CASE_DIR")"
FOAM_FILE="$CASE_DIR/${CASE_NAME}.foam"

# ------------------------------------------------------------------------------
# 2. Ensure ParaView Marker (.foam) File Exists
# ------------------------------------------------------------------------------
# ParaView recognizes OpenFOAM cases via an empty dummy file ending in .foam
if [ ! -f "$FOAM_FILE" ]; then
    echo "Creating OpenFOAM reader marker file: $FOAM_FILE"
    touch "$FOAM_FILE"
fi

# ------------------------------------------------------------------------------
# 3. Locate Local ParaView Executable
# ------------------------------------------------------------------------------
PARAVIEW_EXEC=""

# Check .env first
if [ -f .env ]; then
    CONFIGURED="$(grep "^PARAVIEW_PATH=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'" || true)"
    if [ -n "$CONFIGURED" ] && [ -x "$CONFIGURED" ]; then
        PARAVIEW_EXEC="$CONFIGURED"
    fi
fi

# Auto-detect if not configured
if [ -z "$PARAVIEW_EXEC" ]; then
    if [ "$(uname)" = "Darwin" ]; then
        # Search macOS Applications folder
        for app in /Applications/ParaView*.app/Contents/MacOS/paraview; do
            if [ -x "$app" ]; then
                PARAVIEW_EXEC="$app"
                break
            fi
        done
    elif [ "$(uname)" = "Linux" ]; then
        if command -v paraview >/dev/null 2>&1; then
            PARAVIEW_EXEC="$(command -v paraview)"
        fi
    fi
fi

if [ -z "$PARAVIEW_EXEC" ]; then
    echo -e "${COLOR_RED}Error: ParaView was not found on your host system.${COLOR_RESET}"
    echo "Please download and install ParaView from: https://www.paraview.org/download/"
    echo "Once installed, set the absolute path in .env (PARAVIEW_PATH=...)"
    exit 1
fi

# ------------------------------------------------------------------------------
# 4. Launch ParaView in Background
# ------------------------------------------------------------------------------
echo -e "${COLOR_CYAN}Launching ParaView on host:${COLOR_RESET} $PARAVIEW_EXEC"
echo -e "${COLOR_CYAN}Loading case:${COLOR_RESET} $FOAM_FILE"
echo ""
echo -e "${COLOR_GREEN}====================================================================${COLOR_RESET}"
echo -e "${COLOR_GREEN} Quick ParaView Inspection Checklist:                               ${COLOR_RESET}"
echo -e "${COLOR_GREEN}====================================================================${COLOR_RESET}"
echo "1. Look at the 'Properties' panel on the left and click the blue 'Apply' button."
echo "2. In the top toolbar, change the display dropdown from 'Solid Color' to 'p' (Pressure) or 'U' (Velocity)."
echo "3. Click the green Play button in the top VCR controls to animate through time steps."
echo "--------------------------------------------------------------------"

# Launch in background and disown so terminal stays free
"$PARAVIEW_EXEC" "$FOAM_FILE" >/dev/null 2>&1 &
echo "ParaView process launched."
