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

Below is a more detailed, step-by-step guide on setting up and running the Social Resilience ABM in Julia with Agents.jl. These instructions assume you have no prior Julia experience and want explicit details for each stage, from installing Julia to running the simulation.

### Detailed Setup and Usage Instructions

#### 1. **Install Julia**
1. Go to the official Julia downloads page: https://julialang.org/downloads/
2. Download the appropriate installer for your operating system (macOS, Windows, or Linux).
3. Follow the on-screen instructions to install Julia.
- On macOS, you typically drag the Julia app into your Applications folder or another preferred location.
- On Windows, you typically run an .exe installer.
- On Linux, you can extract a .tar.gz and place it in a convenient folder (or install via a package manager if available).
4. Verify your installation by opening a terminal (or command prompt) and typing:

```bash
julia --version
```

You should see a version number (e.g., julia version 1.9.2).

#### 2. Get This Repository Onto Your Machine

##### Option A: Git Clone (Recommended)

If you have Git installed:
1. Open a terminal or command prompt.
2. Navigate (cd) to the directory where you want to store this project, for example Documents/GitHub/.
3. Run:

```bash
git clone https://github.com/EarthNetOrg/social-resilience-abm-julia.git```

4. Enter the new directory:
```bash
    cd social-resilience-abm-julia```


##### Option B: Download ZIP
1. On the GitHub page of the repository, click “Code” → “Download ZIP”.
2. Unzip the file to a convenient location.
3. Open a terminal or command prompt and navigate (cd) into the unzipped folder.

### 3. Open Julia and Install Dependencies

#### 3.1. Launch Julia
- On macOS or Windows, you can open Terminal (macOS) or Command Prompt/Powershell (Windows), navigate to your project folder, and type:

    julia

Then press Enter to start the Julia REPL (Read-Eval-Print Loop).

- Alternatively, you may double-click the “Julia” application (on macOS) or start Julia from the Start menu (on Windows), then manually cd into your project folder from inside the Julia REPL.

#### 3.2. Pkg Mode and Environment Setup
1. Once you’re in the Julia REPL, you’ll see a prompt like:

    julia>


2. Press the ] key to enter “Pkg mode” — the prompt will change to something like:

    (@v1.9) pkg>

or (v1.x) pkg> depending on your Julia version.

3. Activate the project environment (optional but recommended). If your repo has a Project.toml file, you can do:

     (v1.x) pkg> activate .

This tells Julia to treat your local folder as a dedicated environment. If a Project.toml is included with the repository, you can then run instantiate:

4.	Install or instantiate your dependencies:
- If the repository includes Project.toml and Manifest.toml, you can do:

     (YourProjectName) pkg> instantiate

This automatically installs all needed packages in the correct versions.

- If you do not have a pre-defined Project.toml, you can manually add the packages:

   (v1.x) pkg> add Agents
   (v1.x) pkg> add Plots
   (v1.x) pkg> add InteractiveDynamics

(The last two are optional if you want plotting and interactive visualization.)

5. Press backspace to return to the main Julia prompt (julia>).

### 4. Explore or Edit the Code
1.	Open the repository folder in your favorite editor (e.g., VSCode, Atom, Sublime Text).
2.	The main code might be in a file called resilience_model.jl (or similarly named). Inside, you should see:
-	An agent definition (e.g. @agent ResilienceAgent ...)
-	An init_model function
-	Functions like agent_step!, model_step!, etc.-	A run_resilience_model or similar demonstration function

(You can edit these if you want to change parameters, agent logic, or environment rules.)

### 5. Run the Model

There are two typical approaches:

#### 5.1. Approach A: Directly in the REPL
1.	Navigate to your project folder in the terminal and launch Julia:

     cd path/to/social-resilience-abm-julia
     julia


2.	Activate the environment (optional but recommended):

     julia> ]
      (v1.x) pkg> activate .
      (v1.x) pkg> backspace

3.	Load the model file:

julia> include("resilience_model.jl")


4.	Run the demonstration function (e.g., run_resilience_model()), or manually create and step the model:

     julia> run_resilience_model()

This will typically run for 100 steps and print some output like:

After 100 steps, total waste in environment = 1234.56

