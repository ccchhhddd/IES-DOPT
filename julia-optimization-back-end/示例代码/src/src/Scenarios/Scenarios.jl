module Scenarios

using ModelingToolkit, DifferentialEquations
using ..HRESDesign, ..HRESDesign.EnergyFlowComponents
using BlackBoxOptim, ActuaryUtilities, OrderedCollections
using DataFrames, CSV

include("utils.jl")
include("RE2H2.jl")


export simulation_RE2H2,
       optimization_RE2H2,
       simulation_RE2Channel,
       optimization_RE2Channel

export save_csv

end

