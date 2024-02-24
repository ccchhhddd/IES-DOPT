"""
    figureDictData(wt_power, pv_power, ec_power,hc_power, ΔE_to_grid, ΔE_from_grid...)

    返回绘图数据字典

- `wt_power` 风力发功率
- `pv_power` 光伏发功率
- `ec_power` 制氢负荷量
- `hc_power` 储氢负荷量
- `ΔE_to_grid` 卖电上网量
- `ΔE_from_grid` 电网购功率
- `ΔE_to_es` 储氢充功率
- `ΔE_from_es` 储氢放功率

"""
figureDictData(wt_power, pv_power, ec_power,
    hc_power, ΔE_to_grid, ΔE_from_grid, ::Val{1}) = OrderedDict(
    "风力发电功率" => round.(wt_power / 1e4, digits=2),
    "光伏发电功率" => round.(pv_power / 1e4, digits=2),
    "网汇功率" => round.(-ΔE_from_grid / 1e4, digits=2),
    # "制氢负荷量" => round.(-ec_power / 1e4, digits=2),
    "卖电上网量" => round.(ΔE_to_grid / 1e4, digits=2),
    # "储氢用功率" => round.(-hc_power / 1e4, digits=2)
)

function figureDictData(wt_power, pv_power, to_ec_power, from_ec_power, to_hc_power, from_hc_power,
    to_discard, ΔE_from_grid, to_es, from_es, ::Val{2}) 

        for i in eachindex(pv_power)
                s = to_es[i] + to_discard[i] + to_ec_power[i] + to_hc_power[i]
            if pv_power[i] >= s
                pv_power[i] -= to_es[i] + to_discard[i] + to_ec_power[i] + to_hc_power[i]
            else
                wt_power[i] -= s - pv_power[i]
                pv_power[i] = 0
            end
        end

    return OrderedDict(
        "风力发电功率" => round.(wt_power / 1e4, digits=2),
        "光伏发电功率" => round.(pv_power / 1e4, digits=2),
        "储氢罐放气功率" => round.(-(from_ec_power + from_hc_power)  / 1e4, digits=2),      
        "储能总放电功率" => round.(-from_es / 1e4, digits=2),
        "网汇功率" => round.(-ΔE_from_grid / 1e4, digits=2),
        "储氢罐充气用功率" => round.((to_ec_power + to_hc_power)  / 1e4, digits=2),
        "储能总充电功率" => round.(to_es / 1e4, digits=2),
        # "制氢负荷量" => round.(ec_power / 1e4, digits=2),
        # "储氢用功率" => round.(-hc_power / 1e4, digits=2),
        "弃电功率" => round.(to_discard / 1e4, digits=2),
    )
end
figureDictData(wt_power, pv_power, ec_power,
    hc_power, ΔE_to_grid, to_es, from_es, ::Val{3}) = OrderedDict(
    "风力发功率" => round.(wt_power, digits=2),
    "光伏发功率" => round.(pv_power, digits=2),
    "储能放功率" => round.(-from_es, digits=2),
    "制氢负荷量" => round.(-ec_power, digits=2),
    "储氢用功率" => round.(-hc_power, digits=2),
    "储能充功率" => round.(-to_es, digits=2),
    "风光弃功率" => round.(-ΔE_to_grid, digits=2),
)

# figureDictData(wt_power, pv_power, cp_power,
#     gp_power, ΔE_to_grid, ΔE_from_grid, to_es, from_es, load, ::Val{7}) = OrderedDict(
#     "煤电发电功率" => round.(cp_power / 1e4, digits=2),
#     "气电发电功率" => round.(gp_power / 1e4, digits=2),
#     "风力发电功率" => round.(wt_power / 1e4, digits=2),
#     "光伏发电功率" => round.(pv_power / 1e4, digits=2),
#     "储能放电功率" => round.(-from_es / 1e4, digits=2),
#     # "储能充功率" => round.(to_es, digits=2),
#     "网汇功率" => round.(-ΔE_from_grid / 1e4, digits=2),
#     # "弃电功率" => round.(ΔE_to_grid, digits=2),
#     # "外送通道功率" => round.(load, digits=2),
# )

