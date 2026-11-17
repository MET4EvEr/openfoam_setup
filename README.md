# OpenFOAM (Docker) + Python (`uv`) + Local ParaView Course Environment

Welcome to the **OpenFOAM CFD Course Environment**! This repository provides an end-to-end, zero-headache, cross-platform computational fluid dynamics workspace designed specifically for beginners and engineering students.

It combines:
1. **Headless Linux Docker Container:** Runs OpenFOAM solvers and a lightning-fast Python scientific environment (`uv`, `numpy`, `pandas`, `matplotlib`, `foamlib`) on any architecture (Intel/AMD x86_64 and Apple Silicon ARM64).
2. **Host-Mounted Workspace:** Simulation cases live on your host machine in `openfoam_course_workspace/`, so all your files, code, and results are permanently saved on your computer.
3. **Native Host ParaView:** Renders 3D flow fields and meshes locally on Windows or macOS with full GPU hardware acceleration and zero lag.

---

## 1. Architectural Architecture Overview

```
+-----------------------------------------------------------------------------------------+
|                                    YOUR HOST COMPUTER                                    |
|                              (Windows 10/11, macOS, or Linux)                            |
+-----------------------------------------------------------------------------------------+
       |                                                                   |
       |  1. Launches container via start_openfoam.bat/.sh                 |  3. Inspects 3D results
       v                                                                   v     via open_paraview.bat/.sh
+--------------------------------------------------+        +-----------------------------+
|              DOCKER ENGINE / DESKTOP             |        |    NATIVE HOST PARAVIEW     |
|                                                  |        |   (GPU Hardware Accelerated)|
|  +--------------------------------------------+  |        +-----------------------------+
|  | Container: openfoam_course                 |  |                       ^
|  | Image: microfluidica/openfoam:latest       |  |                       |
|  |                                            |  |                       | Reads *.foam &
|  | +----------------------------------------+ |  |                       | time-step fields
|  | | OpenFOAM Solvers & Tools               | |  |                       | directly
|  | | (blockMesh, checkMesh, icoFoam, etc.)  | |  |                       |
|  | +----------------------------------------+ |  |                       |
|  |                                            |  |                       |
|  | +----------------------------------------+ |  |                       |
|  | | Python Scientific Environment (uv)     | |  |                       |
|  | | (/opt/venv: numpy, pandas, matplotlib) | |  |                       |
|  | +----------------------------------------+ |  |                       |
|  |                                            |  |                       |
|  | Mount: /workspace <------------------------+--+-----------------------+
|  +--------------------------------------------+  |
+--------------------------------------------------+
                               |
             Shared Volume Mount (Bi-directional sync)
                               |
                               v
+-----------------------------------------------------------------------------------------+
|                  HOST DIRECTORY: openfoam_course_workspace/                             |
|                                                                                         |
|   test_cavity/                 <-- Self-contained 2D Lid-Driven Cavity tutorial         |
|   |-- 0/                       <-- Initial conditions (p, U)                            |
|   |-- constant/                <-- Fluid properties & mesh (transportProperties)        |
|   |-- system/                  <-- Control & numerical schemes (controlDict, etc.)      |
|   |-- run_test.sh              <-- One-click automated tutorial simulation runner       |
|   |-- plot_residuals.py        <-- Automated Matplotlib convergence graph generator     |
|   |-- cavity.foam              <-- ParaView marker file                                 |
|   `-- residuals.png            <-- High-resolution convergence plot                    |
+-----------------------------------------------------------------------------------------+
```

---

## 2. Repository File Map

| File / Directory | Platform / Component | Purpose & Description |
| :--- | :--- | :--- |
| `start_openfoam.bat` | Windows | One-click Windows launcher (delegates to PowerShell engine). |
| `scripts/start_openfoam.ps1` | Windows (PowerShell) | Validates Docker, auto-detects ParaView, starts container, enters shell. |
| `start_openfoam.sh` | macOS / Linux | One-click bash launcher with auto-detection and UID/GID mapping. |
| `stop_openfoam.bat` | Windows | Safely stops and shuts down the Docker container. |
| `stop_openfoam.sh` | macOS / Linux | Safely stops and shuts down the Docker container. |
| `open_paraview.bat` | Windows | One-click script to launch native ParaView and load case results. |
| `scripts/open_paraview.ps1` | Windows (PowerShell) | PowerShell engine that locates `paraview.exe` and passes `.foam` file. |
| `open_paraview.sh` | macOS / Linux | Bash script to launch host ParaView and load case results. |
| `Dockerfile` | Docker | Multi-arch recipe with headless OpenFOAM and pre-baked `uv` environment. |
| `docker-compose.yml` | Docker Compose | Container configuration with 2GB shared memory and volume mounts. |
| `docker-entrypoint.sh` | Container Init | Sourcing guard for OpenFOAM `bashrc` and permission setup. |
| `pyproject.toml` | Python (`uv`) | Standard PEP 621 dependencies (`numpy`, `pandas`, `matplotlib`, `foamlib`). |
| `.env.example` | Configuration | Template for user settings (`PARAVIEW_PATH`, `HOST_UID`, `HOST_GID`). |
| `.gitattributes` | Git | Enforces Linux LF (`\n`) line endings across all platforms. |
| `.gitignore` | Git | Ignores local `.env` and temporary files while tracking `test_cavity/`. |
| `openfoam_course_workspace/` | Shared Storage | Your simulation projects folder (accessible from host and Docker). |
| `.../test_cavity/` | OpenFOAM Case | 100% self-contained 2D Lid-Driven Cavity beginner tutorial case. |

---

## 3. Prerequisites (One-Time Setup)

Before running simulations, install the following two free software packages on your computer:

### 1. Docker Desktop
Docker runs the Linux container containing OpenFOAM and Python.
* **Download:** [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
* **Installation notes:**
  * **Windows:** During installation, ensure the **"Use WSL 2 instead of Hyper-V"** option is checked. After installation, launch Docker Desktop from the Start Menu and wait until the bottom-left icon turns green (**Engine running**).
  * **macOS:** Download the version matching your chip (**Apple Silicon** for M1/M2/M3/M4 or **Intel**). Launch Docker Desktop from `/Applications` and approve system permissions.
  * **Linux:** Install `docker.io` and `docker-compose-v2` via your distribution's package manager (`sudo apt install docker.io docker-compose-v2`). Add your user to the docker group (`sudo usermod -aG docker $USER`).

### 2. ParaView
ParaView is the industry-standard open-source 3D scientific visualization software.
* **Download:** [https://www.paraview.org/download/](https://www.paraview.org/download/)
* **Recommended version:** Download the latest stable release (e.g., ParaView 5.12 or 5.13 for Windows/macOS).
* **Installation notes:**
  * **Windows:** Install into the default location (`C:\Program Files\ParaView...`). Our launcher scripts will automatically find it.
  * **macOS:** Drag `ParaView.app` into your `/Applications` folder.

---

## 4. Quick Start Guide: Your First Simulation in 3 Minutes

Follow these 4 simple steps to run your first OpenFOAM simulation:

### Step 1: Open the Environment

* **On Windows:**
  Double-click `start_openfoam.bat` (or open Command Prompt / PowerShell in this folder and run `.\start_openfoam.bat`).
* **On macOS or Linux:**
  Open your Terminal in this repository directory and run:
  ```bash
  ./start_openfoam.sh
  ```

> The script will check that Docker is running, auto-detect ParaView, build the container image, and drop you directly into an interactive bash prompt inside `/workspace`:
> ```text
> root@openfoam_course:/workspace#
> ```

---

### Step 2: Run the 2D Cavity Simulation

Inside the container terminal, navigate to the `test_cavity` directory and run the automated tutorial script:

```bash
cd test_cavity
./run_test.sh
```

**What happens behind the scenes:**
1. **Cleaning:** Removes any previous run artifacts.
2. **`blockMesh`:** Constructs a 2D computational grid (20x20 cells, 0.1m x 0.1m).
3. **`checkMesh`:** Confirms the grid geometry is valid and orthogonal.
4. **`icoFoam`:** Solves the unsteady Navier-Stokes equations for 0.5 physical seconds (100 time-steps).
5. **ParaView Marker:** Creates `cavity.foam` for 3D visualization.
6. **Python (`uv`):** Executes `plot_residuals.py` to extract solver convergence data and save `residuals.png`.

---

### Step 3: Inspect the Convergence Plot

Open `openfoam_course_workspace/test_cavity/residuals.png` on your host computer using your favorite image viewer.

The semi-log plot displays the initial residuals of velocity ($U_x$, $U_y$) and pressure ($p$) decreasing across physical time, demonstrating that the linear matrix solvers converged stably at every time-step!

---

### Step 4: Visualize 3D Velocity & Pressure in ParaView

From your host terminal (outside the container):

* **On Windows:**
  ```cmd
  open_paraview.bat
  ```
* **On macOS or Linux:**
  ```bash
  ./open_paraview.sh
  ```

### **3-Step ParaView Visual Checklist (For Beginners):**
1. **Click "Apply":**
   Look at the **Properties** panel on the left side of ParaView. Notice the blue **"Apply"** button with a green checkmark icon. Click it to load the mesh into the 3D viewport.
2. **Select Field:**
   In the top toolbar, find the active variable dropdown (which defaults to `"Solid Color"`). Change it to **`U`** (Velocity) or **`p`** (Pressure).
3. **Play Animation:**
   Click the green **Play** button (triangle) in the top VCR toolbar controls. Watch the moving lid induce a recirculating flow vortex inside the square cavity!

---

## 5. "OpenFOAM 101" Case Anatomy Guide

Every OpenFOAM case requires three mandatory subdirectories: `0/`, `constant/`, and `system/`. Understanding these three folders is the key to mastering OpenFOAM.

```
test_cavity/
|-- 0/                       <-- Time folder: Initial and boundary conditions
|   |-- p                    <-- Pressure field (dimensions, internal value, boundary walls)
|   `-- U                    <-- Velocity vector field (sliding lid speed, wall no-slip)
|
|-- constant/                <-- Physical properties & Mesh definition
|   |-- transportProperties  <-- Kinematic viscosity (nu = 0.01 m^2/s)
|   |-- physicalProperties   <-- Foundation-compatible mirror of transport properties
|   `-- polyMesh/            <-- Generated by blockMesh (points, faces, owner, neighbour)
|
`-- system/                  <-- Solver control and numerical algorithms
    |-- blockMeshDict        <-- Parametric mesh geometry definition
    |-- controlDict          <-- Solver selection, time-step (deltaT), run duration
    |-- fvSchemes            <-- Spatial and temporal discretization schemes
    `-- fvSolution           <-- Matrix solvers (PCG, PBiCGStab), tolerances, and PISO settings
