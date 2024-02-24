import ActuaryUtilities.FinanceCore.rate
using ActuaryUtilities: present_value, irr, breakeven
using OrderedCollections: OrderedDict

include("structs.jl")
include("simulate.jl")
include("financial-functions.jl")
include("energy-functions.jl")
include("economic-analysis.jl")
include("figure-data.jl")
include("optimize.jl")


"""
读取前端数据，生成设备数据结构体
"""
function generateData(paras, N)
    if N <= 3
        wt = WindTurbine(
            input_v=S1_DATA_WS,
            capacity=paras["风电参数"]["装机容量（千瓦）"],
            # unit_capacity=paras["风电参数"]["单位设备容量（kW）"],
            # η_inverter=paras["风电参数"]["综合效率"],
            life_year=paras["风电参数"]["产品寿命（年）"],
            cost_initial=paras["风电参数"]["投资成本（￥/kW）"] * 1.2,
            # cost_OM=paras["风电参数"]["运维成本（￥/kW）"],
            cost_replace=paras["风电参数"]["替换成本（￥/kW）"] * 1.2
        )
        pv = PhotovoltaicCell(
            input_GI=S1_DATA_GI, input_Ta=S1_DATA_TA, input_v=S1_DATA_WS,
            capacity=paras["光伏参数"]["装机容量（千瓦）"],
            # unit_capacity=paras["光伏参数"]["单位设备容量（kW）"],
            # η_inverter=paras["光伏参数"]["综合效率"],
            life_year=paras["光伏参数"]["产品寿命（年）"],
            cost_initial=paras["光伏参数"]["投资成本（￥/kW）"] * 1.2,
            # cost_OM=paras["光伏参数"]["运维成本（￥/kW）"],
            cost_replace=paras["光伏参数"]["替换成本（￥/kW）"] * 1.2
        )
        ec = ElectrolyticCell(
            # load=S1_DATA_LOAD,
            load=paras["电解槽参数"]["目标产氢量（吨）"] * 1e3 / 8760 * ones(Float64, 8760),
            capacity=paras["电解槽参数"]["装机容量（千瓦）"],
            # unit_capacity=paras["电解槽参数"]["单位设备容量（kW）"],
            # η_inverter=paras["电解槽参数"]["综合效率"],
            life_year=paras["电解槽参数"]["产品寿命（年）"],
            cost_initial=paras["电解槽参数"]["投资成本（￥/kW）"],
            # cost_OM=paras["电解槽参数"]["运维成本（￥/kW）"],
            cost_replace=paras["电解槽参数"]["替换成本（￥/kW）"]
        )
        hc = HydrogenCompressor(
            # load=S1_DATA_LOAD,
            load=paras["压缩机参数"]["目标压缩氢气量（吨）"] * 1e3 / 8760 .* ones(Float64, 8760),
            capacity=paras["压缩机参数"]["装机容量（kg）"],
            life_year=paras["压缩机参数"]["产品寿命（年）"],
            cost_initial=paras["压缩机参数"]["投资成本（￥/kg）"],
            cost_replace=paras["压缩机参数"]["替换成本（￥/kg）"]
        )
        hs = HydrogenStorage(
            capacity=paras["储氢罐参数"]["装机容量（kg）"],
            life_year=paras["储氢罐参数"]["产品寿命（年）"],
            cost_initial=paras["储氢罐参数"]["投资成本（￥/kg）"],
            cost_replace=paras["储氢罐参数"]["替换成本（￥/kg）"]
        )
        # es = EnergyStorage(
        #     capacity=paras["储能参数"]["装机容量（千瓦时）"],
        #     unit_capacity=paras["储能参数"]["单位设备容量（kW）"],
        #     charging_limit=paras["储能参数"]["充能阈值"],
        #     life_year=paras["储能参数"]["产品寿命（年）"],
        #     cost_initial=paras["储能参数"]["投资成本（￥/kW）"],
        #     cost_OM=paras["储能参数"]["运维成本（￥/kW）"],
        #     cost_replace=paras["储能参数"]["替换成本（￥/kW）"]
        # )
        e_es = ElectrochemicalEnergyStorage(
            capacity=paras["电化学储能参数"]["装机功率（千瓦）"] * paras["电化学储能参数"]["小时数（小时）"],
            hours=paras["电化学储能参数"]["小时数（小时）"],
            # unit_capacity=paras["电化学储能参数"]["单位设备容量（kW）"],
            # charging_limit=paras["电化学储能参数"]["充能阈值"],
            life_year=paras["电化学储能参数"]["产品寿命（年）"],
            cost_initial=paras["电化学储能参数"]["投资成本（￥/kW）"],
            # cost_OM=paras["电化学储能参数"]["运维成本（￥/kW）"],
            cost_replace=paras["电化学储能参数"]["替换成本（￥/kW）"]
        )
        ca_es = CompressAirEnergyStorage(
            capacity=paras["压缩空气储能参数"]["装机功率（千瓦）"] * paras["压缩空气储能参数"]["小时数（小时）"],
            hours=paras["压缩空气储能参数"]["小时数（小时）"],
            # unit_capacity=paras["压缩空气储能参数"]["单位设备容量（kW）"],
            # charging_limit=paras["压缩空气储能参数"]["充能阈值"],
            life_year=paras["压缩空气储能参数"]["产品寿命（年）"],
            cost_initial=paras["压缩空气储能参数"]["投资成本（￥/kW）"],
            # cost_OM=paras["压缩空气储能参数"]["运维成本（￥/kW）"],
            cost_replace=paras["压缩空气储能参数"]["替换成本（￥/kW）"]
        )
        cp = Nothing()
        gp = Nothing()
        fin = Financial(
            n_sys=paras["经济性参数"]["系统运营年限（年）"],
            rate_discount=paras["经济性参数"]["目标收益率"],
            rate_tax=paras["经济性参数"]["所得税率"],
            # rate_depreciation=paras["经济性参数"]["折旧率"],
            cost_water_per_kg_H2=paras["经济性参数"]["电解水成本（￥/kg）"],
            peak_price_from_grid=paras["经济性参数"]["高峰买电电价（￥/kwh）"],
            valley_price_from_grid=paras["经济性参数"]["低谷买电电价（￥/kwh）"],
            flat_price_from_grid=paras["经济性参数"]["平段买电电价（￥/kwh）"],
            price_to_grid=paras["经济性参数"]["卖电电价（￥/kwh）"],
            H2price_sale=paras["经济性参数"]["氢气售卖价格（￥/kg）"]
        )
        return (pv, wt, ec, hc, hs, e_es, ca_es, cp, gp), fin
    elseif N <= 7
        wt = WindTurbine(
            # 1.2 为容配比例
            input_v=S2_DATA_WS,
            capacity=paras["风电参数"]["装机容量（千瓦）"],
            # unit_capacity=paras["风电参数"]["单位设备容量（kW）"],
            # η_inverter=paras["风电参数"]["综合效率"],
            life_year=paras["风电参数"]["产品寿命（年）"],
            cost_initial=paras["风电参数"]["投资成本（￥/kW）"] * 1.2,
            # cost_OM=paras["风电参数"]["运维成本（￥/kW）"],
            cost_replace=paras["风电参数"]["替换成本（￥/kW）"] * 1.2,
            # staff_number=paras["风电参数"]["人员数"]
        )
        pv = PhotovoltaicCell(
            input_GI=S2_DATA_GI, input_Ta=S2_DATA_TA, input_v=S2_DATA_WS,
            capacity=paras["光伏参数"]["装机容量（千瓦）"],
            # unit_capacity=paras["光伏参数"]["单位设备容量（kW）"],
            # η_inverter=paras["光伏参数"]["综合效率"],
            life_year=paras["光伏参数"]["产品寿命（年）"],
            cost_initial=paras["光伏参数"]["投资成本（￥/kW）"] * 1.2,
            # cost_OM=paras["光伏参数"]["运维成本（￥/kW）"],
            cost_replace=paras["光伏参数"]["替换成本（￥/kW）"] * 1.2,
            # staff_number=paras["光伏参数"]["人员数"]
        )
        ec = Nothing()
        hc = Nothing()
        # es = EnergyStorage(
        #     capacity=paras["储能参数"]["装机容量（千瓦时）"],
        #     unit_capacity=paras["储能参数"]["单位设备容量（kW）"],
        #     charging_limit=paras["储能参数"]["充能阈值"],
        #     life_year=paras["储能参数"]["产品寿命（年）"],
        #     cost_initial=paras["储能参数"]["投资成本（￥/kW）"],
        #     cost_OM=paras["储能参数"]["运维成本（￥/kW）"],
        #     cost_replace=paras["储能参数"]["替换成本（￥/kW）"]
        # )
        p_es = PumpedStorage(
            capacity=paras["抽水蓄能参数"]["装机功率（千瓦）"] * paras["抽水蓄能参数"]["小时数（小时）"],
            hours=paras["抽水蓄能参数"]["小时数（小时）"],
            # unit_capacity=paras["抽水蓄能参数"]["单位设备容量（kW）"],
            # charging_limit=paras["抽水蓄能参数"]["充能阈值"],
            life_year=paras["抽水蓄能参数"]["产品寿命（年）"],
            cost_initial=paras["抽水蓄能参数"]["投资成本（￥/kW）"] - paras["抽水蓄能参数"]["容量电价（￥/kW）"],
            # cost_OM=paras["抽水蓄能参数"]["运维成本（￥/kW）"],
            cost_replace=paras["抽水蓄能参数"]["替换成本（￥/kW）"],
            # staff_number=paras["抽水蓄能参数"]["人员数"]
        )
        ca_es = CompressAirEnergyStorage(
            capacity=paras["压缩空气储能参数"]["装机功率（千瓦）"] * paras["压缩空气储能参数"]["小时数（小时）"],
            hours=paras["压缩空气储能参数"]["小时数（小时）"],
            # unit_capacity=paras["压缩空气储能参数"]["单位设备容量（kW）"],
            # charging_limit=paras["压缩空气储能参数"]["充能阈值"],
            life_year=paras["压缩空气储能参数"]["产品寿命（年）"],
            cost_initial=paras["压缩空气储能参数"]["投资成本（￥/kW）"],
            # cost_OM=paras["压缩空气储能参数"]["运维成本（￥/kW）"],
            cost_replace=paras["压缩空气储能参数"]["替换成本（￥/kW）"],
            # staff_number=paras["压缩空气储能参数"]["人员数"]
        )
        e_es = ElectrochemicalEnergyStorage(
            capacity=paras["电化学储能参数"]["装机功率（千瓦）"] * paras["电化学储能参数"]["小时数（小时）"],
            hours=paras["电化学储能参数"]["小时数（小时）"],
            # unit_capacity=paras["电化学储能参数"]["单位设备容量（kW）"],
            # charging_limit=paras["电化学储能参数"]["充能阈值"],
            life_year=paras["电化学储能参数"]["产品寿命（年）"],
            cost_initial=paras["电化学储能参数"]["投资成本（￥/kW）"],
            # cost_OM=paras["电化学储能参数"]["运维成本（￥/kW）"],
            cost_replace=paras["电化学储能参数"]["替换成本（￥/kW）"],
            # staff_number=paras["电化学储能参数"]["人员数"]
        )
        cp = CoalPower(
            capacity=paras["煤电参数"]["装机容量（千瓦）"],
            # unit_capacity=paras["煤电参数"]["单位设备容量（kW）"],
            η=paras["煤电参数"]["发电效率"],
            life_year=paras["煤电参数"]["产品寿命（年）"],
            cost_initial=paras["煤电参数"]["投资成本（￥/kW）"],
            # cost_OM=paras["煤电参数"]["运维成本（￥/kW）"],
            cost_replace=paras["煤电参数"]["替换成本（￥/kW）"],
            # staff_number=paras["煤电参数"]["人员数"]
        )
        gp = GasPower(
            capacity=paras["气电参数"]["装机容量（千瓦）"],
            # unit_capacity=paras["气电参数"]["单位设备容量（kW）"],
            η=paras["气电参数"]["发电效率"],
            life_year=paras["气电参数"]["产品寿命（年）"],
            cost_initial=paras["气电参数"]["投资成本（￥/kW）"],
            # cost_OM=paras["气电参数"]["运维成本（￥/kW）"],
            cost_replace=paras["气电参数"]["替换成本（￥/kW）"],
            # staff_number=paras["气电参数"]["人员数"]
        )
        fin = Financial(
            n_sys=paras["经济性参数"]["系统运营年限（年）"],
            rate_discount=paras["经济性参数"]["目标收益率"],
            rate_tax=paras["经济性参数"]["所得税率"],
            # rate_depreciation=paras["经济性参数"]["折旧率"],
            price_coal_per_kg=paras["经济性参数"]["煤价格（￥/kg）"],
            price_to_grid=paras["经济性参数"]["卖电电价（￥/kwh）"],
            price_gas_per_Nm3=paras["经济性参数"]["燃气价格（￥/Nm3）"],
            gas_factor=paras["经济性参数"]["气电碳排放因子（kg/kWh）"],
            coal_factor=paras["经济性参数"]["煤电碳排放因子（kg/kWh）"],
        )
        channelpower = paras["channelConstraints"]
        return (pv, wt, ec, hc, p_es, ca_es, e_es, cp, gp, channelpower), fin
    else
        wt = WindTurbine(
            input_v=S3_DATA_WS,
            capacity=paras["风电参数"]["装机容量（千瓦）"],
            unit_capacity=paras["风电参数"]["单位设备容量（kW）"],
            η_inverter=paras["风电参数"]["综合效率"],
            life_year=paras["风电参数"]["产品寿命（年）"],
            cost_initial=paras["风电参数"]["投资成本（￥/kW）"],
            cost_OM=paras["风电参数"]["运维成本（￥/kW）"],
            cost_replace=paras["风电参数"]["替换成本（￥/kW）"]
        )
        pv = PhotovoltaicCell(
            input_GI=S3_DATA_GI, input_Ta=S3_DATA_TA, input_v=S3_DATA_WS,
            capacity=paras["光伏参数"]["装机容量（千瓦）"],
            unit_capacity=paras["光伏参数"]["单位设备容量（kW）"],
            η_inverter=paras["光伏参数"]["综合效率"],
            life_year=paras["光伏参数"]["产品寿命（年）"],
            cost_initial=paras["光伏参数"]["投资成本（￥/kW）"],
            cost_OM=paras["光伏参数"]["运维成本（￥/kW）"],
            cost_replace=paras["光伏参数"]["替换成本（￥/kW）"]
        )
        ec = ElectrolyticCell(
            load=S3_DATA_LOAD,
            capacity=paras["电解槽参数"]["装机容量（千瓦）"],
            unit_capacity=paras["电解槽参数"]["单位设备容量（kW）"],
            η_inverter=paras["电解槽参数"]["综合效率"],
            life_year=paras["电解槽参数"]["产品寿命（年）"],
            cost_initial=paras["电解槽参数"]["投资成本（￥/kW）"],
            cost_OM=paras["电解槽参数"]["运维成本（￥/kW）"],
            cost_replace=paras["电解槽参数"]["替换成本（￥/kW）"]
        )
        hc = HydrogenCompressor(
            load=S3_DATA_LOAD,
            capacity=paras["储氢参数"]["装机容量（吨）"],
            unit_capacity=paras["储氢参数"]["单位设备容量（吨）"],
            life_year=paras["储氢参数"]["产品寿命（年）"],
            cost_initial=paras["储氢参数"]["投资成本（￥/吨）"],
            cost_OM=paras["储氢参数"]["运维成本（￥/吨）"],
            cost_replace=paras["储氢参数"]["替换成本（￥/吨）"]
        )
        es = EnergyStorage(
            capacity=paras["储能参数"]["装机容量（千瓦时）"],
            unit_capacity=paras["储能参数"]["单位设备容量（kW）"],
            charging_limit=paras["储能参数"]["充能阈值"],
            life_year=paras["储能参数"]["产品寿命（年）"],
            cost_initial=paras["储能参数"]["投资成本（￥/kW）"],
            cost_OM=paras["储能参数"]["运维成本（￥/kW）"],
            cost_replace=paras["储能参数"]["替换成本（￥/kW）"]
        )
        cp = CoalPower(
            capacity=paras["煤电参数"]["装机容量（千瓦）"],
            unit_capacity=paras["煤电参数"]["单位设备容量（kW）"],
            η=paras["煤电参数"]["发电效率"],
            life_year=paras["煤电参数"]["产品寿命（年）"],
            cost_initial=paras["煤电参数"]["投资成本（￥/kW）"],
            cost_OM=paras["煤电参数"]["运维成本（￥/kW）"],
            cost_replace=paras["煤电参数"]["替换成本（￥/kW）"]
        )
        gp = GasPower(
            capacity=paras["气电参数"]["装机容量（千瓦）"],
            unit_capacity=paras["气电参数"]["单位设备容量（kW）"],
            η=paras["气电参数"]["发电效率"],
            life_year=paras["气电参数"]["产品寿命（年）"],
            cost_initial=paras["气电参数"]["投资成本（￥/kW）"],
            cost_OM=paras["气电参数"]["运维成本（￥/kW）"],
            cost_replace=paras["气电参数"]["替换成本（￥/kW）"]
        )
        fin = Financial(
            n_sys=paras["经济性参数"]["系统运营年限（年）"],
            rate_discount=paras["经济性参数"]["目标收益率"],
            rate_tax=paras["经济性参数"]["所得税率"],
            rate_depreciation=paras["经济性参数"]["折旧率"],
            price_coal_per_kg=paras["经济性参数"]["煤价格（￥/kg）"],
            price_to_grid=paras["经济性参数"]["卖电电价（￥/kwh）"],
            price_gas_per_Nm3=paras["经济性参数"]["燃气价格（￥/Nm3）"],
            gas_factor=paras["经济性参数"]["气电碳排放因子（kg/kWh）"],
            coal_factor=paras["经济性参数"]["煤电碳排放因子（kg/kWh）"],
        )
        return (pv, wt, ec, hc, es, cp, gp), fin
    end
    # return (pv, wt, ec, hc, es, cp, gp), fin
