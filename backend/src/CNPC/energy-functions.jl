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
outputEnergy(ec::ElectrolyticCell) = @. ec.load / ec.Δt / ec.M_H2 * ec.LHV_H2 / 3600 * 1000 / ec.η_EC 
# outputEnergy(ec::ElectrolyticCell) = [ec.capacity for _ in 1:8760]

outputEnergy(ec::ElectrolyticCell, load::Float64) = load / ec.Δt / ec.M_H2 * ec.LHV_H2 / 3600 * 1000 / ec.η_EC

"""
返回氢气压缩机的日耗电量
"""
outputEnergy(hc::HydrogenCompressor) = hc.load * hc.comsumption

outputEnergy(hc::HydrogenCompressor, load::Float64) = load * hc.comsumption
"""
返回煤电机组的最低出力，自耗电量百分之一
"""
outputEnergy(cp::CoalPower) = cp.capacity * cp.load_min

"""
返回气电机组的最低出力
"""
outputEnergy(gp::GasPower) = gp.capacity * gp.load_min

# """
# 返回储能的充放电量列表

# - `es` 储能设备
# - `ΔE` 风光电量与负荷需求的差值
# """
# function outputEnergy(es::EnergyStorage, ΔE::Vector)
#     to_es, es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
#     es_limit = es.capacity * es.charging_limit # 储能最大容量
#     for i in 1:length(ΔE)-1
#         if ΔE[i] > 0 # 风光盈余电量, 储能充电
#             to_es[i] = ΔE[i] > es_limit - es_power[i] ? es_limit - es_power[i] : ΔE[i]
#         elseif ΔE[i] < 0 # 风光网汇量, 储能放电
#             to_es[i] = ΔE[i] < -es_power[i] ? -es_power[i] : ΔE[i]
#         end
#         es_power[i+1] = es_power[i] + to_es[i]
#     end
#     return to_es, es_power
# end

"""
返回储能的充放电量列表
储能优先级：电化学储能 > 压缩空气储能

- `e_es` 电化学储能设备
- `ca_es` 压缩空气储能设备
- `ΔE` 风光电量与负荷需求的差值
"""
function outputEnergy(e_es::ElectrochemicalEnergyStorage, ca_es::CompressAirEnergyStorage, ΔE::Vector)
    to_es, es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    to_e_es, e_es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    to_ca_es, ca_es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))

    #两种储能方式最大容量值
    e_es_limit = e_es.capacity * e_es.charging_limit # 电化学储能最大容量
    ca_es_limit = ca_es.capacity * ca_es.charging_limit # 压缩空气储能最大容量

    for i in 1:length(ΔE)-1

        range1 = e_es_limit - e_es_power[i]
        range2 = e_es_limit - e_es_power[i] + ca_es_limit - ca_es_power[i]

        if ΔE[i] > 0 # 风光盈余电量, 储能充电
            if ΔE[i] <= range1
                to_e_es[i], to_ca_es[i] = ΔE[i], 0
            elseif  ΔE[i] <= range2
                to_e_es[i], to_ca_es[i] = range1, ΔE[i] - range1
            else
                to_e_es[i], to_ca_es[i] = range1, range2 - range1
            end
        elseif ΔE[i] < 0 # 风光网汇量, 储能放电
            if ΔE[i] >= -e_es_power[i]
                to_e_es[i], to_ca_es[i] = ΔE[i], 0
            elseif -e_es_power[i] - ca_es_power[i] <= ΔE[i] < -e_es_power[i]
                to_e_es[i], to_ca_es[i] = -e_es_power[i], ΔE[i] + e_es_power[i]
            else
                to_e_es[i], to_ca_es[i] = -e_es_power[i], -ca_es_power[i]
            end
        end
        to_es[i] = to_e_es[i] + to_ca_es[i] # 储能充电量
        e_es_power[i+1] = e_es_power[i] + to_e_es[i] # 电化学储能量
        ca_es_power[i+1] = ca_es_power[i] + to_ca_es[i] # 压缩空气储能量
        es_power[i+1] = e_es_power[i+1] + ca_es_power[i+1] # 储能总量
    end
    return to_es, to_e_es, to_ca_es, es_power, e_es_power, ca_es_power
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
        if ΔE[i] < 0 # 风光网汇量, 储能放电
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
返回煤电与气电在最小负荷基础上增加的出力与储能的充放电列表，气电优先， 
储能优先级：抽水蓄能>压缩空气储能>电化学储能

