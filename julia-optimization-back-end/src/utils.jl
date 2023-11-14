import ActuaryUtilities.FinanceCore.rate
using ActuaryUtilities: present_value, irr, breakeven
using OrderedCollections: OrderedDict

include("structs.jl")
include("simulate.jl")
include("economic-analysis.jl")
include("figure-data.jl")
include("optimize.jl")

"""
返回风力发电机的年发电量
"""
outputEnergy(wt::WindTurbine) = @. wt.k(wt.input_v * (wt.h2 / wt.h1)^wt.α) * wt.capacity * wt.η_t * wt.η_g * wt.Δt * wt.η_inverter

"""
返回光伏组件的日发电量列表
"""
outputEnergy(pv::PhotovoltaicCell) = @. pv.f_PV * (1.0 + pv.λ * (pv.input_Ta - pv.Tc_ref) + pv.λ * pv.input_GI * pv.tau_alpha / (5.7 + 3.8 * pv.input_v) * (1 - pv.η_PV_ref)) * pv.input_GI / 1000 * pv.capacity * pv.Δt * pv.η_inverter

"""
返回电解槽的日产氢耗电量列表
"""
# outputEnergy(ec::ElectrolyticCell) = @. ec.load / ec.Δt / ec.M_H2 * ec.LHV_H2 / 3600 * 1000 / ec.η_EC
outputEnergy(ec::ElectrolyticCell) = [ec.capacity for _ in 1:8760]


"""
返回氢气压缩机的年耗电量
"""
outputEnergy(hc::HydrogenCompressor) = hc.load * hc.comsumption
"""
返回煤电机组的最低出力
"""
outputEnergy(cp::CoalPower) = cp.capacity * cp.load_min

"""
返回气电机组的最低出力
"""
outputEnergy(gp::GasPower) = gp.capacity * gp.load_min

"""
返回储能的充放电量列表

- `es` 储能设备
- `ΔE` 风光电量与负荷需求的差值
"""
function outputEnergy(es::EnergyStorage, ΔE::Vector)
    to_es, es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    es_limit = es.capacity * es.charging_limit # 储能最大容量
    for i in 1:length(ΔE)-1
        if ΔE[i] > 0 # 风光盈余电量, 储能充电
            to_es[i] = ΔE[i] > es_limit - es_power[i] ? es_limit - es_power[i] : ΔE[i]
        elseif ΔE[i] < 0 # 风光缺电量, 储能放电
            to_es[i] = ΔE[i] < -es_power[i] ? -es_power[i] : ΔE[i]
        end
        es_power[i+1] = es_power[i] + to_es[i]
    end
    return to_es, es_power
end

"""
返回煤电与气电在最小负荷基础上增加的出力与储能的充放电列表，煤电优先

- `cp` 煤电
- `gp` 气电
- `es` 储能
- `ΔE` 风光电量与负荷需求的差值
"""
function outputEnergy(cp::CoalPower, gp::GasPower, es::EnergyStorage, ΔE::Vector)
    cp_power, gp_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    to_es, es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    es_limit = es.capacity * es.charging_limit # 储能最大容量
    limits = (
        cp.capacity * cp.load_max - cp.capacity * cp.load_min,
        cp.capacity * cp.load_max - cp.capacity * cp.load_min + gp.capacity * gp.load_max - gp.capacity * gp.load_min
    )
    for i in 1:length(ΔE)-1
        if ΔE[i] < 0 # 风光缺电量, 储能放电
            to_es[i] = ΔE[i] < -es_power[i] ? -es_power[i] : ΔE[i]
            ΔE_left = -ΔE[i] + to_es[i]
            if ΔE_left < limits[1]
                cp_power[i], gp_power[i] = ΔE_left, 0
            elseif ΔE_left <= limits[2]
                cp_power[i], gp_power[i] = limits[1], ΔE_left - limits[1]
            else
                cp_power[i], gp_power[i] = limits[1], limits[2] - limits[1]
            end
        elseif ΔE[i] > 0 # 风光盈余电量, 储能充电
            to_es[i] = ΔE[i] > es_limit - es_power[i] ? es_limit - es_power[i] : ΔE[i]
        end
        es_power[i+1] = es_power[i] + to_es[i]
    end
    return cp_power, gp_power, to_es, es_power
