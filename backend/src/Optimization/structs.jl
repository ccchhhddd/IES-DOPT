#能源设备类型
abstract type EnergyEquipment end

"""
- 1号组件:风力发电

- `input_v`: 环境风速输入
- `unit_capacity`: 单机容量, kW
- `machine_number`: 机组数量
- `capacity`: 总装机容量, kW
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
    unit_capacity::Float64 = 1500.0
    machine_number::Int64 = 2500
    capacity::Float64 = unit_capacity * machine_number
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
- `unit_capacity`: 单机容量, kW
- `machine_number`: 机组数量
- `capacity`: 总装机容量, kW
- `A`: 光伏板面积, m2
- `actual_T`: 光伏板实际温度,℃
- `λ`: 光伏板温度系数
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kW
- `cost_OM`: 年运维成本,元/kW
- `cost_replace`: 更换成本,元/kW

"""
Base.@kwdef mutable struct Photovoltaic <: EnergyEquipment
    input_GI::Vector = Float64[]
    input_Ta::Vector = Float64[]
    unit_capacity::Float64 = 3.5
    machine_number::Int64 = 1e6
    capacity::Float64 = unit_capacity * machine_number
    A::Float64 = 3.1
    actual_T::Vector = Float64[]
    λ::Float64 = 0.0034
    life_year::Float64 = 20.0
    cost_initial::Float64 = 3800.0
    cost_OM::Float64 = 190.0
    cost_replace::Float64 = 3800.0

end


"""
- 3号组件:燃气轮机发电

- `unit_capacity`: 单机容量,kW
- `machine_number`: 机组数量
- `capacity`: 总装机容量,kW
- `load_min`: 最小出力效率 
- `load_change`: 出力调整系数
- `η`: 发电效率,
- `outputpower`:天然气燃烧速率, m³/h
- `lhv_gas`: 天然气低位发热值(单位质量的燃料在完全燃烧时所发出的热量), MJ/ Nm³
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kW
- `cost_OM`: 年运维成本,元/kW
- `cost_replace`: 更换成本,元/kW


"""
Base.@kwdef mutable struct GasTurbine <: EnergyEquipment
    unit_capacity::Float64 = 650
    machine_number::Int64 = 5000
    capacity::Float64 = unit_capacity * machine_number
    load_min::Float64 = 0.2
    load_change::Float64 = 0.05
    η::Float64 = 0.6
    outputpower::Vector = Float64[]
    lhv_gas::Float64 = 34.94
    life_year::Float64 = 20.0
    cost_initial::Float64 = 4800.0
    cost_OM::Float64 = 160.0
    cost_replace::Float64 = 4800.0

end

"""
- 4号组件:整流器

- `unit_capacity`:单机容量, kw
- `machine_number`: 机组数量
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
    unit_capacity::Float64 = 1500
    machine_number::Int64 = 10
    capacity::Float64 = unit_capacity * machine_number
    η_inverter::Float64 = 0.9
    P_input::Vector = Float64[]
    P_output::Vector = Float64[]
    life_year::Float64 = 20.0
    cost_initial::Float64 = 2300.0
    cost_OM::Float64 = 50
    cost_replace::Float64 = 2300.0
end


"""
- 5号组件:压缩空气储能

- `load`: 存储的电量 ,kwh
- `unit_capacity`: 单机容量, kW
- `machine_number`: 机组数量
- `capacity`: 装机额定功率, kW
- `η_charging`: 充电效率
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kW
- `cost_OM`: 年运维成本,元/kW
- `cost_replace`: 更换成本,元/kW
"""
Base.@kwdef mutable struct CompressAirEnergyStorage <: EnergyEquipment
    load::Vector= Float64[]
    unit_capacity::Float64 = 5000
    machine_number::Int64 = 30
    capacity::Float64 = unit_capacity * machine_number
    η_charging::Float64 = 0.6   
    life_year::Float64 = 15.0
    cost_initial::Float64 = 3800.0
    cost_OM::Float64 = 190.0
    cost_replace::Float64 = 3800.0
end

"""
- 6号组件:电解槽

