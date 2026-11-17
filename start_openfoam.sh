#!/usr/bin/env bash
# ==============================================================================
# One-Click OpenFOAM Environment Launcher (macOS / Linux)
# ==============================================================================
#
# PURPOSE:
# 1. Validates that Docker daemon is running.
# 2. Ensures local .env configuration exists (auto-creating from .env.example).
# 3. Dynamically exports host UID/GID for seamless Linux/macOS file permissions.
# 4. Probes for local ParaView installation and gives helpful status feedback.
# 5. Starts or rebuilds the Docker container in the background.
# 6. Attaches the user into an interactive shell inside /workspace.
# ==============================================================================

set -euo pipefail

# ANSI color codes for beginner-friendly readable output
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[1;31m"
COLOR_BLUE="\033[1;34m"
COLOR_CYAN="\033[1;36m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${COLOR_CYAN}====================================================================${COLOR_RESET}"
echo -e "${COLOR_CYAN}       OpenFOAM (Docker) + Python (uv) Course Environment           ${COLOR_RESET}"
echo -e "${COLOR_CYAN}====================================================================${COLOR_RESET}"

# ------------------------------------------------------------------------------
# 1. Verify Docker Daemon is Running
# ------------------------------------------------------------------------------
echo -n "Checking Docker daemon status... "
if ! docker info >/dev/null 2>&1; then
    echo -e "${COLOR_RED}[FAILED]${COLOR_RESET}"
    echo -e "${COLOR_RED}Error: Docker is not running or not accessible!${COLOR_RESET}"
    echo "Please ensure Docker Desktop (or the Docker daemon) is started and try again."
    echo "Download Docker: https://www.docker.com/products/docker-desktop"
    exit 1
fi
echo -e "${COLOR_GREEN}[RUNNING]${COLOR_RESET}"

# ------------------------------------------------------------------------------
# 2. Ensure .env Exists and Configure Host Permissions
# ------------------------------------------------------------------------------
if [ ! -f .env ]; then
    echo "Creating .env from template .env.example..."
    cp .env.example .env
fi

# Detect host user and group IDs on Linux/macOS
export HOST_UID="$(id -u)"
export HOST_GID="$(id -g)"

# Update or append HOST_UID/HOST_GID in .env
if grep -q "^HOST_UID=" .env; then
    # Cross-platform sed inplace (compatible with macOS BSD sed and Linux GNU sed)
    sed -i.bak "s/^HOST_UID=.*/HOST_UID=${HOST_UID}/" .env && rm -f .env.bak
else
    echo "HOST_UID=${HOST_UID}" >> .env
fi

if grep -q "^HOST_GID=" .env; then
    sed -i.bak "s/^HOST_GID=.*/HOST_GID=${HOST_GID}/" .env && rm -f .env.bak
else
    echo "HOST_GID=${HOST_GID}" >> .env
fi

# ------------------------------------------------------------------------------
# 3. Detect and Validate ParaView
# ------------------------------------------------------------------------------
PARAVIEW_DETECTED=""
CONFIGURED_PARAVIEW="$(grep "^PARAVIEW_PATH=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'" || true)"

if [ -n "$CONFIGURED_PARAVIEW" ] && [ -x "$CONFIGURED_PARAVIEW" ]; then
    PARAVIEW_DETECTED="$CONFIGURED_PARAVIEW"
else
    # Auto-detection search paths for macOS and Linux
    if [ "$(uname)" = "Darwin" ]; then
        # Check macOS Applications
        for app in /Applications/ParaView*.app/Contents/MacOS/paraview; do
            if [ -x "$app" ]; then
                PARAVIEW_DETECTED="$app"
                break
            fi
        done
    elif [ "$(uname)" = "Linux" ]; then
        if command -v paraview >/dev/null 2>&1; then
            PARAVIEW_DETECTED="$(command -v paraview)"
        fi
    fi
fi

if [ -n "$PARAVIEW_DETECTED" ]; then
    echo -e "Host ParaView: ${COLOR_GREEN}[OK]${COLOR_RESET} (${PARAVIEW_DETECTED})"
else
    echo -e "Host ParaView: ${COLOR_YELLOW}[WARNING]${COLOR_RESET} Not detected in standard paths."
    echo -e "  ${COLOR_YELLOW}-> You can still run simulations without ParaView!${COLOR_RESET}"
    echo "  -> To view 3D meshes and flow fields, install ParaView from https://www.paraview.org/download/"
    echo "     and optionally set PARAVIEW_PATH in .env"
fi

# ------------------------------------------------------------------------------
# 4. Start Container with Docker Compose
# ------------------------------------------------------------------------------
echo ""
echo "Building / Starting OpenFOAM container service..."
docker compose up -d --build

# ------------------------------------------------------------------------------
# 5. Welcome Banner & Drop into Interactive Shell
# ------------------------------------------------------------------------------
echo ""
echo -e "${COLOR_GREEN}====================================================================${COLOR_RESET}"
echo -e "${COLOR_GREEN} Container is ready! Entering interactive OpenFOAM shell...         ${COLOR_RESET}"
echo -e "${COLOR_GREEN}====================================================================${COLOR_RESET}"
echo -e "You are now in ${COLOR_CYAN}/workspace${COLOR_RESET} inside the container."
echo -e "Try running the beginner test case right now:"
echo -e "  ${COLOR_YELLOW}cd test_cavity${COLOR_RESET}"
echo -e "  ${COLOR_YELLOW}./run_test.sh${COLOR_RESET}"
echo ""
echo "Type 'exit' whenever you want to return to your host terminal."
echo "--------------------------------------------------------------------"

# Execute interactive login bash session inside the running container
docker compose exec openfoam bash -l