end

"""
返回煤电与气电在最小负荷基础上增加的出力与储能的充放电列表，气电优先

- `cp` 煤电
- `gp` 气电
- `es` 储能
- `ΔE` 风光电量与负荷需求的差值

return 煤电出力, 气电出力, 储能充放电, 储能储电量
"""
function outputEnergy(gp::GasPower, cp::CoalPower, es::EnergyStorage, ΔE::Vector)
    cp_power, gp_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    to_es, es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    es_limit = es.capacity * es.charging_limit # 储能最大容量
    limits = (
        gp.capacity * gp.load_max - gp.capacity * gp.load_min,
        cp.capacity * cp.load_max - cp.capacity * cp.load_min + gp.capacity * gp.load_max - gp.capacity * gp.load_min
    )
    for i in 1:length(ΔE)-1
        if ΔE[i] < 0 # 风光缺电量, 储能放电
            to_es[i] = ΔE[i] < -es_power[i] ? -es_power[i] : ΔE[i]
            ΔE_left = -ΔE[i] + to_es[i]
            if ΔE_left < limits[1]
                gp_power[i], cp_power[i] = ΔE_left, 0
            elseif ΔE_left <= limits[2]
                gp_power[i], cp_power[i] = limits[1], ΔE_left - limits[1]
            else
                gp_power[i], cp_power[i] = limits[1], limits[2] - limits[1]
            end
        elseif ΔE[i] > 0 # 风光盈余电量, 储能充电
            to_es[i] = ΔE[i] > es_limit - es_power[i] ? es_limit - es_power[i] : ΔE[i]
        end
        es_power[i+1] = es_power[i] + to_es[i]
    end
    return cp_power, gp_power, to_es, es_power
end

"""
返回煤电、气电在最小负荷基础上增加的出力数组与储能、储氢功率的充放电数值。气电优先

- `cp` 煤电
- `gp` 气电
- `es` 储能
- `ec` 电解槽
- `ΔE` 风光电量与负荷需求的差值

return 煤电出力增加量, 气电出力增加量, 储能充放电, 储能储电量, 电解槽功率
"""
function outputEnergy(gp::GasPower, cp::CoalPower, es::EnergyStorage, ec::ElectrolyticCell, coefficient_H2::Float64, ΔE::Vector)
    cp_power, gp_power, to_es, ec_power, es_power = (zeros(Float64, length(ΔE)) for _ in 1:5)
    es_limit = es.capacity * es.charging_limit # 储能最大容量
    ec_limit = ec.capacity * coefficient_H2  # 电解槽最大容量
    limits = (
        gp.capacity * gp.load_max - gp.capacity * gp.load_min,
        cp.capacity * cp.load_max - cp.capacity * cp.load_min + gp.capacity * gp.load_max - gp.capacity * gp.load_min
    )
    for i in 1:length(ΔE)-1
        if ΔE[i] < 0 # 风光缺电量, 储能放电
            to_es[i] = ΔE[i] < -es_power[i] ? -es_power[i] : ΔE[i]
            ΔE_left = -ΔE[i] + to_es[i]
            if ΔE_left < limits[1]
                gp_power[i], cp_power[i] = ΔE_left, 0
            elseif ΔE_left <= limits[2]
                gp_power[i], cp_power[i] = limits[1], ΔE_left - limits[1]
            else
                gp_power[i], cp_power[i] = limits[1], limits[2] - limits[1]
            end
        elseif ΔE[i] > 0 # 风光过剩, 先制氢，盈余再储能充电
            ec_power[i] = ΔE[i] > ec_limit ? ec_limit : ΔE[i]
            ΔE_left = ΔE[i] - ec_power[i]
            to_es[i] = ΔE_left > es_limit - es_power[i] ? es_limit - es_power[i] : ΔE_left
        end
        es_power[i+1] = es_power[i] + to_es[i]
    end
    return cp_power, gp_power, to_es, es_power, ec_power
