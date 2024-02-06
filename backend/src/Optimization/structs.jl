#能源设备类型
abstract type EnergyEquipment end

"""
- 1号组件:风力发电

- `input_v`: 环境风速输入
- `capacity`: 总装机容量, kW
- `unit_capacity`: 单机容量, kW
- `machine_number`: 机组数量
- `Δt`: 采样时间, h
- `η_t`: 风轮传动效率
- `η_g`: 发电机效率
- `h1`: 风速切入速度, m/s
- `h2`: 风速切出速度, m/s
- `h3`: 截止风速速度, m/s
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kW
- `cost_OM`: 年运维成本,元/kW
- `cost_replace`: 更换成本,元/kW

"""
Base.@kwdef mutable struct WindTurbine <: EnergyEquipment
    input_v::Vector = Float64[]
    capacity::Float64 = 4e6
    unit_capacity::Float64 = 1.0
    machine_number::Int64 = 1
    Δt::Float64 = 1.0
    η_t::Float64 = 0.96
    η_g::Float64 = 0.93
    h1::Float64 = 10.0
    h2::Float64 = 135.0
    h3::Float64 = 150.0
    life_year::Float64 = 20.0
    cost_initial::Float64 = 4800.0
    cost_OM::Float64 = 720.0
    cost_replace::Float64 = 4800.0
end


"""
- 2号组件:光伏发电

- `input_GI`   : 光照强度输入, Wh/m2
- `input_Ta ` :环境温度输入,℃
- `capacity`: 总装机容量, kW
- `unit_capacity`: 单机容量, kW
- `machine_number`: 机组数量
- `Δt`: 采样时间, h
- `A`: 光伏板面积, m2
- `actual_T`: 光伏板实际温度,℃
- `tau_alpha`: 光伏板吸收率
- `λ`: 光伏板温度系数(0.0034)
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kW
- `cost_OM`: 年运维成本,元/kW
- `cost_replace`: 更换成本,元/kW

"""
Base.@kwdef mutable struct Photovoltaic <: EnergyEquipment
    input_GI::Vector = Float64[]
    input_Ta::Vector = Float64[]
    capacity::Float64 = 1e7
    unit_capacity::Float64 = 1.0
    machine_number::Int64 = 1
    Δt::Float64 = 1.0
    A::Float64 = 3.1
    actual_T::Vector = Float64[]
    tau_alpha::Float64 = 0.9
    λ::Float64 = 0.34 / 100
    life_year::Float64 = 20.0
    cost_initial::Float64 = 3800.0
    cost_OM::Float64 = 190.0
    cost_replace::Float64 = 3800.0

end


"""
- 3号组件:燃气轮机发电

- `capacity`: 总装机容量,kW
- `unit_capacity`: 单机容量,kW
- `machine_number`: 机组数量
- `load_min`: 最小出力效率 
- `load_change`: 出力调整系数
- `Δt`: 采样时间, h
- `η`: 发电效率,
- `Fuel_rate`:天然气燃烧速率, m³/h
- `lhv_gas`: 天然气低位发热值(单位质量的燃料在完全燃烧时所发出的热量), MJ/ Nm³
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kW
- `cost_OM`: 年运维成本,元/kW
- `cost_replace`: 更换成本,元/kW


"""
Base.@kwdef mutable struct GasTurbine <: EnergyEquipment
    capacity::Float64 = 4e6
    unit_capacity::Float64 = 650
    machine_number::Int64 = 1
    load_min::Float64 = 0.2
    load_change::Float64 = 0.05
    Δt::Float64 = 1.0
    η::Float64 = 0.6
    Fuel_rate::Vector = Float64[]
    lhv_gas::Float64 = 34.94
    life_year::Float64 = 20.0
    cost_initial::Float64 = 4800.0
    cost_OM::Float64 = 160.0
    cost_replace::Float64 = 4800.0

end

"""
- 4号组件:整流器
- `capacity`: 装机额定功率, kW
- `η_inverter`:整流器综合效率
- `P_input`:输入功率 ,kW 
- `P_output`:输出功率 ,kW 
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kg
- `cost_OM`: 年运维成本,元/kg
- `cost_replace`: 更换成本,元/kg
"""
Base.@kwdef mutable struct Inverter <: EnergyEquipment
    capacity::Float64 = 15000
    η_inverter::Float64 = 0.9
    P_input::Vector = Float64[]
    P_output::Vector = Float64[]
    life_year::Float64 = 20.0
    cost_initial::Float64 = 2300.0
    cost_OM::Float64 = 46
    cost_replace::Float64 = 2300.0
end