- `cp` 煤电
- `gp` 气电
- `to_es` 总储能
- `to_p_es`  抽水蓄能
- `to_ca_es` 压缩空气储能
- `to_e_es` 电化学储能
- `ΔE` 风光电量与负荷需求的差值

return 煤电出力, 气电出力, 总储能充放电,  总储能储电量， 三种储能方式分别充放电， 三种储能方式分别储电量
"""
function outputEnergy(gp::GasPower, cp::CoalPower, p_es::PumpedStorage, ca_es::CompressAirEnergyStorage, e_es::ElectrochemicalEnergyStorage, ΔE::Vector)
    cp_power, gp_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    to_es, es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    to_p_es, p_es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    to_ca_es, ca_es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    to_e_es, e_es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    #三种储能方式最大容量值
    p_es_limit = p_es.capacity * p_es.charging_limit # 抽水储能最大容量
    ca_es_limit = ca_es.capacity * ca_es.charging_limit # 压缩空气储能最大容量
    e_es_limit = e_es.capacity * e_es.charging_limit # 电化学储能最大容量

    limits = (
        gp.capacity * gp.load_max - gp.capacity * gp.load_min,
        cp.capacity * cp.load_max - cp.capacity * cp.load_min + gp.capacity * gp.load_max - gp.capacity * gp.load_min
    )

    for i in 1:length(ΔE)-1

        range1 = p_es_limit - p_es_power[i]
        range2 = p_es_limit - p_es_power[i] + ca_es_limit - ca_es_power[i]
        range3 = p_es_limit - p_es_power[i] + ca_es_limit - ca_es_power[i] + e_es_limit - e_es_power[i]

        if ΔE[i] < 0 # 风光网汇量, 储能放电
            if ΔE[i] >= -p_es_power[i]
                to_p_es[i], to_ca_es[i], to_e_es[i] = ΔE[i], 0, 0
            elseif -p_es_power[i] - ca_es_power[i] <= ΔE[i] < -p_es_power[i]
                to_p_es[i], to_ca_es[i], to_e_es[i] = -p_es_power[i], ΔE[i] + p_es_power[i], 0
            elseif -p_es_power[i] - ca_es_power[i] - e_es_power[i] <= ΔE[i] < -p_es_power[i] - ca_es_power[i]
                to_p_es[i], to_ca_es[i], to_e_es[i] = -p_es_power[i], -ca_es_power[i], ΔE[i] + p_es_power[i] + ca_es_power[i]
            else
                to_p_es[i], to_ca_es[i], to_e_es[i] = -p_es_power[i], -ca_es_power[i], -e_es_power[i]
            end

            ΔE_left = -ΔE[i] + to_p_es[i] + to_ca_es[i] + to_e_es[i]

            if ΔE_left < limits[1]
                gp_power[i], cp_power[i] = ΔE_left, 0
            elseif ΔE_left <= limits[2]
                gp_power[i], cp_power[i] = limits[1], ΔE_left - limits[1]
            else
                gp_power[i], cp_power[i] = limits[1], limits[2] - limits[1]
            end

        elseif ΔE[i] > 0 # 风光盈余电量, 储能充电
            #计算三种储能方式充电量
            if ΔE[i] <= range1
                to_p_es[i], to_ca_es[i], to_e_es[i] = ΔE[i], 0, 0
                # elseif range2[i] >= ΔE[i] > range1[i]
            elseif ΔE[i] <= range2
                to_p_es[i], to_ca_es[i], to_e_es[i] = range1, ΔE[i] - range1, 0
                # elseif range3[i] >= ΔE[i] > range2[i]
            elseif ΔE[i] <= range3
                to_p_es[i], to_ca_es[i], to_e_es[i] = range1, range2 - range1, ΔE[i] - range2
            else
                to_p_es[i], to_ca_es[i], to_e_es[i] = range1, range2 - range1, range3 - range2
            end
        end
        to_es[i] = to_p_es[i] + to_ca_es[i] + to_e_es[i] #储能充电量
        p_es_power[i+1] = p_es_power[i] + to_p_es[i] # 抽水储能量
        ca_es_power[i+1] = ca_es_power[i] + to_ca_es[i] # 压缩空气储能量
        e_es_power[i+1] = e_es_power[i] + to_e_es[i] # 电化学储能量
        es_power[i+1] = p_es_power[i+1] + ca_es_power[i+1] + e_es_power[i+1] # 储能总量
    end
    return cp_power, gp_power, to_es, to_p_es, to_ca_es, to_e_es, es_power, p_es_power, ca_es_power, e_es_power
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
        if ΔE[i] < 0 # 风光网汇量, 储能放电
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
        if ΔE[i] < 0 # 风光网汇量, 储能放电
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
返回电解槽用电和压缩空气用电产生的氢气量

- `power` 电解槽和压缩机用电量
- `ec` 电解槽
- `hc` 压缩氢气组件
"""
outputH2Mass(power::Real, ec::ElectrolyticCell, hc::HydrogenCompressor) = power / (hc.comsumption + ec.LHV_H2 / ( ec.Δt * ec.M_H2 * ec.η_EC) * 1000 / 3600)

