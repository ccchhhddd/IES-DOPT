"""
返回仿真结果的字典数据

- Val{1}：风光制氢余电上网
- Val{2}：风光制氢余电不上网
- Val{3}：离网制氢
- Val{4}：风光储 TODO
- Val{5}：风光气储 TODO
- Val{6}：风光煤储 TODO
- Val{7}：风光气煤储
- Val{8}：风光煤气氢储
"""
function simulate_ies_ele!(machines::Tuple, fin::Financial, ::Val{1})
    pv, wt, ec, hc, _ = machines
    pv_power, wt_power, load_power = map(outputEnergy, (pv, wt, ec))
    # println(load_power)
    hc.load = outputH2Mass(load_power, ec, 1.0)
    hc_power = outputEnergy(hc)
    powers = (pv_power, wt_power, load_power, hc_power)
    # 供给-需求=ΔE
    ΔE = wt_power + pv_power - load_power - hc_power
    # 余电上网，网汇购电
    ΔE_to_grid, ΔE_from_grid = pn_split(ΔE)
    machines = (pv, wt, ec, hc)
    fd = figureDictData(wt_power, pv_power, load_power, hc_power,
        ΔE_to_grid, ΔE_from_grid, Val(1))
    ecd = economicAnalysisData(machines, fin, powers,
        (sum(ΔE_to_grid), sum(ΔE_from_grid), 0), Val(1))
    return fd, ecd
end


# function simulate!(machines::Tuple, fin::Financial, ::Val{2})
#     pv, wt, ec, hc, e_es, ca_es, _ = machines
#     machines = (pv, wt, ec, hc, e_es, ca_es)
#     pv_power, wt_power, load_power = map(outputEnergy, (pv, wt, ec))
#     if ec.capacity < maximum(load_power)
#         return Inf
#     end
#     hc.load = outputH2Mass(load_power, ec, 1.0)
#     hc_power = outputEnergy(hc)
#     # 供给-需求=ΔE
#     ΔE = wt_power + pv_power - load_power - hc_power
#     # to_es, es_power = outputEnergy(es, ΔE)
#     to_es, to_e_es, to_ca_es, es_power, e_es_power, ca_es_power = outputEnergy(e_es, ca_es, ΔE)
#     ΔE -= to_es
#     to_discard, ΔE_from_grid = pn_split(ΔE)
#     to_es, from_es = pn_split(to_es)
#     to_e_es, from_e_es = pn_split(to_e_es)
#     to_ca_es, from_ca_es = pn_split(to_ca_es)

#     powers = (pv_power, wt_power, load_power, hc_power, es_power, e_es_power, ca_es_power)
#     ecd = economicAnalysisData(machines, fin, powers,
#         (0, ΔE_from_grid, sum(to_discard)), Val(2))
#     fd = figureDictData(wt_power, pv_power, load_power, hc_power,
#         to_discard, ΔE_from_grid, to_es, to_e_es, to_ca_es, from_es, from_e_es, from_ca_es, Val(2))
#     return fd, ecd
# end

function simulate_ies_ele!(machines::Tuple, fin::Financial, ::Val{2})
    pv, wt, ec, hc, hs, e_es, ca_es, _ = machines
    machines = (pv, wt, ec, hc, hs, e_es, ca_es)
    pv_power, wt_power, load_power_base = map(outputEnergy, (pv, wt, ec))
    if ec.capacity < maximum(load_power_base)
        return Inf
    end
    hc.load = outputH2Mass(load_power_base, ec, 1.0)
    hc_power_base = outputEnergy(hc)
    # 供给-基础负荷=ΔE
    ΔE = wt_power + pv_power - load_power_base - hc_power_base
    to_ec_power, to_hc_power, to_hs, hs_mass, to_es, to_e_es, to_ca_es, es_power, e_es_power, ca_es_power, to_discard, ΔE_from_grid = outputEnergy(ec, hc, hs, e_es, ca_es, ΔE)
    to_es, from_es = pn_split(to_es)
    to_e_es, from_e_es = pn_split(to_e_es)
    to_ca_es, from_ca_es = pn_split(to_ca_es)
    ec_power = load_power_base .+ to_ec_power
    hc_power = hc_power_base .+ to_hc_power

    to_ec_power, from_ec_power = pn_split(to_ec_power)
    to_hc_power, from_hc_power = pn_split(to_hc_power)

    powers = (pv_power, wt_power, ec_power, hc_power, es_power, e_es_power, ca_es_power, load_power_base)
    ecd = economicAnalysisData(machines, fin, powers,
        (0, ΔE_from_grid, sum(to_discard)), Val(2))
    fd = figureDictData(wt_power, pv_power, to_ec_power, from_ec_power, to_hc_power, from_hc_power,
        to_discard, ΔE_from_grid, to_es, from_es, Val(2))
    return fd, ecd
end

