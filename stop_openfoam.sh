#!/usr/bin/env bash
# ==============================================================================
# Safe OpenFOAM Container Shutdown Script (macOS / Linux)
# ==============================================================================
#
# PURPOSE:
# Gracefully stops and removes the running OpenFOAM Docker container service.
# Reassures the user that all simulations, logs, and meshes stored in
# 'openfoam_course_workspace/' remain intact on their host machine.
# ==============================================================================

set -euo pipefail

COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_CYAN="\033[1;36m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${COLOR_CYAN}Stopping OpenFOAM container service...${COLOR_RESET}"

docker compose down

echo ""
echo -e "${COLOR_GREEN}====================================================================${COLOR_RESET}"
echo -e "${COLOR_GREEN} OpenFOAM service has been stopped successfully.                    ${COLOR_RESET}"
echo -e "${COLOR_GREEN}====================================================================${COLOR_RESET}"
echo "All your simulation cases, meshes, and results in:"
echo "  $(pwd)/openfoam_course_workspace"
echo "are safely saved on your computer and preserved across sessions."
echo "--------------------------------------------------------------------"
