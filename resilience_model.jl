using Agents    # Core Agent-Based Modeling library
using Random    # For random number generation
using Agents.Schedulers

# Define the ResilienceAgent type using the new syntax
@agent struct ResilienceAgent(GridAgent{2})
    static_store::Float64 = 50.0    # We can provide defaults
    dynamic_store::Float64 = 0.0
    waste_store::Float64 = 0.0
    max_dynamic_store::Float64 = 100.0  # Maximum capacity for dynamic_store
    needed_energy::Float64 = 5.0
end

"""
    init_model(width=20, height=20, N=50; kwargs...)

Initialize an ABM with the given dimensions, number of agents, 
and model parameters (kwargs). Returns the ABM.
"""
function init_model(
    width::Int=20,
    height::Int=20,
    N::Int=2;
    rate_of_static_gather::Float64=1.0,
    rate_of_dynamic_gather::Float64=1.0,
    percent_waste_generated::Float64=0.1,
    dynamic_vs_static_preference::Float64=0.5,
    waste_impact_rate::Float64=1.0,
    initial_static_store::Float64=5000.0,
    initial_dynamic_store::Float64=1000.0,
    initial_waste_store::Float64=0.0,
    death_recycle_ratio::Float64=0.7,
    max_dynamic_store::Float64=100.0,
    needed_energy::Float64=5.0
)


    # 1) Create a periodic grid with given width and height
    space = GridSpace((width, height); periodic=true)

    # 2) Create the ABM with our custom agent type and the grid
    #    We'll store parameters in model.properties for easy access
    total_energy = 6000.0
    cells = width * height
    energy_per_cell = total_energy / cells

    # Distribute energy between static and dynamic (e.g., 80% static, 20% dynamic)
    static_energy = fill(energy_per_cell * 0.8, width, height)
    dynamic_energy = fill(energy_per_cell * 0.2, width, height)
    waste = fill(0.0, width, height)

    properties = (;
        rate_of_static_gather,
        rate_of_dynamic_gather,
        percent_waste_generated,
        dynamic_vs_static_preference,
        waste_impact_rate,
        static_energy,
        dynamic_energy,
        waste,
        rng=Random.default_rng(),
        death_recycle_ratio=death_recycle_ratio
    )

    model = ABM(
        ResilienceAgent,
        space;
        properties=properties,
        (agent_step!)=agent_step!,
        (model_step!)=model_step!,
        scheduler=Schedulers.Randomly()
    )

    # 5) Add N agents to the model
    for i in 1:N
        x = rand(model.rng, 1:width)
        y = rand(model.rng, 1:height)

        # Calculate how much we can take from dynamic_energy
        available_dynamic = min(dynamic_energy[x, y], initial_dynamic_store)
        dynamic_shortfall = initial_dynamic_store - available_dynamic

        # Check if we can cover the shortfall with static_energy
        total_static_needed = initial_static_store + dynamic_shortfall

        if static_energy[x, y] >= total_static_needed
            # Subtract from environment
            dynamic_energy[x, y] -= available_dynamic
            static_energy[x, y] -= total_static_needed

            agent = ResilienceAgent(
                i,
                (x, y),
                initial_static_store,
                initial_dynamic_store,
                initial_waste_store,
                max_dynamic_store,
                needed_energy
            )
            add_agent!(agent, model)
        end
    end

    return model
end

"""
    move_agent!(agent, model)

Move the agent to a random neighboring cell (Moore neighborhood).
Movement costs 1.0 energy, taken first from dynamic_store, then static_store.
"""
function move_agent_randomly!(agent::ResilienceAgent, model::ABM)
    # Get a list of all adjacent positions, including diagonals (radius 1)
    possible_moves = collect(nearby_positions(agent.pos, model, 1))
    # Choose one at random
    new_pos = possible_moves[rand(model.rng, 1:length(possible_moves))]
    # Move the agent to the new position
    move_agent!(agent, new_pos, model)

    # Movement cost
    movement_cost = 1.0
    if agent.dynamic_store >= movement_cost
        agent.dynamic_store -= movement_cost
    else
        # If not enough dynamic_store, use what's left and draw from static_store
        shortfall = movement_cost - agent.dynamic_store
        agent.dynamic_store = 0.0
        agent.static_store = max(agent.static_store - shortfall, 0.0)
        # If static_store also goes < 0, you could handle "death" or partial leftover
    end
end

"""
    gather_resources!(agent, model)

Agent gathers from static_energy and dynamic_energy on its patch.
Some fraction is converted to agent's waste_store.
If dynamic_store exceeds capacity, the excess is returned to environment 
and partially converted to patch-level waste.
"""
function gather_resources!(agent::ResilienceAgent, model::ABM)
    # Retrieve environment arrays and parameters from model
    static_energy = model.static_energy
    dynamic_energy = model.dynamic_energy
    waste = model.waste

    # Retrieve model parameters
    pref = model.dynamic_vs_static_preference
    rate_dyn = model.rate_of_dynamic_gather
    rate_stat = model.rate_of_static_gather
    waste_frac = model.percent_waste_generated

    (x, y) = agent.pos
    needed_energy = agent.needed_energy

    # Calculate how much dynamic vs static the agent aims to gather
    dynamic_target = needed_energy * pref
    static_target = needed_energy * (1.0 - pref)

    # The actual gather is limited by the environment resource and the gather rate
    d_gather = min(dynamic_energy[x, y], dynamic_target * rate_dyn)
    s_gather = min(static_energy[x, y], static_target * rate_stat)

    # Remove from environment
    dynamic_energy[x, y] -= d_gather
    static_energy[x, y] -= s_gather

    # Add to agent's dynamic_store
    total_collected = d_gather + s_gather
    agent.dynamic_store += total_collected

    # A fraction of that becomes waste in the agent
    agent.waste_store += total_collected * waste_frac

    # Check for max capacity on dynamic_store
    max_dynamic = 100.0
    if agent.dynamic_store > max_dynamic
        excess = agent.dynamic_store - max_dynamic
        agent.dynamic_store = max_dynamic

        # Return excess to environment as dynamic_energy
        dynamic_energy[x, y] += excess
        # Some fraction of that becomes patch waste
        waste[x, y] += 0.1 * excess
    end


    println("Before gather: static_energy[$x, $y] = ", static_energy[x, y])
    println("Gathered: s_gather = $s_gather")
    println("After gather: static_energy[$x, $y] = ", static_energy[x, y])

