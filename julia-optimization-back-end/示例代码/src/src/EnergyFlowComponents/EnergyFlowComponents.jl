module EnergyFlowComponents

using ModelingToolkit

using ..HRESDesign

include("utils.jl")
include("components/PhotovoltaicCell.jl")
include("components/WindTurbine.jl")
include("components/Battery.jl")
include("components/CompressedH2Tank.jl")
include("components/ElectrolyticCell.jl")


export PhotovoltaicCell,
    WindTurbine,
    Battery,
    ElectrolyticCell,
    CompressedH2Tank


export EnergySource,
    EnergyBus,
    EnergyStorage,
    Secrete,
    Constant,
    RealOutput,
    RealInput,
    get_datas,
    compare_energy

end