```

### 1. The `0/` Folder (Initial & Boundary Conditions)
* Holds field files for variables solved by the equations at time $t = 0$.
* For laminar incompressible flow, the primary variables are **`p`** (kinematic pressure, $m^2/s^2$) and **`U`** (velocity vector, $m/s$).
* In `0/U`, the boundary patch `movingWall` has `value uniform (1 0 0);`, while `fixedWalls` has `type noSlip;`.
* The front and back planes have `type empty;`, which instructs OpenFOAM to treat the 3D grid as a 2D simulation.

### 2. The `constant/` Folder (Physical Properties & Mesh)
* Contains data that does not change over the course of the simulation.
* **`transportProperties`** defines the fluid model (`Newtonian`) and kinematic viscosity `nu` ($\nu = 0.01 \, m^2/s$).
* With lid speed $U = 1.0 \, m/s$ and cavity dimension $L = 0.1 \, m$, the Reynolds number is:
  $$\text{Re} = \frac{U \cdot L}{\nu} = \frac{1.0 \cdot 0.1}{0.01} = 10$$
* The **`polyMesh/`** subfolder is created when you run `blockMesh`. It stores the actual nodes, cell faces, cell bounding volumes, and boundary connectivity.

### 3. The `system/` Folder (Solver Control & Numerical Schemes)
* **`controlDict`:** Specifies the solver application (`icoFoam`), simulation start and end time (`startTime 0; endTime 0.5;`), time-step size (`deltaT 0.005;`), and write interval (`writeInterval 20;`).
* **`fvSchemes`:** Specifies how continuous differential operators are discretized into algebraic equations.
  * `ddtSchemes`: Time derivative $\partial / \partial t$ (e.g., `Euler`).
  * `gradSchemes`: Spatial gradient $\nabla$ (e.g., `Gauss linear`).
  * `divSchemes`: Convection term $\nabla \cdot (\phi \mathbf{U})$ (e.g., `Gauss linear`).
  * `laplacianSchemes`: Diffusion term $\nabla^2 (\nu \mathbf{U})$ (e.g., `Gauss linear orthogonal`).
* **`fvSolution`:** Configures iterative matrix equation solvers:
  * Uses **PCG** (Preconditioned Conjugate Gradient) for pressure equations.
  * Uses **PBiCGStab** (Preconditioned Bi-Conjugate Gradient Stabilized) for velocity components.
  * Sets up the **PISO** (Pressure-Implicit with Splitting of Operators) loop and pins `pRefCell 0; pRefValue 0;` because all cavity boundaries are enclosed walls.

---

## 6. Daily Course Cheat Sheet

### Essential OpenFOAM Commands
Run these commands inside the container terminal:

| Command | Purpose |
| :--- | :--- |
| `blockMesh` | Generates a structured hexahedral mesh from `system/blockMeshDict`. |
| `checkMesh` | Checks mesh validity, non-orthogonality, aspect ratios, and skewness. |
| `icoFoam` | Transient solver for incompressible, laminar flow of Newtonian fluids. |
| `simpleFoam` | Steady-state solver for incompressible turbulent or laminar flow (RANS). |
| `pimpleFoam` | Transient solver for incompressible turbulent or laminar flow. |
| `touch case.foam` | Creates a ParaView reader marker file inside the case directory. |
| `foamCleanTutorials` | Cleans generated time-step folders and logs from the current directory. |

### Working with Python and `uv`
The container includes Astral `uv` and Python 3 pre-configured in `/opt/venv`:

```bash
# Run a Python analysis script
python plot_residuals.py

