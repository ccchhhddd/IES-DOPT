"""
返回仿真结果的字典数据


- Val{1}：离网制氢

"""

function simulate!(machines::Tuple, fin::Financial, ::Val{3})
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
