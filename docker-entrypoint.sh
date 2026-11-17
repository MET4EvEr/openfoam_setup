#!/usr/bin/env bash
# ==============================================================================
# Container Entrypoint Script for OpenFOAM + Python Environment
# ==============================================================================
#
# ARCHITECTURAL ROLE:
# This script initializes the OpenFOAM solver environment and sets up user space
# variables before executing any interactive shell or background command.
#
# CRITICAL TRAP GUARD:
# OpenFOAM's etc/bashrc script frequently probes environment variables and aliases
# that can produce non-zero exit codes during normal initialization. If 'set -e'
# is active when sourcing bashrc, the container will immediately crash and exit!
# Therefore, we MUST disable immediate error exiting with 'set +e' while sourcing.
# ==============================================================================

# Disable immediate exit on error and unbound variable checking during OpenFOAM loading
set +eu

# Locate and source the OpenFOAM environment file (etc/bashrc).
# Different OpenFOAM distributions (OpenCFD, Foundation, microfluidica) place
# the installation under /opt/openfoam* or /usr/lib/openfoam/openfoam*.
OPENFOAM_SOURCED=0
for rc in /opt/openfoam*/etc/bashrc /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM/OpenFOAM-*/etc/bashrc; do
    if [ -f "$rc" ]; then
        # Source the OpenFOAM environment variables into current shell
        # shellcheck source=/dev/null
        source "$rc"
        OPENFOAM_SOURCED=1
        break
    fi
done

if [ "$OPENFOAM_SOURCED" -eq 0 ]; then
    echo "[WARNING] OpenFOAM bashrc was not found in standard directories."
    echo "[WARNING] If OpenFOAM commands fail, check the base image installation path."
fi

# Re-enable standard bash error safety
set -e

# ------------------------------------------------------------------------------
# Permission & Home Directory Guard for Non-Root Containers
# ------------------------------------------------------------------------------
# When running with host user permissions (e.g., HOST_UID:HOST_GID = 1001:1001),
# standard /root or /home/foam directories may be unwritable.
# Pointing HOME to /tmp/openfoam_home guarantees that OpenFOAM history, OpenMPI
# session directories, and tool caches can always write without Permission Denied.
export HOME=/tmp/openfoam_home
mkdir -p "$HOME"
chmod 777 "$HOME" 2>/dev/null || true

# ------------------------------------------------------------------------------
# Hand over control to the requested container process
# ------------------------------------------------------------------------------
# 'exec "$@"' replaces the entrypoint shell process with the command specified in
# docker-compose or the docker run CLI (e.g., bash, run_test.sh, etc.), preserving
# proper PID 1 signal forwarding (SIGINT/SIGTERM for clean container shutdowns).
exec "$@"