end

"""
返回煤电、气电在最小负荷基础上增加的出力数组与储能、储氢功率的充放电数值。煤电优先

- `cp` 煤电
- `gp` 气电
- `es` 储能
- `ec` 电解槽
- `coefficient_H2` 电解槽产氢耗电系数，系数中包含制氢与输氢的电能消耗
- `ΔE` 风光电量与负荷需求的差值

return 煤电出力增加量, 气电出力增加量, 储能充放电, 储能储电量, 电解槽功率
"""
function outputEnergy(cp::CoalPower, gp::GasPower, es::EnergyStorage, ec::ElectrolyticCell, coefficient_H2::Float64, ΔE::Vector)
    cp_power, gp_power, to_es, ec_power, es_power = (zeros(Float64, length(ΔE)) for _ in 1:5)
    es_limit = es.capacity * es.charging_limit # 储能最大容量
    ec_limit = ec.capacity * coefficient_H2  # 电解槽最大容量
    limits = (
        cp.capacity * cp.load_max - cp.capacity * cp.load_min,
        cp.capacity * cp.load_max - cp.capacity * cp.load_min + gp.capacity * gp.load_max - gp.capacity * gp.load_min
    )
    for i in 1:length(ΔE)-1
        if ΔE[i] < 0 # 风光缺电量, 储能放电
            to_es[i] = ΔE[i] < -es_power[i] ? -es_power[i] : ΔE[i]
            ΔE_left = -ΔE[i] + to_es[i]
            if ΔE_left < limits[1]
                cp_power[i], gp_power[i] = ΔE_left, 0
            elseif ΔE_left <= limits[2]
                cp_power[i], gp_power[i] = limits[1], ΔE_left - limits[1]
            else
                cp_power[i], gp_power[i] = limits[1], limits[2] - limits[1]
            end
        elseif ΔE[i] > 0 # 风光过剩, 先制氢(制氢耗电包含了制氢与储氢)，盈余再储能充电
            ec_power[i] = ΔE[i] > ec_limit ? ec_limit : ΔE[i]
            ΔE_left = ΔE[i] - ec_power[i]
            to_es[i] = ΔE_left > es_limit - es_power[i] ? es_limit - es_power[i] : ΔE_left
        end
        es_power[i+1] = es_power[i] + to_es[i]
    end
    return cp_power, gp_power, to_es, es_power, ec_power
end


"""
返回电解槽用电产生的氢气量

- `power` 电解槽用电量
- `ec` 电解槽
- `coefficient_H2` 电解槽产氢耗电系数，系数中包含制氢与输氢的电能消耗，若只考虑制氢，则系数为1。若power包含了储氢电耗，则系数为大于1。
"""
outputH2Mass(power::Vector, ec::ElectrolyticCell, coefficient_H2::Float64) = @. power / coefficient_H2 * ec.Δt * ec.M_H2 / ec.LHV_H2 * 3.6 * ec.η_EC

outputH2Mass(power::Real, ec::ElectrolyticCell, coefficient_H2::Float64) = power / coefficient_H2 * ec.Δt * ec.M_H2 / ec.LHV_H2 * 3.6 * ec.η_EC

"""
返回设备的初始投资
"""
initialInvestment(machine::RenewableEnergyMachine) = machine.cost_initial * machine.capacity

"""
返回设备的年运维成本
"""
annualOperationCost(machine::RenewableEnergyMachine) = machine.cost_OM * machine.capacity