# Check installed packages
uv pip list

# Install any additional Python package on the fly
uv pip install scipy sympy
```

---

## 7. Troubleshooting & FAQ

### Q1: `start_openfoam` says "Docker daemon is not running". What should I do?
* **Solution:** Open Docker Desktop from your operating system application menu. Wait 15-30 seconds until Docker Desktop finishes starting and reports "Engine running" in green. Then re-run `start_openfoam.bat` or `./start_openfoam.sh`.

### Q2: ParaView gives an error or isn't auto-detected.
* **Solution:** Open `.env` in any text editor. Uncomment and set the exact path to your ParaView executable:
  * Windows: `PARAVIEW_PATH="C:\Program Files\ParaView 5.12.0\bin\paraview.exe"`
  * macOS: `PARAVIEW_PATH="/Applications/ParaView-5.12.0.app/Contents/MacOS/paraview"`
  * Linux: `PARAVIEW_PATH="/usr/bin/paraview"`

### Q3: I am on an Apple Silicon Mac (M1/M2/M3/M4). Does this run natively?
* **Solution:** Yes! The base image `microfluidica/openfoam:latest` is built natively for `linux/arm64`. Docker runs it without Rosetta emulation overhead.

### Q4: Are my simulation files lost when I stop or restart the container?
* **Solution:** No! The entire directory `openfoam_course_workspace/` is mounted directly from your host machine. Any files written inside `/workspace` inside Docker are saved permanently onto your computer's hard drive.

### Q5: How do I cleanly stop the container when I am done?
* **Solution:** Run `stop_openfoam.bat` (Windows) or `./stop_openfoam.sh` (macOS/Linux). This gracefully stops the background container.

---
*Happy Computing! Enjoy your OpenFOAM journey.*
