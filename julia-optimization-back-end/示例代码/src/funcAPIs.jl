@info "导入 funcAPIs.jl..."
# 生成前端图表数据

getFigureData(sol, ::Val{3}) = Dict(
    "储能供电量" => map(x -> x < 0 ? round(-x, digits=1) : 0, sol["BAT₊ΔE(t)"]),
    "风力发电量" => round.(sol["WT₊W(t)"], digits=1),
    "光伏发电量" => round.(sol["PV₊W(t)"], digits=1),
    "电解用电量" => round.(-sol["AEC₊W(t)"], digits=1),
    "储能充电量" => map(x -> x >= 0 ? round(-x, digits=1) : 0, sol["BAT₊ΔE(t)"]),
    #"储氢用电量" => map(x -> x >= 0 ? round(x, digits=1) : 0, sol["HT₊ΔE(t)"]),
)


# 生成前端表格数据[{items: "风电（万千瓦）", value: "90.82801252034335"}, ...]  
getTableData(table) = [Dict("items" => k, "value" => round(v, digits=2)) for (k, v) in table]
#=
多重派分代号：
1：风光制氢离网
=#

optimization(paras, isOptList, ::Val{3}) = optimization_RE2H2(S3_data_GI, S3_data_Ta, S3_data_WS, S3_data_H2L,
  Dict(:E_rated => paras["光伏参数"]["装机容量（千瓦）"],
        :E_device_rated => paras["光伏参数"]["单位设备容量（kW）"],
        :η_inverter => paras["光伏参数"]["综合效率"],
        :life_year => paras["光伏参数"]["产品寿命（年）"],
        :cost_initial => paras["光伏参数"]["投资成本（￥/kW）"],
        :cost_OM => paras["光伏参数"]["运维成本（￥/kW）"],
        :cost_replace => paras["光伏参数"]["替换成本（￥/kW）"]),
    Dict(
        :E_rated => paras["风电参数"]["装机容量（千瓦）"],
        :E_device_rated => paras["风电参数"]["单位设备容量（kW）"],
        :η_inverter => paras["风电参数"]["综合效率"],
        :life_year => paras["风电参数"]["产品寿命（年）"],
        :cost_initial => paras["风电参数"]["投资成本（￥/kW）"],
        :cost_OM => paras["风电参数"]["运维成本（￥/kW）"],
        :cost_replace => paras["风电参数"]["替换成本（￥/kW）"]),
    Dict(
        :E_rated => paras["电解槽参数"]["装机容量（千瓦）"],
        :E_device_rated => paras["电解槽参数"]["单位设备容量（kW）"],
        :η_inverter => paras["电解槽参数"]["综合效率"],
        :life_year => paras["电解槽参数"]["产品寿命（年）"],
        :cost_initial => paras["电解槽参数"]["投资成本（￥/kW）"],
        :cost_OM => paras["电解槽参数"]["运维成本（￥/kW）"],
        :cost_replace => paras["电解槽参数"]["替换成本（￥/kW）"]),
    Dict(
        :E_rated => paras["储氢参数"]["装机容量（吨）"],
        :E_device_rated => paras["储氢参数"]["单位设备容量（吨）"],
        :SoC_cha_thre => paras["储氢参数"]["充能阈值"],
        :life_year => paras["储氢参数"]["产品寿命（年）"],
        :cost_initial => paras["储氢参数"]["投资成本（￥/吨）"],
        :cost_OM => paras["储氢参数"]["运维成本（￥/吨）"],
        :cost_replace => paras["储氢参数"]["替换成本（￥/吨）"]),
    Dict(
        :E_rated => paras["储能参数"]["装机容量（千瓦时）"],
        :E_device_rated => paras["储能参数"]["单位设备容量（kW）"],
        :SoC_cha_thre => paras["储能参数"]["充能阈值"],
        :life_year => paras["储能参数"]["产品寿命（年）"],
        :cost_initial => paras["储能参数"]["投资成本（￥/kW）"],
        :cost_OM => paras["储能参数"]["运维成本（￥/kW）"],
        :cost_replace => paras["储能参数"]["替换成本（￥/kW）"]
    ),
    isOptList,
    1e2 * ones(length(isOptList)),
    1e6 * ones(length(isOptList)),
    n_sys=paras["经济性参数"]["系统运营年限（年）"],
    rate_discount=paras["经济性参数"]["目标收益率"],
    rate_tax=paras["经济性参数"]["综合税率"],
    rate_depreciation=paras["经济性参数"]["折旧率"],
    cost_water_per_kg_H2=paras["经济性参数"]["电解水成本（￥/kg）"],
    H2price_sale=paras["经济性参数"]["氢气售卖价格（￥/kg）"],
    gas_factor=paras["经济性参数"]["气电碳排放因子（kg/kWh）"],
    coal_factor=paras["经济性参数"]["煤电碳排放因子（kg/kWh）"],
    max_opt_time=paras["优化时长"]
)
