module HRESDesign

using ModelingToolkit

@variables t
∂ = Differential(t)

export t, ∂

include("EnergyFlowComponents/EnergyFlowComponents.jl")
include("Scenarios/Scenarios.jl")

end # module HRESDesign