end

"""
仿真接口函数，派发至具体情况的仿真函数
"""
function simulate_ies_ele!(paras, ::Val{N}) where {N}
    machines, fin = generateData(paras, N)
    return simulate_ies_ele!(machines, fin, Val(N))
end

"""
优化接口函数，派发至具体情况的优化函数
"""
function optimize_ies_ele!(paras, isopt::Vector, ::Val{N}) where {N}
    machines, fin = generateData(paras, N)
    return optimize_ies_ele!(machines, isopt, fin, Val(N))
end

"""
按照前端表格的格式返回数据：

[
    {
        items: xxx,
        value: xxx
    },
    {
        items: xxx,
        value: xxx
    }
]

"""
getTableData(table) = [Dict("items" => k, "value" => round(v, digits=2)) for (k, v) in table]

"""
将向量x中的正数和负数分开，返回两个向量：postive, negative
"""
function pn_split(x::Vector)
    postive, negative = zeros(length(x)), zeros(length(x))
    for i in eachindex(x)
        if x[i] > 0
            postive[i] = x[i]
        else
            negative[i] = x[i]
        end
    end
    return postive, negative
end

"""
返回小时级通道外送数据，分为冬夏两个季节

输入参数：
- `winter_data` 冬季数据
- `summer_data` 夏季数据
"""
function generateChannelConstrainData(
    winter_data=1e6 .* [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 5, 5, 5, 5, 5, 5, 5, 3, 3, 3, 3, 3, 3],
    summer_data=1e6 .* [4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 8, 8, 8, 8, 8, 8, 8, 8, 8, 4, 4, 4, 4, 4]
)
    day_1 = (31 + 28 + 31) #1-3 month
    day_2 = day_1 + (30 + 31 + 30 + 31 + 31 + 30) #4-9 month
    day_3 = day_2 + (31 + 30 + 31) #10-12 month
    EL_data = []
    for i in 1:365
        if 1 <= i <= day_1
            append!(EL_data, winter_data)
        elseif day_1 < i <= day_2
            append!(EL_data, summer_data)
        else
            append!(EL_data, winter_data)
        end
    end
    return EL_data
end
