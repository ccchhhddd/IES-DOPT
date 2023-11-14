abstract type RenewableEnergyMachine end
"""
风力发电机

组件参数:
- `input_v`: 环境风速输入
- `capacity`: 总装机容量， kW
- `unit_capacity`: 单机容量， kW
- `machine_number`: 机组数量
- `Δt`: 采样时间， h
- `η_t`: 风轮传动效率
- `η_g`: 发电机效率
- `h1`: 风速切入速度， m/s
- `h2`: 风速切出速度， m/s
- `α`: 风速指数
- `η_inverter`: 综合效率，如考虑逆变器、电机效率等
- `life_year`: 使用年限，年
- `cost_initial`: 初始成本，元/kW
- `cost_OM`: 年运维成本，元/kW
- `cost_replace`: 更换成本，元/kW
- `k `: 风速-功率曲线

"""
Base.@kwdef mutable struct WindTurbine <: RenewableEnergyMachine
    input_v::Vector = Float64[]
    capacity::Float64 = 5e5
    unit_capacity::Float64 = 1.0
    machine_number::Int64 = 1
    Δt::Float64 = 1.0
    η_t::Float64 = 0.96
    η_g::Float64 = 0.93
    h1::Float64 = 10.0
    h2::Float64 = 135.0
    α::Float64 = 1.0 / 7.0
    η_inverter::Float64 = 1.0
    life_year::Float64 = 20.0
    cost_initial::Float64 = 4800.0
    cost_OM::Float64 = 720.0
    cost_replace::Float64 = 4800.0
    k::Function = k
end

k(v2) = ifelse(v2 < 3.0, 0.0,
    ifelse(3.0 <= v2 < 9.5, (-30.639 * v2^3 + 623.5 * v2^2 - 3130.4 * v2 + 4928) / 5000,
        ifelse(9.5 <= v2 < 19.5, 1.0,
            ifelse(19.5 <= v2 <= 25.0, (-203.97 * v2 + 9050.9) / 5000, 0.0))))

"""

光伏组件

组件参数:
- `input_GI`: 光照强度输入， Wh/m2
- `input_Ta`: 环境温度输入， ℃
- `input_v`: 风速输入， m/s
- `capacity`: 总装机容量， kW
- `unit_capacity`: 单机容量， kW
- `machine_number`: 机组数量
- `Δt`: 采样时间， h
- `A`: 光伏板面积， m2
- `f_PV`: 光伏板填充因子
- `η_PV_ref`: 光伏板额定转换效率
- `λ`: 光伏板温度系数
- `Tc_ref`: 光伏板额定温度， ℃
- `tau_alpha`: 光伏板吸收率
- `η_inverter`: 综合效率，如考虑逆变器、电机效率等
- `life_year`: 使用年限，年
- `cost_initial`: 初始成本，元/kW
- `cost_OM`: 年运维成本，元/kW
- `cost_replace`: 更换成本，元/kW

"""
Base.@kwdef mutable struct PhotovoltaicCell <: RenewableEnergyMachine
    input_GI::Vector = Float64[]
    input_Ta::Vector = Float64[]
    input_v::Vector = Float64[]
    capacity::Float64 = 5e5
    unit_capacity::Float64 = 1.0
    machine_number::Int64 = 1
    Δt::Float64 = 1.0
    A::Float64 = 3.1
    f_PV::Float64 = 0.8
    η_PV_ref::Float64 = 20.9 / 100
    λ::Float64 = -0.34 / 100
    Tc_ref::Float64 = 25.0
    tau_alpha::Float64 = 0.9
    η_inverter::Float64 = 1.0
    life_year::Float64 = 20.0
    cost_initial::Float64 = 3800.0
    cost_OM::Float64 = 190.0
    cost_replace::Float64 = 3800.0
end



# maximum(outputEnergy(WindTurbine(input_v=data_WS)))

"""

电解槽产氢组件

# Parameters:
- `load`: 负载功率， kg
- `capacity`: 电解槽额定功率， kW
- `Δt`: 采样时间， h
- `η_EC`: 电解槽效率
- `LHV_H2`: 氢燃料低位发热值， MJ/kg
- `M_H2`: 氢燃料摩尔质量， kg/mol
- `η_inverter`: 综合效率，如考虑逆变器、电机效率等
- `η_load_min`: 负载最小效率
- `life_year`: 使用年限，年
- `cost_initial`: 初始成本，元/kW
- `cost_OM`: 年运维成本，元/kW
- `cost_replace`: 更换成本，元/kW
"""
Base.@kwdef mutable struct ElectrolyticCell <: RenewableEnergyMachine
    load::Vector = Float64[]
    capacity::Float64 = 5e5
    unit_capacity::Float64 = 1.0
    machine_number::Int64 = 1
    Δt::Float64 = 1.0
    η_EC::Float64 = 0.6
    LHV_H2::Float64 = 241
    M_H2::Float64 = 2
    η_inverter::Float64 = 1.0
    η_load_min::Float64 = 0.0
    life_year::Float64 = 10.0
    cost_initial::Float64 = 2000.0
    cost_OM::Float64 = 100.0
    cost_replace::Float64 = 2000.0
end


