# ==============================================================================
# Multi-Arch Production Dockerfile: OpenFOAM + Python (uv) Headless Environment
# ==============================================================================
#
# PURPOSE:
# Builds a lightweight, robust, multi-architecture container supporting:
#   - OpenFOAM CFD solvers (icoFoam, simpleFoam, blockMesh, checkMesh, etc.)
#   - High-performance Python scientific stack managed via Astral `uv`
#   - Headless plotting and automated post-processing
#
# BASE IMAGE:
# microfluidica/openfoam:latest
# - Native multi-architecture support: linux/amd64 (Intel/AMD) & linux/arm64 (Apple Silicon)
# - No bulky X11/VNC desktop bloat (ParaView runs natively on host OS for GPU acceleration)
# ==============================================================================

FROM microfluidica/openfoam:latest

# Switch to root to configure system tools, Python environment, and entrypoint
USER root

# Avoid interactive tzdata/locale prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# 1. System Utilities and Python 3 Runtime
# ------------------------------------------------------------------------------
# Install python3 and certificates required for SSL package verification
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        procps \
        python3 \
        python3-pip \
        python3-venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# 2. Install Astral `uv` Fast Package Manager
# ------------------------------------------------------------------------------
# Astral `uv` is copied directly from its official multi-arch binary distribution.
# It resolves and installs packages at blazing speed and manages virtual environments.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# ------------------------------------------------------------------------------
# 3. Configure Python Environment Variables
# ------------------------------------------------------------------------------
# Point uv to store the virtual environment at /opt/venv inside the container image
ENV UV_PROJECT_ENVIRONMENT=/opt/venv

# Set uv temporary cache directory
ENV UV_CACHE_DIR=/tmp/uv-cache

# Enforce headless matplotlib rendering backend (prevents X11 connection errors)
ENV MPLBACKEND=Agg

# Add virtual environment binaries directly to system PATH so 'python' and
# installed command-line utilities are immediately accessible
ENV PATH="/opt/venv/bin:${PATH}"

# ------------------------------------------------------------------------------
# 4. Pre-bake Python Dependencies via uv
# ------------------------------------------------------------------------------
# Copy PEP 621 package definition into /opt/python-env
WORKDIR /opt/python-env
COPY pyproject.toml .

# Create virtual environment and synchronize dependencies defined in pyproject.toml
# --no-install-project avoids needing an installable root package while installing
# numpy, pandas, matplotlib, and foamlib into /opt/venv.
RUN uv sync --no-install-project && \
    # Ensure all course attendees have full read/write/execute access regardless of their host UID
    chmod -R 777 /opt/venv /tmp/uv-cache /opt/python-env

# ------------------------------------------------------------------------------
# 5. Setup Safe OpenFOAM Entrypoint
# ------------------------------------------------------------------------------
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# ------------------------------------------------------------------------------
# 6. Configure Workspace and Execution Defaults
# ------------------------------------------------------------------------------
# Set the default working directory to the host-mounted workspace
WORKDIR /workspace

# Use our safe OpenFOAM entrypoint script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command: interactive bash shell
CMD ["bash"]
