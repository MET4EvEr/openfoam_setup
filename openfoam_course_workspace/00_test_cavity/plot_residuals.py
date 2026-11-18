#!/usr/bin/env python3
"""
==============================================================================
OpenFOAM Residual Extraction & Convergence Plotting Tool
==============================================================================

PURPOSE:
Parses the solver log file (log.icoFoam), extracts initial residuals for
momentum components (Ux, Uy) and pressure (p) across time-steps, and plots
their convergence history on a semi-logarithmic scale.

DEPENDENCIES:
Pre-installed in the container virtual environment (/opt/venv) via `uv`:
  - numpy
  - pandas
  - matplotlib
==============================================================================
"""

import os
import re
import sys

# Crucial: Enforce headless non-GUI backend before importing pyplot
# This prevents crashes when running inside headless Linux Docker containers.
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd


def parse_solver_log(log_path: str) -> pd.DataFrame:
    """
    Parses OpenFOAM solver log for Time steps and Initial residuals.

    OpenFOAM prints solver lines in the following format:
      Time = 0.005
      ...
      Solving for Ux, Initial residual = 1, Final residual = 8.2323e-06, No Iterations 5
      Solving for Uy, Initial residual = 0, Final residual = 0, No Iterations 0
      Solving for p, Initial residual = 1, Final residual = 7.4215e-07, No Iterations 18
    """
    if not os.path.exists(log_path):
        raise FileNotFoundError(f"Solver log file not found: {log_path}")

    time_pattern = re.compile(r"^Time = ([\d.eE+-]+)")
    residual_pattern = re.compile(
        r"Solving for (\w+), Initial residual = ([\d.eE+-]+)"
    )

    records = []
    current_time = None
    current_step_residuals = {}

    with open(log_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line_strip = line.strip()

            # Detect new time-step header
            time_match = time_pattern.match(line_strip)
            if time_match:
                # Flush previous time-step if it contains data
                if current_time is not None and current_step_residuals:
                    entry = {"Time": current_time, **current_step_residuals}
                    records.append(entry)
                    current_step_residuals = {}
                current_time = float(time_match.group(1))
                continue

            # Detect residual solver lines
            res_match = residual_pattern.search(line_strip)
            if res_match:
                variable = res_match.group(1)
                initial_res = float(res_match.group(2))
                # Store the first occurrence in the time step (initial residual)
                if variable not in current_step_residuals:
                    current_step_residuals[variable] = initial_res

    # Flush the last step
    if current_time is not None and current_step_residuals:
        records.append({"Time": current_time, **current_step_residuals})

    df = pd.DataFrame(records)
    return df


def plot_residuals(df: pd.DataFrame, output_path: str = "residuals.png") -> None:
    """
    Generates a publication-quality semi-logarithmic residual convergence plot.
    """
    if df.empty:
        print("[WARNING] No residual data found to plot.")
        return

    fig, ax = plt.subplots(figsize=(10, 6), dpi=300)

    # Plot styles for each solved field
    styles = {
        "Ux": {"color": "#1f77b4", "label": "Ux (X-Velocity)", "linestyle": "-", "marker": "o"},
        "Uy": {"color": "#2ca02c", "label": "Uy (Y-Velocity)", "linestyle": "--", "marker": "s"},
        "p":  {"color": "#d62728", "label": "p (Pressure)",    "linestyle": "-.", "marker": "^"},
    }

    x_axis = df["Time"] if "Time" in df.columns else df.index

    for col in ["Ux", "Uy", "p"]:
        if col in df.columns:
            # Filter out non-positive values to prevent log scale errors
            valid_mask = df[col] > 0
            if valid_mask.any():
                ax.semilogy(
                    x_axis[valid_mask],
                    df.loc[valid_mask, col],
                    color=styles[col]["color"],
                    label=styles[col]["label"],
                    linestyle=styles[col]["linestyle"],
                    marker=styles[col]["marker"],
                    markevery=max(1, len(df) // 25),
                    markersize=5,
                    linewidth=2,
                    alpha=0.9,
                )

    # Format chart titles and axes
    ax.set_title("OpenFOAM 2D Cavity Flow: Solver Residual Convergence", fontsize=14, fontweight="bold", pad=12)
    ax.set_xlabel("Physical Time (seconds)", fontsize=12, fontweight="medium")
    ax.set_ylabel("Initial Residual (Log Scale)", fontsize=12, fontweight="medium")

    # Add primary and secondary grids
    ax.grid(True, which="major", linestyle="-", linewidth=0.8, alpha=0.7)
    ax.grid(True, which="minor", linestyle=":", linewidth=0.5, alpha=0.4)
    ax.minorticks_on()

    # Aesthetic legend
    ax.legend(loc="upper right", frameon=True, framealpha=0.95, fontsize=10, shadow=True)

    # Add annotations detailing case parameters
    info_text = (
        "Solver: icoFoam (PISO)\n"
        "Mesh: 20x20x1 (400 cells)\n"
        "Reynolds Number: Re = 10\n"
        "Time Step: deltaT = 0.005s"
    )
    ax.text(
        0.02,
        0.05,
        info_text,
        transform=ax.transAxes,
        fontsize=9,
        verticalalignment="bottom",
        bbox=dict(boxstyle="round,pad=0.5", facecolor="#f8f9fa", edgecolor="#cccccc", alpha=0.9),
    )

    plt.tight_layout()
    plt.savefig(output_path, dpi=300)
    plt.close()
    print(f"[SUCCESS] Convergence plot saved to: {output_path}")


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    log_file = os.path.join(script_dir, "log.icoFoam")
    output_png = os.path.join(script_dir, "residuals.png")

    if not os.path.exists(log_file):
        print(f"[ERROR] Log file '{log_file}' does not exist.")
        print("Please run icoFoam simulation first: icoFoam | tee log.icoFoam")
        sys.exit(1)

    print(f"Reading solver log: {log_file}")
    df = parse_solver_log(log_file)
    print(f"Extracted {len(df)} time-step residual entries.")
    plot_residuals(df, output_png)


if __name__ == "__main__":
    main()
