#测试组件是否可用
include("./head.jl")
include("./components.jl")
include("./simulation.jl")
# {
#    "inputdata": {
#                        "仿真参数": {
#                                            "热流体流量(kg/s)": 4,
#                                               "热流体温度(K)": "600",
#                                            "冷流体流量(kg/s)": 4,
#                                               "冷流体温度(K)": 300,
#                                               "换热管长度(m)": 10,
#                                                  "热流体种类": "Water",
#                                                  "冷流体种类": "Water"
#                                    }
#                 },
#         "mode": 1
# }
paras = Dict("inputdata" => Dict("仿真参数" => Dict("热流体流量(kg/s)" => 4,
																									"热流体温度(K)" => 600,
																									"冷流体流量(kg/s)" => 4,
																									"冷流体温度(K)" => 300,
																									"换热管长度(m)" => 10,
																									"热流体种类" => "Water",
																									"冷流体种类" => "Water")),
             "mode" => 1)
println(paras["inputdata"])
println(paras["mode"])

#println(paras)
figure,table = simulate_1!(paras["inputdata"],Val(paras["mode"]))