- `load`: 负载功率(制出来多少氢气), kg
- `unit_capacity`: 单机容量, kW
- `machine_number`:机组数量
- `capacity`: 电解槽额定功率(装机容量), kW
- `LHV_H2`: 氢燃料低位发热值, MJ/kg
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kW
- `cost_OM`: 年运维成本,元/kW
- `cost_replace`: 更换成本,元/kW
"""
Base.@kwdef mutable struct Electrolyzer <: EnergyEquipment
    load::Vector = Float64[]
    unit_capacity::Float64 = 5000.0
    machine_number::Int64 = 100
    capacity::Float64 = unit_capacity * machine_number
    LHV_H2::Float64 = 241.0
    life_year::Float64 = 10.0
    cost_initial::Float64 = 2000.0
    cost_OM::Float64 = 100.0
    cost_replace::Float64 = 2000.0
end


"""
- 7号组件:氢气压缩机

- `unit_capacity`:单机容量,kg
- `machine_number`:机组数量 
- `capacity`: 装机容量, kg
- `consumption`: 单位耗电量, kWh/kg
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kg
- `cost_OM`: 年运维成本,元/kg
- `cost_replace`: 更换成本,元/kg
"""
Base.@kwdef mutable struct HydrogenCompressor <: EnergyEquipment
    unit_capacity::Float64 = 500 
    machine_number::Int64 = 100
    capacity::Float64 = unit_capacity * machine_number
    consumption::Float64 = 1.0
    life_year::Float64 = 20.0
    cost_initial::Float64 = 2300.0
    cost_OM::Float64 = 46
    cost_replace::Float64 = 2300.0
end 

"""
- 8号组件:储氢罐
- `unit_capacity`:单机容量,kg
- `machine_number`:机组数量 
- `capacity`: 装机容量, kg
- `load`: 容量 kg(相当于电解槽里的一个无限大的临时储罐，用来临时存储当前时刻的制氢量，但是这些量会在下一时刻经过氢气压缩机后才会到下一时刻的储氢罐里)
- `life_year`: 使用年限,年
- `cost_initial`: 初始成本,元/kg
- `cost_OM`: 年运维成本,元/kg
- `cost_replace`: 更换成本,元/kg
"""
Base.@kwdef mutable struct HydrogenStorage <: EnergyEquipment
    unit_capacity::Float64 = 5000
    machine_number::Int64 = 10
    capacity::Float64 = unit_capacity * machine_number
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
- `cost_unit_transport`:氢气单次运输费用,元/次
- `H2price_sale`: 氢气销售价格,元/kg
- `price_gas_per_Nm3`: 天然气价格,元/Nm³
- `investment`:最大投资金额,元
- `H2production`:目标最小制氢量,kg
- ``

"""
Base.@kwdef mutable struct Financial
    day::Float64 = 364
    n_sys::Float64 = day/365
    cost_water_per_kg_H2::Float64 = 0.021
    cost_unit_transport ::Float64 = 250000.0
    H2price_sale::Float64 = 25.58
    price_gas_per_Nm3::Float64 = 1.7
    investment::Float64 = 1.0e10
    H2production::Float64 = 1.0e8
end



"""
- 10号组件:优化参数

- `area`: 地区选择,1.榆林 2.若羌 3.冷湖 4.西海
- `select_obj`: 优化目标 1.最小单位氢气成本 2.氢气产能最大 3.总投资成本最低
- `select_slo`: 选择单优化算法【目前只有黑箱优化】

"""
Base.@kwdef mutable struct OptimizeParas
    select_obj::Int64 = 1
    select_slo::String = "separable_nes"
end
                            
# 在全局定义 slo_dict
global slo_dict = Dict(
    "separable_nes" => :separable_nes,
    "resampling_memetic_search" => :resampling_memetic_search,
    "generating_set_search" => :generating_set_search,
    "simultaneous_perturbation_stochastic_approximation" => :simultaneous_perturbation_stochastic_approximation,
    "adaptive_de_rand_1_bin" => :adaptive_de_rand_1_bin
    )