#### 5.2. Approach B: Using VSCode’s Julia Extensions
	1.	Open the folder in VSCode.
	2.	Install the Julia extension if you haven’t already.
	3.	Open the resilience_model.jl file and look for the “play” button or “Run” button near each function.
	4.	You can highlight lines and press Shift + Enter to send them to the Julia REPL at the bottom.
	5.	Once all code is loaded, call the final function (e.g. run_resilience_model()) in the REPL.

### 6. Customizing Parameters

Depending on how the code is written, you might see a function like:

model = init_model(
    width = 20,
    height = 20,
    N = 50;
    rate_of_static_gather = 1.0,
    rate_of_dynamic_gather = 1.0,
    percent_waste_generated = 0.1,
    dynamic_vs_static_preference = 0.5,
    waste_impact_rate = 1.0,
    initial_static_store = 50.0,
    initial_dynamic_store = 50.0,
    initial_waste_store = 0.0
)

You can tweak these keyword arguments to explore different behaviors, for example:
	•	rate_of_dynamic_gather: Increase if you want agents to gather dynamic energy more quickly.
	•	percent_waste_generated: Increase if you want the system to produce more waste per resource gathered.
	•	dynamic_vs_static_preference: If 0.8, for instance, the agent strongly prefers dynamic energy.
	•	waste_impact_rate: Affects how much energy is expelled back to environment each step, based on the local waste level.

After customizing these parameters, you can run:

model = init_model(30, 30, 100; rate_of_dynamic_gather=2.0, ...)
run!(model, agent_step!, model_step!, 200)

(Here, run! is Agents.jl’s function that steps the model a certain number of times. The code might differ slightly depending on your exact script.)

### 7. Monitoring and Data Collection
	1.	Basic Logging: After each run, you might see console output of total waste or other aggregates.
	2.	DataCollector: In Agents.jl, you can use:

using Agents

mdata = Dict{Symbol, Vector{Float64}}()
add_model_measure!(model, mdata, :total_waste, total_waste)
run!(model, agent_step!, model_step!, 100; mdata = mdata)

# Now mdata[:total_waste] is an array of total_waste per step


	3.	Plots: You can visualize the data with Plots.jl. For example:

using Plots
plot(mdata[:total_waste], ylabel="Total Waste", xlabel="Step")

8. Visualizing the Grid (Optional)

If you’d like to see an actual grid or interactive environment:
	1.	Install InteractiveDynamics.jl:

(v1.x) pkg> add InteractiveDynamics


	2.	Then you can do something like:

using InteractiveDynamics

abm_plot(
    model;
    ac = agent -> :blue,         # color of agents
    as = 0.8,                    # agent size
    am = :circle,                # agent shape
    am_parallel = true           # optional, for parallel processing
)


	3.	You might also create a function for colorizing patches based on waste or dynamic_energy. Check the InteractiveDynamics documentation for more details on advanced usage.

9. Troubleshooting
	•	“Command Not Found: julia”: Make sure Julia is on your PATH or start it directly by double-clicking the Julia app.
	•	Package Installation Errors: If you see “No project found,” ensure you used ] activate . in the correct folder or add the needed packages individually.
	•	Outdated Julia Version: Agents.jl typically requires Julia 1.6 or newer. Update your Julia version if necessary.

10. Next Steps
	•	Experiment with different parameter values to see how waste accumulates or how quickly agents run out of resources.
	•	Extend agent behavior: for example, add rules for agent “death” if their static store hits zero, or for “reproduction” if they have a surplus of energy.
	•	Collect data systematically across many runs (e.g. with DrWatson.jl or your own scripts) and analyze emergent patterns.
	•	Visualize outputs with line plots, heatmaps, or interactive dashboards.

Done!

You now have a detailed blueprint for:
	1.	Installing Julia.
	2.	Acquiring the repository (via Git or ZIP).
	3.	Installing the necessary Julia packages.
	4.	Running the ABM in either a terminal-based REPL or VSCode.
	5.	Customizing model parameters and collecting data.

With these steps, you should be able to explore, experiment with, and extend the Social Resilience ABM in Agents.jl on your local system. Happy modeling!