# Val(3)未进行更新
function simulate_ies_ele!(machines::Tuple, fin::Financial, ::Val{3})
    pv, wt, ec, hc, es, _ = machines
    machines = (pv, wt, ec, hc, es)
    pv_power, wt_power, load_power = map(outputEnergy, (pv, wt, ec))
    hc.load = outputH2Mass(load_power, ec, 1.0)
    hc_power = outputEnergy(hc)
    # 供给-需求=ΔE
    ΔE = wt_power + pv_power - load_power - hc_power
    to_es, es_power = outputEnergy(es, ΔE)
    ΔE -= to_es
    ΔE_to_grid, ΔE_from_grid = pn_split(ΔE)
    load_discount = @. 1 + ΔE_from_grid / (load_power + hc_power)
    to_es, from_es = pn_split(to_es)

    powers = (pv_power, wt_power, load_power, hc_power, es_power)
    fd = figureDictData(wt_power, pv_power,
        load_power .* load_discount, hc_power .* load_discount,
        ΔE_to_grid, to_es, from_es, Val(3))
    ecd = economicAnalysisData(machines, fin, powers,
        (0, 0, sum(ΔE_to_grid), load_discount), Val(3))
    return fd, ecd
end


function simulate_ies_ele!(machines::Tuple, fin::Financial, ::Val{7})
    pv, wt, _, _, p_es, ca_es, e_es, cp, gp, channelpower = machines
    machines = (pv, wt, p_es, ca_es, e_es, cp, gp)
    pv_power, wt_power, cp_power_base, gp_power_base = map(outputEnergy, (pv, wt, cp, gp))
    # println(sum(pv_power))
    load_power = generateChannelConstrainData(channelpower["winter"], channelpower["summer"])
    # 供给-需求=ΔE
    ΔE = @. wt_power + pv_power + cp_power_base + gp_power_base - load_power
    # 计算煤气电与储能分配
    cp_to_add, gp_to_add, to_es, to_p_es, to_ca_es, to_e_es, es_power, p_es_power, ca_es_power, e_es_power = outputEnergy(gp, cp, p_es, ca_es, e_es, ΔE)
    ΔE += (cp_to_add + gp_to_add - to_es)
    to_discard, ΔE_from_grid = pn_split(ΔE)
    to_es, from_es = pn_split(to_es)
    to_p_es, from_p_es = pn_split(to_p_es)
    to_ca_es, from_ca_es = pn_split(to_ca_es)
    to_e_es, from_e_es = pn_split(to_e_es)
    # from_es = @.from_p_es + from_ca_es + from_e_es
    cp_power = cp_to_add .+ cp_power_base
    gp_power = gp_to_add .+ gp_power_base
    powers = (pv_power, wt_power, cp_power, gp_power, load_power, es_power, p_es_power, ca_es_power, e_es_power)

    ecd = economicAnalysisData(machines, fin, powers,
    (0, sum(ΔE_from_grid), sum(to_discard)), Val(7)) # 余电上网及外送负荷，网汇购电为0

    fd = figureDictData(wt_power, pv_power, cp_power, gp_power, ΔE_from_grid, to_discard,
    to_es, to_p_es, to_ca_es, to_e_es, from_es, from_p_es, from_ca_es, from_e_es, load_power, Val(7))

    return fd, ecd
end


function simulate_ies_ele!(machines::Tuple, fin::Financial, ::Val{8})
    pv, wt, ec, hc, es, cp, gp = machines
    # machines = (pv, wt, es, cp, gp)
    pv_power, wt_power, cp_power_base, gp_power_base = map(outputEnergy, (pv, wt, cp, gp))
    electricity_load_power = generateChannelConstrainData(1.0e5 .* [3, 3, 3, 3, 3, 3, 3, 3, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 3, 3, 3, 3, 3, 3], 1.0e5 .* [4, 4, 4, 4, 4, 4, 4, 5.6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 4, 4, 4, 4, 4])
    # 供给-需求=ΔE
    ΔE = @. wt_power + pv_power + cp_power_base + gp_power_base - electricity_load_power
    # 1千瓦时电量制氢产量
    unit_mass = ec.Δt * ec.M_H2 / ec.LHV_H2 * 3.6 * ec.η_EC
    # 电解槽制氢总耗费电量的系数
    coefficient_H2 = (hc.comsumption * unit_mass + 1)
    # 计算煤气电与储能分配
    cp_to_add, gp_to_add, to_es, es_power, ec_power = outputEnergy(gp, cp, es, ec, coefficient_H2, ΔE)
    # 计算电解槽和氢压缩机的氢产量负荷
    h2_mass = outputH2Mass(ec_power, ec, coefficient_H2)
    ec.load, hc.load = copy(h2_mass), copy(h2_mass)
    # 添加 煤气电 补充电量 与储能、电解槽的分配
    ΔE += (cp_to_add + gp_to_add - to_es - ec_power)
    to_discard, ΔE_from_grid = pn_split(ΔE)
    to_es, from_es = pn_split(to_es)
    cp_power = cp_to_add .+ cp_power_base
    gp_power = gp_to_add .+ gp_power_base
    powers = (pv_power, wt_power, cp_power, gp_power, electricity_load_power, ec_power, es_power)
    fd = figureDictData(wt_power, pv_power, cp_power, gp_power,
        to_discard, to_es, from_es, electricity_load_power, ec_power, Val(8))
    ecd = economicAnalysisData(machines, fin, powers,
        (0, 0, sum(to_discard)), Val(8)) # 余电上网及外送负荷，网汇购电为0
    return fd, ecd
end