"""
返回设备的更换成本

- `machine` 设备
- `fin` 财务参数
"""
replacementCost(machine::RenewableEnergyMachine, fin::Financial) = fin.n_sys > machine.life_year ? machine.cost_replace * machine.capacity * ceil(fin.n_sys / machine.life_year) : 0

"""
返回设备的总成本

- `machine` 设备
- `fin` 财务参数
"""
totalCost(machine::RenewableEnergyMachine, fin::Financial) = initialInvestment(machine) + operationCost(machine, fin) + replacementCost(machine, fin)

"""
返回设备的年发电收益

- `capacity` 设备容量
- `fin` 财务参数
"""
sellElectricityProfit(capacity, fin::Financial) = fin.price_to_grid * abs(capacity)

"""
返回买电成本

- `capacity` 买电量
- `fin` 财务参数
"""
buyElectricityCost(capacity, fin::Financial) = fin.price_from_grid * abs(capacity)


"""
返回氢气销售收益

- `capacity` 卖氢量
- `fin` 财务参数
"""
sellH2Profit(capacity, fin::Financial) = fin.H2price_sale * capacity


"""
返回年用水成本

- `capacity` 水量
- `fin` 财务参数
"""
costWater(capacity, fin::Financial) = fin.cost_water_per_kg_H2 * capacity

"""
返回年用煤成本

- `capacity` 煤电发电量
- `cp` 煤电参数
- `fin` 财务参数
"""
costCoal(capacity, cp::CoalPower, fin::Financial) = capacity * 3.6 / (cp.η * cp.lhv_coal) * fin.price_coal_per_kg

"""
返回年用气成本

- `capacity` 气电发电量
- `gp` 气电参数
- `fin` 财务参数
"""
costGas(capacity, gp::GasPower, fin::Financial) = capacity * 3.6 / (gp.η * gp.lhv_gas) * fin.price_gas_per_Nm3

"""
返回设备的资金回收系数
"""
crf(fin::Financial) = (fin.r * (1 + fin.r)^fin.n_sys) / ((1 + fin.r)^fin.n_sys - 1)

"""
返回设备的财务评价指标。

# 参数
- `cost_initial`：初始投资，包括置换成本
- `year_profit`：年盈利收入
- `operation_life`：运营期限
- `rate_depreciation`：折旧率
- `rate_discount`：贴现率
- `rate_tax`：税率

# 返回值
- `NPV`：净现值
- `IRR`：内部收益率
- `payback`：投资回收期
"""
function financial_evaluation(cost_initial, year_profit, operation_life;
    rate_depreciation=0.05, rate_discount=0.06, rate_tax=0.25)

    # operation_life = Int(operation_life)
    # construction_life = Int(construction_life)
    # annual_investment_cost = vcat(cost_initial / construction_life .* ones(construction_life), zeros(operation_life))
    # annual_revenue = vcat(zeros(construction_life), year_profit .* ones(operation_life))
    # annual_operating_cost = vcat(zeros(construction_life), (year_cost_oper + year_cost_main) .* ones(operation_life))
    # depreciation = vcat(zeros(construction_life), cost_initial * rate_depreciation .* ones(operation_life)) # 折旧
    # cashflows = @. (annual_revenue - depreciation - annual_operating_cost) * (1 - rate_tax) - annual_investment_cost
    # cashflows = @. (annual_revenue - annual_operating_cost) * (1 - rate_tax) - annual_investment_cost

    cashflows = append!([-cost_initial], (year_profit * (1 - rate_tax) for _ in 1:Int(operation_life)))
    # println(cashflows)
    times = collect(0:length(cashflows)-1)
    NPV = present_value(rate_discount, cashflows, times)
    IRR = irr(cashflows)
    payback = breakeven(rate_discount, cashflows, times)
    IRR = isnothing(IRR) ? -1 : rate(IRR)
    payback = isnothing(payback) ? -1 : payback
    return NPV, IRR, payback
end

