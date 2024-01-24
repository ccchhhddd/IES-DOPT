#测试组件是否可用
include("./head.jl")
include("./function.jl")
include("./FluidMechanics/VenturiMeter.jl")

#Q = paras["仿真参数"]["流量(m^3/s)"], friction = true, Media = paras["仿真参数"]["流体种类"]
paras = Dict("inputdata"=>Dict("仿真参数" => Dict("流量(m^3/s)" => 0.1, "流体种类" => "Water")),
             "mode" => 1)
println(paras)
figure = simulate_2!(paras["inputdata"],Val(paras["mode"]))

