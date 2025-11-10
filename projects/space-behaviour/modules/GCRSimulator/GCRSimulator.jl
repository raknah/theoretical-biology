using Interpolations, Distributions, StatsBase, Random, LinearAlgebra, StaticArrays

export GCRSimulator, simulate_events

mutable struct GCRSimulator

    energy_grid::Vector{Float64}
    particles::Vector{Symbol}
    parameters::Dict{Symbol, NamedTuple}
    area::Float64
    fluxes::Vector{Vector{Float64}}
    totalflux::Vector{Float64}
    λ::Float64
    cdfs::Vector{Vector{Float64}}
    inv_cdfs::Vector{Any}

end

function GCRSimulator(parameters::Dict{Symbol, <:NamedTuple};
    E0 = 1.0, Emin = 1.0, Emax = 3.0e4, points = 1000, area = 1.0)

    # hardcoded log-spaced energy grid
    energy_grid = 10 .^ range(log10(Emin), log10(Emax), length=points)
    ΔEs = diff(energy_grid)

    # particle names from parameter keys
    particles = collect(keys(parameters))

    # flux per species and total flux
    fluxes = Vector{Vector{Float64}}(undef, length(particles))
    for (i, particle) in enumerate(particles)
        params = parameters[particle]
        fluxes[i] = params.A .* (energy_grid./E0) .^ (-params.γ) .* exp.(-energy_grid/params.cutoff)
    end
    total_flux = reduce(+, fluxes)

    # trapezoidal integration for flux values
    function trapezoidal(flux)
        return cumsum(0.5 .* (flux[1:end-1] .+ flux[2:end]) .* ΔEs)
    end

    # calculate lambda
    totalfluxint = trapezoidal(total_flux)
    λ = area * 4π * totalfluxint[end]

    # CDFs and inv CDFS

    cdfs = Vector{Vector{Float64}}(undef, length(particles))
    inv_cdfs = Vector{Any}(undef, length(particles))

    for i in 1:length(particles)
        particlefluxint = trapezoidal(fluxes[i])
        particlefluxint = [0.0; particlefluxint]
        cdf = particlefluxint./particlefluxint[end]
        cdfs[i] = cdf
        inv_cdfs[i] = LinearInterpolation(cdf, energy_grid; extrapolation_bc = Throw())
    end

    return GCRSimulator(energy_grid, particles, parameters, area,
                        fluxes, total_flux, λ, cdfs, inv_cdfs)
end

using StaticArrays

function simulate_events(sim::GCRSimulator, N::Int)
    
    # arrival times from Poisson process
    Δts = rand(Exponential(1 / sim.λ), N)
    times = cumsum(Δts)

    # output arrays
    species    = Vector{Symbol}(undef, N)
    energies   = Vector{Float64}(undef, N)
    directions = Vector{SVector{3, Float64}}(undef, N)

    # sample particle types
    weights = [sim.parameters[p].weight for p in sim.particles]
    idxs = sample(1:length(sim.particles), Weights(weights), N)

    # loop over events
    for i in 1:N
        s_idx = idxs[i]
        species[i]  = sim.particles[s_idx]
        energies[i] = sim.inv_cdfs[s_idx](rand())  # sample from inverse CDF

        # isotropic direction
        ϕ = 2π * rand()
        μ = rand(Uniform(-1, 1))
        θ = acos(μ)
        directions[i] = SVector(sin(θ) * cos(ϕ), sin(θ) * sin(ϕ), cos(θ))
    end

    return times, species, energies, directions
end