"""
- 5号组件:压缩空气储能

- `capacity`: 装机额定功率, kW
- `load`: 存储的电量 ,kwh
- `unit_capacity`: 单机容量, kW
- `machine_number`: 机组数量
- `η_charging`: 充电效率
- `charging_limit`: 充电阈值限制
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kW
- `cost_OM`: 年运维成本,元/kW
- `cost_replace`: 更换成本,元/kW
"""
Base.@kwdef mutable struct CompressAirEnergyStorage <: EnergyEquipment
    capacity::Float64 = 15000
    load::Vector= Float64[]
    unit_capacity::Float64 = 650
    machine_number::Int64 = 1
    η_charging::Float64 = 0.6
    charging_limit::Float64 = 1.0   
    life_year::Float64 = 15.0
    cost_initial::Float64 = 3800.0
    cost_OM::Float64 = 190.0
    cost_replace::Float64 = 3800.0
end

"""
- 6号组件:电解槽

- `load`: 负载功率(制出来多少氢气), kg
- `capacity`: 电解槽额定功率(装机容量), kW
- `unit_capacity`: 单机容量, kW
- 'machine_number':机组数量
- `Δt`: 采样时间, h
- `LHV_H2`: 氢燃料低位发热值, MJ/kg
- `η_load_min`: 负载最小效率
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kW
- `cost_OM`: 年运维成本,元/kW
- `cost_replace`: 更换成本,元/kW
"""
Base.@kwdef mutable struct Electrolyzer <: EnergyEquipment
    load::Vector = Float64[]
    capacity::Float64 = 5e5
    unit_capacity::Float64 = 1.0
    machine_number::Int64 = 1
    Δt::Float64 = 1.0
    LHV_H2::Float64 = 241
    η_load_min::Float64 = 0.0
    life_year::Float64 = 10.0
    cost_initial::Float64 = 2000.0
    cost_OM::Float64 = 100.0
    cost_replace::Float64 = 2000.0
end

"""
- 7号组件:氢气压缩机
- `capacity`: 装机容量, kg
- `machine_number`:机组数量 
- `consumption`: 单位耗电量, kWh/kg
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kg
- `cost_OM`: 年运维成本,元/kg
- `cost_replace`: 更换成本,元/kg
"""
Base.@kwdef mutable struct HydrogenCompressor <: EnergyEquipment
    capacity::Float64 = 5e5    
    machine_number::Int64 = 1
    consumption::Float64 = 1.0
    life_year::Float64 = 20.0
    cost_initial::Float64 = 2300.0
    cost_OM::Float64 = 46
    cost_replace::Float64 = 2300.0
end 

"""
- 8号组件:储氢罐
- `capacity`: 装机容量, kg
- `load`: 容量 kg
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kg
- `cost_OM`: 年运维成本,元/kg
- `cost_replace`: 更换成本,元/kg
"""
Base.@kwdef mutable struct HydrogenStorage <: EnergyEquipment
    capacity::Float64 = 5e5
    load::Vector = Float64[]
    life_year::Float64 = 20.0
    cost_initial::Float64 = 2300.0
    cost_OM::Float64 = 46
    cost_replace::Float64 = 2300.0
end


# """
# - 9号组件:燃料电池

# - `capacity`: 气电机组定功率， kW
# - `unit_capacity`: 单机容量， kW
# - `machine_number`: 机组数量
# - `η`: 发电效率
# - `lhv_gas`: 氢气低位发热值(单位质量的燃料在完全燃烧时所发出的热量), MJ/Nm³
# - `life_year`: 使用年限，年
# - `cost_initial`: 初始成本，元/kW
# - `cost_OM`: 年运维成本，元/kW
# - `cost_replace`: 更换成本，元/kW
# """
# Base.@kwdef mutable struct FuelCell <: EnergyEquipment
#     capacity::Float64 = 4e6
#     unit_capacity::Float64 = 650
#     machine_number::Int64 = 1
#     η::Float64 = 0.6
#     lhv_gas::Float64 = 34.94
#     life_year::Float64 = 20.0
#     cost_initial::Float64 = 4800.0
#     cost_OM::Float64 = 160.0
#     cost_replace::Float64 = 4800.0
# end


"""
- 9号组件:经济性分析

- `day`: 运行天数
- `n_sys`: 系统设计寿命,年
- `cost_water_per_kg_H2`: 氢气生产用水成本,元/kg
- `H2price_sale`: 氢气销售价格,元/kg
- `price_gas_per_Nm3`: 天然气价格,元/Nm³

"""
Base.@kwdef mutable struct Financial
    day::Float64 = 700
    n_sys::Float64 = 20.0
    cost_water_per_kg_H2::Float64 = 0.021
    H2price_sale::Float64 = 25.58
    price_gas_per_Nm3::Float64 = 1.7
end