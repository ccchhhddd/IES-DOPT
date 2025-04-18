using Plots, DataFrames, CSV
using OrderedCollections: OrderedDict

include("structs.jl")
include("function_Electricity.jl")
include("function_Financial.jl")
include("function_Gas.jl")
include("function.jl")
include("simulate.jl")
include("optimize.jl")

paras = Dict("inputdata" => Dict(
                          "风电参数" => Dict(
                                          "单机容量(kw)" => 1500,
                                          "机组数量" => 2500,
                                          "风轮传动效率" => 0.96,
                                          "风速切入速度(m/s)" => 10.0,
                                          "风速切出速度(m/s)" =>135.0,
                                          "截止风速速度(m/s)" =>150.0,                                  
                                          "发电机效率" => 0.93,
                                          "使用年限(年)" => 20,
                                          "初始成本(元/kw)" => 4800,
                                          "年运维成本(元/kw)" => 720,
                                          "更换成本(元/kw)" => 4800
                                            ),
                          "光电参数" => Dict(
                                          "单机容量(kw)" => 3.5,
                                          "机组数量" => 1e6,
                                          "光伏板面积(m2)" => 3.1,
                                          "光伏板温度系数" =>0.0034,
                                          "光伏板吸收率" => 0.9,
                                          "使用年限(年)" => 20,
                                          "初始成本(元/kw)" => 3800,
                                          "年运维成本(元/kw)" => 190,
                                          "更换成本(元/kw)" => 3800
                                            ),
                          "气电参数" => Dict(
                                          "单机容量(kw)" => 6.5e6,
                                          "机组数量" => 5,
                                          "最小出力效率" => 0.2,
                                          "出力调整系数" => 0.05,
                                          "发电效率" => 0.6,
                                          "使用年限(年)" => 20,
                                          "初始成本(元/kw)" => 4800,
                                          "年运维成本(元/kw)" => 160,
                                          "更换成本(元/kw)" => 4800
                                          ),
                          "整流器参数" => Dict(
                                          "单机容量(kw)" => 1500,
                                          "机组数量" => 10,
                                          "综合效率" => 0.9,
                                          "使用年限(年)" => 20,
                                          "初始成本(元/kw)" => 2300,
                                          "年运维成本(元/kw)" => 46,
                                          "更换成本(元/kw)" => 2300
                                          ),
                          "压缩空气储能参数" => Dict(
                                          "单机容量(kw)" => 5000,
                                          "机组数量" => 30,
                                          "充电效率" => 0.6,
                                          "使用年限(年)" => 15,
                                          "初始成本(元/kw)" => 3800,
                                          "年运维成本(元/kw)" => 190,
                                          "更换成本(元/kw)" => 3800
                                          ),
                          "电解槽参数" => Dict(
                                          "单机容量(kw)" => 5000,
                                          "机组数量" => 100,
                                          "使用年限(年)" => 10,
                                          "初始成本(元/kw)" => 2000,
                                          "年运维成本(元/kw)" => 100,
                                          "更换成本(元/kw)" => 2000
                                          ),
                          "氢气压缩机参数" => Dict(
                                          "单机容量(kg)" => 500,
                                          "机组数量" => 100,
                                          "单位耗电量(kWh/kg)" => 1.0,
                                          "使用年限(年)" => 20,
                                          "初始成本(元/kg)" => 2300,
                                          "年运维成本(元/kg)" => 46,
                                          "更换成本(元/kg)" => 2300
                                          ),
                          "储氢罐参数" => Dict(
                                          "单机容量(kg)" => 5000,
                                          "机组数量" => 10,
                                          "使用年限(年)" => 20,
                                          "初始成本(元/kg)" => 2300,
                                          "年运维成本(元/kg)" => 46,
                                          "更换成本(元/kg)" => 2300
                                          ),
                          "经济性分析参数" => Dict(
                                          "运行天数" => 360,
                                          "氢气生产用水成本(元/kg)" => 0.021,
                                          "氢气销售价格(元/kg)" => 25.58,
                                          "单次运输氢气费用(元/次)" => 1e5,
                                          "天然气价格(元/Nm³)" => 1.7,
                                          "最大投资金额(元)" => 1e11,
                                          "目标最小制氢量(kg)" => 1e4,
                            )
                            ),
             "opt_paras" => Dict(
                                  "select_obj" => 1,
                                  "select_slo" => "adaptive_de_rand_1_bin",
                                  ),
             "isOpt" => [1,1,1,0,0,0,0,0],
             "mode" => 1,
             "area" => 1,
             )
# select_obj可以分别以
# 1.氢气成本最低、
# 2.氢气产能最大、
# 3.总投资成本最低
# 等作为优化目标，计算得出多元系统各要素的最佳配置比例。
figure,figure1,figure2,table = optimize!(paras["inputdata"],paras["opt_paras"],paras["isOpt"], paras["area"],Val(paras["mode"]))
println(table)