"""
计算满足年度现金流收益的售电价格

# 参数
- `cost_initial`：初始投资，包括置换成本
- `year_cost`：年成本（运营+燃料）
- `sum_load_power`：卖电量
- `operation_life`：运营期限
- `rate_depreciation`：折旧率
- `rate_discount`：贴现率
- `rate_tax`：税率

# 返回值
- `sell_price`：符合正收益要求的卖电电价
"""
function find_price(cost_initial, year_cost, sum_load_power, operation_life;
    rate_depreciation=0.05, rate_discount=0.06, rate_tax=0.25)
    
    sell_price = 0.1
    cashflows = append!([-cost_initial], ((sum_load_power * sell_price - year_cost) * (1 - rate_tax) for _ in 1:Int(operation_life)))
    IRR = irr(cashflows)
    

    while isnothing(IRR) || rate(IRR) < rate_discount
        sell_price += 0.01
        cashflows = append!([-cost_initial], ((sum_load_power * sell_price - year_cost) * (1 - rate_tax) for _ in 1:Int(operation_life)))
        IRR = irr(cashflows)
    end

    return sell_price
end


"""
读取前端数据，生成设备数据结构体
"""
function generateData(paras, N)
    if N <= 3
        wt = WindTurbine(
            input_v=S1_DATA_WS,
            capacity=paras["风电参数"]["装机容量（千瓦）"],
            unit_capacity=paras["风电参数"]["单位设备容量（kW）"],
            η_inverter=paras["风电参数"]["综合效率"],
            life_year=paras["风电参数"]["产品寿命（年）"],
            cost_initial=paras["风电参数"]["投资成本（￥/kW）"],
            cost_OM=paras["风电参数"]["运维成本（￥/kW）"],
            cost_replace=paras["风电参数"]["替换成本（￥/kW）"]
        )
        pv = PhotovoltaicCell(
            input_GI=S1_DATA_GI, input_Ta=S1_DATA_TA, input_v=S1_DATA_WS,
            capacity=paras["光伏参数"]["装机容量（千瓦）"],
            unit_capacity=paras["光伏参数"]["单位设备容量（kW）"],
            η_inverter=paras["光伏参数"]["综合效率"],
            life_year=paras["光伏参数"]["产品寿命（年）"],
            cost_initial=paras["光伏参数"]["投资成本（￥/kW）"],
            cost_OM=paras["光伏参数"]["运维成本（￥/kW）"],
            cost_replace=paras["光伏参数"]["替换成本（￥/kW）"]
        )
        ec = ElectrolyticCell(
            load=S1_DATA_LOAD,
            capacity=paras["电解槽参数"]["装机容量（千瓦）"],
            unit_capacity=paras["电解槽参数"]["单位设备容量（kW）"],
            η_inverter=paras["电解槽参数"]["综合效率"],
            life_year=paras["电解槽参数"]["产品寿命（年）"],
            cost_initial=paras["电解槽参数"]["投资成本（￥/kW）"],
            cost_OM=paras["电解槽参数"]["运维成本（￥/kW）"],
            cost_replace=paras["电解槽参数"]["替换成本（￥/kW）"]
        )
        hc = HydrogenCompressor(
            load=S1_DATA_LOAD,
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
        cp = Nothing()
        gp = Nothing()
        fin = Financial(
            n_sys=paras["经济性参数"]["系统运营年限（年）"],
            rate_discount=paras["经济性参数"]["目标收益率"],
            rate_tax=paras["经济性参数"]["综合税率"],
            rate_depreciation=paras["经济性参数"]["折旧率"],
            cost_water_per_kg_H2=paras["经济性参数"]["电解水成本（￥/kg）"],
            price_from_grid=paras["经济性参数"]["买电电价（￥/kwh）"],
            price_to_grid=paras["经济性参数"]["卖电电价（￥/kwh）"],
            H2price_sale=paras["经济性参数"]["氢气售卖价格（￥/kg）"]
        )
    elseif N <= 7
        wt = WindTurbine(
            input_v=S2_DATA_WS,
            capacity=paras["风电参数"]["装机容量（千瓦）"],
            unit_capacity=paras["风电参数"]["单位设备容量（kW）"],
            η_inverter=paras["风电参数"]["综合效率"],
            life_year=paras["风电参数"]["产品寿命（年）"],
            cost_initial=paras["风电参数"]["投资成本（￥/kW）"],
            cost_OM=paras["风电参数"]["运维成本（￥/kW）"],
            cost_replace=paras["风电参数"]["替换成本（￥/kW）"]
        )
        pv = PhotovoltaicCell(
            input_GI=S2_DATA_GI, input_Ta=S2_DATA_TA, input_v=S2_DATA_WS,
            capacity=paras["光伏参数"]["装机容量（千瓦）"],
            unit_capacity=paras["光伏参数"]["单位设备容量（kW）"],
            η_inverter=paras["光伏参数"]["综合效率"],
            life_year=paras["光伏参数"]["产品寿命（年）"],
            cost_initial=paras["光伏参数"]["投资成本（￥/kW）"],
            cost_OM=paras["光伏参数"]["运维成本（￥/kW）"],
            cost_replace=paras["光伏参数"]["替换成本（￥/kW）"]
        )
        ec = Nothing()
        hc = Nothing()
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
            rate_tax=paras["经济性参数"]["综合税率"],
            rate_depreciation=paras["经济性参数"]["折旧率"],
            price_coal_per_kg=paras["经济性参数"]["煤价格（￥/kg）"],
            price_to_grid=paras["经济性参数"]["卖电电价（￥/kwh）"],
            price_gas_per_Nm3=paras["经济性参数"]["燃气价格（￥/Nm3）"],
            gas_factor=paras["经济性参数"]["气电碳排放因子（kg/kWh）"],
            coal_factor=paras["经济性参数"]["煤电碳排放因子（kg/kWh）"],
        )
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
            rate_tax=paras["经济性参数"]["综合税率"],
            rate_depreciation=paras["经济性参数"]["折旧率"],
            price_coal_per_kg=paras["经济性参数"]["煤价格（￥/kg）"],
            price_to_grid=paras["经济性参数"]["卖电电价（￥/kwh）"],
            price_gas_per_Nm3=paras["经济性参数"]["燃气价格（￥/Nm3）"],
            gas_factor=paras["经济性参数"]["气电碳排放因子（kg/kWh）"],
            coal_factor=paras["经济性参数"]["煤电碳排放因子（kg/kWh）"],
        )
    end
    return (pv, wt, ec, hc, es, cp, gp), fin