"""

压缩储氢组件

# Parameters:
- `load`: 制氢负载， kg
- `capacity`: 储量， kg
- `consumption`: 单位耗电量， kWh/kg
- `life_year`: 使用年限，年
- `cost_initial`: 初始成本，元/kg
- `cost_OM`: 年运维成本，元/kg
- `cost_replace`: 更换成本，元/kg
"""
Base.@kwdef mutable struct HydrogenCompressor <: RenewableEnergyMachine
    load::Vector = Float64[]
    capacity::Float64 = 5e5
    unit_capacity::Float64 = 1.0
    machine_number::Int64 = 1
    comsumption::Float64 = 1.0
    life_year::Float64 = 20.0
    cost_initial::Float64 = 2300.0
    cost_OM::Float64 = 46
    cost_replace::Float64 = 2300.0
end

"""

储能组件

# Parameters:
- `capacity`: 电解槽额定功率， kW
- `unit_capacity`: 单机容量， kW
- `machine_number`: 机组数量
- `η_charging`: 充电效率
- `charging_limit`: 充电阈值限制
- `life_year`: 使用年限，年
- `cost_initial`: 初始成本，元/kW
- `cost_OM`: 年运维成本，元/kW
- `cost_replace`: 更换成本，元/kW

"""
Base.@kwdef mutable struct EnergyStorage <: RenewableEnergyMachine
    capacity::Float64 = 15000
    unit_capacity::Float64 = 650
    machine_number::Int64 = 1
    charging_limit::Float64 = 1.0
    η_charging::Float64 = 0.6
    life_year::Float64 = 20.0
    cost_initial::Float64 = 3800.0
    cost_OM::Float64 = 190.0
    cost_replace::Float64 = 3800.0
end

"""

气电组件

# Parameters:
- `capacity`: 气电机组定功率， kW
- `unit_capacity`: 单机容量， kW
- `machine_number`: 机组数量
- `η`: 发电效率
- `η_inverter`: 综合效率，如考虑逆变器、电机效率等
- `lhv_gas`: 天然气低位发热值， MJ/Nm³
- `load_min`: 负载最小效率
- `life_year`: 使用年限，年
- `cost_initial`: 初始成本，元/kW
- `cost_OM`: 年运维成本，元/kW
- `cost_replace`: 更换成本，元/kW

"""
Base.@kwdef mutable struct GasPower <: RenewableEnergyMachine
    capacity::Float64 = 15000
    unit_capacity::Float64 = 650
    machine_number::Int64 = 1
    load_max::Float64 = 1.0
    η::Float64 = 0.369
    η_inverter::Float64 = 1.0
    lhv_gas::Float64 = 34.94
    load_min::Float64 = 0.2
    life_year::Float64 = 20.0
    cost_initial::Float64 = 4800.0
    cost_OM::Float64 = 160.0
    cost_replace::Float64 = 4800.0
end

"""

煤电组件

# Parameters:
- `capacity`: 煤电机组额定功率， kW
- `unit_capacity`: 单机容量， kW
- `machine_number`: 机组数量
- `η`: 发电效率
- `η_inverter`: 综合效率，如考虑逆变器、电机效率等
- `lhv_coal`: 煤燃料低位发热量， MJ/kg
- `load_min`: 负载最小效率
- `life_year`: 使用年限，年
- `cost_initial`: 初始成本，元/kW
- `cost_OM`: 年运维成本，元/kW
- `cost_replace`: 更换成本，元/kW

"""
Base.@kwdef mutable struct CoalPower <: RenewableEnergyMachine
    capacity::Float64 = 15000
    unit_capacity::Float64 = 650
    machine_number::Int64 = 1
    load_max::Float64 = 0.9
    η::Float64 = 0.49
    η_inverter::Float64 = 1.0
    lhv_coal::Float64 = 29.307
    load_min::Float64 = 0.6
    life_year::Float64 = 20.0
    cost_initial::Float64 = 15200.0
    cost_OM::Float64 = 248.0
    cost_replace::Float64 = 15200.0
end


"""

经济型分析参数

# Parameters:
- `n_sys`: 系统设计寿命，年
- `r`: 实际利率
- `cost_water_per_kg_H2`: 氢气生产成本，元/kg
- `eprice_to_grid`: 上网电价，元/kWh
- `eprice_from_grid`: 购电电价，元/kWh
- `H2price_sale`: 氢气销售价格，元/kg
- `rate_depreciation`: 折旧率
- `rate_discount`: 目标收益率
- `rate_tax`: 综合税率
- `price_gas_per_Nm3`: 天然气价格，元/Nm³
- `price_coal_per_kg`: 煤炭价格，元/kg
"""
Base.@kwdef mutable struct Financial
    n_sys::Float64 = 20.0
    r::Float64 = 0.0355
    cost_water_per_kg_H2::Float64 = 0.021
    price_to_grid::Float64 = 0.2277
    price_from_grid::Float64 = 0.355
    H2price_sale::Float64 = 25.58
    rate_depreciation::Float64 = 0.0
    rate_discount::Float64 = 0.08
    rate_tax::Float64 = 0.0
    price_gas_per_Nm3::Float64 = 1.7
    price_coal_per_kg::Float64 = 0.5
    gas_factor::Float64 = 0.5
    coal_factor::Float64 = 1.0
end