"""
返回压缩机和电解槽耗能、储氢罐的充放气列表、储能的充放电量列表、弃电量以及购电量
储能优先级：电化学储能 > 压缩空气储能
- `ec` 电解槽
- `hc` 压缩机
- `hs` 储氢罐
- `e_es` 电化学储能设备
- `ca_es` 压缩空气储能设备
- `ΔE` 风光电量与负荷需求的差值
"""

function outputEnergy(ec::ElectrolyticCell, hc::HydrogenCompressor, hs:: HydrogenStorage, e_es::ElectrochemicalEnergyStorage, ca_es::CompressAirEnergyStorage, ΔE::Vector)
    to_ec_power, to_hc_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE)) # 电解槽耗能，压缩机耗能
    to_hs, hs_mass = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE)) # 储氢罐充放气， 储氢罐存量，kg 
    to_es, es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    to_e_es, e_es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    to_ca_es, ca_es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    to_discard, ΔE_from_grid = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    # 储氢罐可储氢最大容量值
    hs_limit = hs.capacity * hs.charging_limit
    # 两种储能方式最大容量值
    e_es_limit = e_es.capacity * e_es.charging_limit # 电化学储能最大容量
    ca_es_limit = ca_es.capacity * ca_es.charging_limit # 压缩空气储能最大容量
    
    for i in 1:length(ΔE) -1

        range1 = e_es_limit - e_es_power[i]
        range2 = e_es_limit - e_es_power[i] + ca_es_limit - ca_es_power[i]

        if ΔE[i] > 0

            hs_max = hs_limit - hs_mass[i] # 储氢罐最大可充气量
            hs_power_max = outputEnergy(ec, hs_max) # 将储氢罐里的储氢量转化为电解槽耗能
            hc_power_max = outputEnergy(hc, hs_max) # 压缩机压缩储氢罐最大可充气量的耗能

            if ΔE[i] >= hs_power_max + hc_power_max # 风光多余电量大于压缩和储存储氢罐可最大充气量所消耗的电能，则需储能，储满放电
                # 压缩机耗能和储氢罐对应的耗能
                to_hs[i] = hs_max
                to_ec_power[i] = hs_power_max
                to_hc_power[i] = hc_power_max
                # 储能充电分配
                if ΔE[i] - (hs_power_max + hc_power_max) <= range1
                    to_e_es[i], to_ca_es[i] = ΔE[i] - (hs_power_max + hc_power_max), 0
                elseif  ΔE[i] - (hs_power_max + hc_power_max) <= range2
                    to_e_es[i], to_ca_es[i] = range1, ΔE[i] - (hs_power_max + hc_power_max) - range1
                else # 储满则弃
                    to_e_es[i], to_ca_es[i] = range1, range2 - range1
                end 
                to_discard[i] = ΔE[i] - (hs_power_max + hc_power_max) - to_e_es[i] - to_ca_es[i]
                ΔE_from_grid[i] = 0
            elseif ΔE[i] < hs_power_max + hc_power_max # 风光多余电量小于压缩和储存储氢罐可最大充气量所消耗的电能，无需储能，储氢罐充气
                # 压缩机耗能和储氢罐对应的耗能
                to_hs[i] = outputH2Mass(ΔE[i], ec, hc)
                to_ec_power[i] = outputEnergy(ec, to_hs[i])
                to_hc_power[i] = outputEnergy(hc, to_hs[i])
                # 储能分配
                to_e_es[i], to_ca_es[i] = 0, 0
                to_discard[i] = 0
                ΔE_from_grid[i] = 0
            end
        elseif  ΔE[i] < 0  # 优先储氢罐放气
            ΔH2 = outputH2Mass(-ΔE[i], ec, hc) # 缺少的氢气量
            if hs_mass[i] >= ΔH2 # 储氢罐氢气足够，无需储能
                to_hs[i] = -ΔH2
                to_ec_power[i] = outputEnergy(ec, to_hs[i])
                to_hc_power[i] = outputEnergy(hc, to_hs[i])
                # 储能分配
                to_e_es[i], to_ca_es[i] = 0, 0
                to_discard[i] = 0
                ΔE_from_grid[i] = 0
            elseif hs_mass[i] < ΔH2 # 储氢罐氢气不足，储能放电
                to_hs[i] = -hs_mass[i]
                ΔE_lack = ΔE[i] + outputEnergy(ec, hs_mass[i]) + outputEnergy(hc, hs_mass[i])
                # 储能分配
                if ΔE_lack >= -e_es_power[i]
                    to_e_es[i], to_ca_es[i] = ΔE_lack, 0
                elseif -e_es_power[i] - ca_es_power[i] <= ΔE_lack < -e_es_power[i]
                    to_e_es[i], to_ca_es[i] = -e_es_power[i], ΔE_lack + e_es_power[i]
                else # 储能不够则购电
                    to_e_es[i], to_ca_es[i] = -e_es_power[i], -ca_es_power[i]
                end
                to_ec_power[i] = outputEnergy(ec, to_hs[i])
                to_hc_power[i] = outputEnergy(hc, to_hs[i])
                to_discard[i] = 0
                ΔE_from_grid[i] = ΔE_lack - to_e_es[i] - to_ca_es[i] 
            end
        end 
        hs_mass[i+1] = hs_mass[i] + to_hs[i] # 储氢罐储气量
        to_es[i] = to_e_es[i] + to_ca_es[i] # 储能充电量
        e_es_power[i+1] = e_es_power[i] + to_e_es[i] # 电化学储能量
        ca_es_power[i+1] = ca_es_power[i] + to_ca_es[i] # 压缩空气储能量
        es_power[i+1] = e_es_power[i+1] + ca_es_power[i+1] # 储能总量 
    end
    return to_ec_power, to_hc_power, to_hs, hs_mass, to_es, to_e_es, to_ca_es, es_power, e_es_power, ca_es_power, to_discard, ΔE_from_grid
end