end

"""
仿真接口函数，派发至具体情况的仿真函数
"""
function simulate!(paras, ::Val{N}) where {N}
    machines, fin = generateData(paras, N)
    return simulate!(machines, fin, Val(N))
end

"""
优化接口函数，派发至具体情况的优化函数
"""
function optimize!(paras, isopt::Vector, ::Val{N}) where {N}
    machines, fin = generateData(paras, N)
    return optimize!(machines, isopt, fin, Val(N))
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
"""
function generateChannelConstrainData(
    EL_data_24h_1=1e6 .* [3, 3, 3, 3, 3, 3, 3, 3, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 3, 3, 3, 3, 3, 3],
    EL_data_24h_2=1e6 .* [4, 4, 4, 4, 4, 4, 4, 5.6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 4, 4, 4, 4, 4]
)
    day_1 = (31 + 28 + 31) #1-3 month
    day_2 = day_1 + (30 + 31 + 30 + 31 + 31 + 30) #4-9 month
    day_3 = day_2 + (31 + 30 + 31) #10-12 month
    EL_data = []
    for i in 1:365
        if 1 <= i <= day_1
            append!(EL_data, EL_data_24h_1)
        elseif day_1 < i <= day_2
            append!(EL_data, EL_data_24h_2)
        else
            append!(EL_data, EL_data_24h_1)
        end
    end
    return EL_data
end