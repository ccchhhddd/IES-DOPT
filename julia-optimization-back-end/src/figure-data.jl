"""
    figureDictData(wt_power, pv_power, ec_power,hc_power, ΔE_to_grid, ΔE_from_grid...)

    返回绘图数据字典

- `wt_power` 风力发电量
- `pv_power` 光伏发电量
- `ec_power` 制氢负荷量
- `hc_power` 储氢负荷量
- `ΔE_to_grid` 卖电上网量
- `ΔE_from_grid` 电网购电量
- `ΔE_to_es` 储氢充电量
- `ΔE_from_es` 储氢放电量

"""

figureDictData(wt_power, pv_power, ec_power,
    hc_power, ΔE_to_grid, to_es, from_es, ::Val{3}) = OrderedDict(
    "风力发电量" => round.(wt_power, digits=2),
    "光伏发电量" => round.(pv_power, digits=2),
    "储能放电量" => round.(-from_es, digits=2),
    "制氢负荷量" => round.(-ec_power, digits=2),
    "储氢用电量" => round.(-hc_power, digits=2),
    "储能充电量" => round.(-to_es, digits=2),
    "风光弃电量" => round.(-ΔE_to_grid, digits=2),
)