# function figureDictData(wt_power, pv_power, cp_power,
#     gp_power, ΔE_to_grid, ΔE_from_grid, to_es, from_es, load, ::Val{7})

#     for i in eachindex(pv_power)
#         s = to_es[i] + ΔE_to_grid[i]
#         if pv_power[i] >= s
#             pv_power[i] -= to_es[i] + ΔE_to_grid[i]
#         else
#             wt_power[i] -= s - pv_power[i]
#             pv_power[i] = 0
#         end
#     end
    
#     return OrderedDict(
#         "煤电发电功率" => round.(cp_power / 1e4, digits=2),
#         "气电发电功率" => round.(gp_power / 1e4, digits=2),
#         "风力发电功率" => round.(wt_power / 1e4, digits=2),
#         "光伏发电功率" => round.(pv_power / 1e4, digits=2),
#         "储能放电功率" => round.(-from_es / 1e4, digits=2),
#         "网汇功率" => round.(-ΔE_from_grid / 1e4, digits=2),
#         "储能充功率" => round.(to_es / 1e4, digits=2),
#         "弃电功率" => round.(ΔE_to_grid / 1e4, digits=2),
#         # "外送通道功率" => round.(load, digits=2),
#     )
# end

function figureDictData(wt_power, pv_power, cp_power, gp_power,  ΔE_from_grid, to_discard,
    to_es, to_p_es, to_ca_es, to_e_es, from_es, from_p_es, from_ca_es, from_e_es, load, ::Val{7})

    for i in eachindex(pv_power)
        s = to_es[i] + to_discard[i]
        if pv_power[i] >= s
            pv_power[i] -= to_es[i] + to_discard[i]
        else
            wt_power[i] -= s - pv_power[i]
            pv_power[i] = 0
        end
    end
    
    return OrderedDict(
        "煤电发电功率" => round.(cp_power / 1e4, digits=2),
        "气电发电功率" => round.(gp_power / 1e4, digits=2),
        "风力发电功率" => round.(wt_power / 1e4, digits=2),
        "光伏发电功率" => round.(pv_power / 1e4, digits=2),
        "储能总放电功率" => round.(-from_es / 1e4, digits=2),
        # "抽水储能放电功率" => round.(-from_p_es / 1e4, digits=2),
        # "压缩空气储能放电功率" => round.(-from_ca_es / 1e4, digits=2),
        # "电化学储能放电功率" => round.(-from_e_es / 1e4, digits=2),
        "网汇功率" => round.(-ΔE_from_grid / 1e4, digits=2),
        "储能总充电功率" => round.(to_es / 1e4, digits=2),
        # "抽水储能充功率" => round.(to_p_es / 1e4, digits=2),
        # "压缩空气储能充功率" => round.(to_ca_es / 1e4, digits=2),
        # "电化学储能充功率" => round.(to_e_es / 1e4, digits=2),
        "弃电功率" => round.(to_discard / 1e4, digits=2),
        # "外送通道功率" => round.(load, digits=2),
    )
end


figureDictData(wt_power, pv_power, cp_power,
    gp_power, ΔE_to_grid, to_es, from_es, load, ec_power, ::Val{8}) = OrderedDict(
    "风力发功率" => round.(wt_power, digits=2),
    "光伏发功率" => round.(pv_power, digits=2),
    "煤电发功率" => round.(cp_power, digits=2),
    "气电发功率" => round.(gp_power, digits=2),
    "储能放功率" => round.(-from_es, digits=2),
    "外送通道功率" => round.(-load, digits=2),
    "储能充功率" => round.(-to_es, digits=2),
    "制氢耗功率" => round.(-ec_power, digits=2),
    "弃电功率" => round.(-ΔE_to_grid, digits=2),
)


