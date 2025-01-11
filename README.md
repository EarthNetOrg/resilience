# Social Resilience ABM in Julia

This repository contains a **social resilience** Agent-Based Model (ABM) using [**Agents.jl**](https://juliadynamics.github.io/Agents.jl/stable/). The model explores how agents gather, store, and expend resources, generate waste, and adapt within a simple 2D environment.

## Key Features

- **Agents** with:
  - **Static store** (can only deplete)
  - **Dynamic store** (can replenish and is used first)
  - **Waste store** (accumulates over time)
- **Environment (2D Grid)**
  - `static_energy`, `dynamic_energy`, `waste` on each cell
  - Periodic boundary conditions (wrap-around)
- **Parameter-driven** behaviors:
  - Movement costs
  - Resource gathering and waste generation
  - Energy output back to environment
  - Rules for preferring dynamic vs. static resources

## Getting Started

### Prerequisites

1. **Julia** (version 1.6 or later)  
   - Download from [julialang.org/downloads](https://julialang.org/downloads).
2. **Agents.jl** (and optionally Plots, InteractiveDynamics for visualization)

### Installation

1. **Clone or download** this repository:
   ```bash
   git clone https://github.com/YourUsername/social-resilience-abm-julia.git
   cd social-resilience-abm-julia