end

"""
    handle_output!(agent, model)

Agent expels energy into the environment at a rate determined by 
the environment waste, movement cost, etc.
"""
function handle_output!(agent::ResilienceAgent, model::ABM)
    static_energy = model.static_energy
    dynamic_energy = model.dynamic_energy
    waste = model.waste

    (x, y) = agent.pos
    env_waste = waste[x, y]

    # Calculate output based on agent's current stores instead of creating new energy
    base_output = min(
        agent.dynamic_store * 0.1,  # Output 10% of current stores
        agent.dynamic_store  # But never more than what agent has
    )

    # Deduct from agent
    agent.dynamic_store -= base_output

    # Distribute output to environment
    waste_ratio = 0.1
    dynamic_ratio = 1.0 - waste_ratio

    dynamic_energy[x, y] += base_output * dynamic_ratio
    waste[x, y] += base_output * waste_ratio
end

function log_agent_death(agent::ResilienceAgent, model::ABM)
    println("Agent $(agent.id) died at position $(agent.pos):")
    println("  static_store  = $(agent.static_store)")
    println("  dynamic_store = $(agent.dynamic_store)")
    println("  waste_store   = $(agent.waste_store)")
    println("  Total resources = $(agent.static_store + agent.dynamic_store + agent.waste_store)")
end


"""
    agent_step!(agent, model)

The function that is called once per agent on each step. 
It orchestrates the agent's move, gather, and output phases.
"""
function agent_step!(agent::ResilienceAgent, model::ABM)
    move_agent_randomly!(agent, model)
    gather_resources!(agent, model)
    handle_output!(agent, model)


    # Death condition:
    # if waste_store > static_store, agent "dies".
    if agent.waste_store > agent.static_store
        # Log the agent's state before removal
        log_agent_death(agent, model)

        # 1) Compute total resources held by the agent:
        total_agent_resources = agent.waste_store + agent.dynamic_store + agent.static_store

        # 2) Determine how resources get distributed
        x = model.death_recycle_ratio  # e.g. 0.7
        portion_dyn = x * total_agent_resources
        portion_waste = (1.0 - x) * total_agent_resources

        # 3) Add to environment at agent's location
        (px, py) = agent.pos
        model.dynamic_energy[px, py] += portion_dyn
        model.waste[px, py] += portion_waste

        # 4) Remove agent from the model
        remove_agent!(agent, model)
    end
end

"""
    model_step!(model)

Global updates that happen once per step, after all agents have moved. 
e.g. replenish dynamic_energy by some small amount each turn.
"""
function model_step!(model::ABM)
    # No automatic energy creation
    # Could add other model-wide updates here if needed
end


"""
    total_waste(model)

Compute total waste across all patches for monitoring or data collection.
"""
function total_waste(model::ABM)
    return sum(model.waste)
end

"""
    total_energy(model)

Calculate total energy in the system (environment + agents).
"""
function total_energy(model::ABM)
    # Environment energy
    env_energy = sum(model.static_energy) + sum(model.dynamic_energy) + sum(model.waste)

    # Agent energy
    agent_energy = sum(
        a.static_store + a.dynamic_store + a.waste_store
        for a in allagents(model)
    )

    return env_energy + agent_energy
end

"""
    run_resilience_model()

Create a model, run for 100 steps, and print total waste.
"""
function run_resilience_model()
    # 1) Create a model
    model = init_model(
        20, 20, 50;   # width=20, height=20, 50 agents
        rate_of_static_gather=1.0,
        rate_of_dynamic_gather=1.0,
        percent_waste_generated=0.1,
        dynamic_vs_static_preference=0.5,
        waste_impact_rate=1.0,
        initial_static_store=50.0,
        initial_dynamic_store=50.0,
        initial_waste_store=0.0,
        max_dynamic_store=50.0,   # Agents have a larger capacity for dynamic energy
        needed_energy=10.0
    )

    # 2) Run the simulation for 100 steps
    steps = 1000
    run!(model, steps)  # No need to pass the stepping functions anymore

    # 3) Print a summary
    println("After $steps steps:")
    println("  Total waste in environment = ", total_waste(model))
    println("  Number of agents left      = ", nagents(model))
    println("  Total static energy        = ", sum(model.static_energy))
    println("  Total dynamic energy       = ", sum(model.dynamic_energy))

    return model  # Return the model for inspection if needed
end

# Main entry point when run directly
if abspath(PROGRAM_FILE) == @__FILE__
    run_resilience_model()
end
