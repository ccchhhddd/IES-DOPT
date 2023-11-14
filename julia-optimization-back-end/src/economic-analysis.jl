"""
    economic_analysis(machines, fin, powers, ΔE, ::Val{1})

    返回设备的经济评价指标。

- `machines`：设备元组
- `fin`：金融参数
- `powers`：设备发电量、电解量等（储氢能耗忽略）
- `::Val{1}`：用于类型分派, 风光制氢余电上网
- `::Val{2}`：用于类型分派, 风光制氢余电不上网
- `::Val{3}`：用于类型分派, 离网制氢
- `::Val{7}`：用于类型分派, 风光煤气储
- `::Val{8}`：用于类型分派, 风光煤气氢储

"""
function economicAnalysisData(machines::Tuple, fin::Financial, powers::Tuple, ΔE::Tuple, ::Val{1})
    # 风机、光伏、电解槽、压缩机
    pv, wt, ec, hc = machines
    # 风机发电量、光伏发电量、电解槽电解量、压缩机压缩量
    wt_power, pv_power, ec_power, hc_power = powers
    # 风机发电总量、光伏发电总量、电解槽电解总量、压缩机压缩总量
    sum_pv_power, sum_wt_power, sum_ec_power, sum_hc_power = map(sum, powers)
    # 风机、光伏总发电
    sum_RE_power = sum_pv_power + sum_wt_power
    # 余电上网，缺电购电
    ΔE_to_grid, ΔE_from_grid, to_discard = ΔE
    # 风光利用率
    utilization_rate = 1 - to_discard / sum_RE_power
    # 电解槽总产氢量
    sum_mass_H2_load = outputH2Mass(sum_ec_power, ec, 1.0)
    # 初始投资与替换成本
    cost_initial = sum(x -> initialInvestment(x) + replacementCost(x, fin), machines)
    # 运维成本
    year_cost_OM = sum(annualOperationCost, machines)
    # 用水成本
    cost_water = costWater(sum_mass_H2_load, fin)
    # 买电成本
    buy_electricity_cost = buyElectricityCost(ΔE_from_grid, fin)
    # 卖电收益
    sell_electricity_profit = sellElectricityProfit(ΔE_to_grid, fin)
    # 售氢收益
    sell_H2_profit = sellH2Profit(sum_mass_H2_load, fin)
    # 制氢成本
    LCOE_H2 = (buy_electricity_cost + cost_water + year_cost_OM) / sum_mass_H2_load
    # 年现金流收益
    annual_profit = -year_cost_OM + sell_electricity_profit - buy_electricity_cost + sell_H2_profit - cost_water

    # 经济性参数
    NPV, IRR, payback = financial_evaluation(cost_initial, annual_profit, ceil(fin.n_sys);
        rate_depreciation=fin.rate_depreciation,
        rate_discount=fin.rate_discount,
        rate_tax=fin.rate_tax)

    return OrderedDict(
        "风电（万千瓦）" => wt.capacity / 1e4,
        "光伏（万千瓦）" => pv.capacity / 1e4,
        "制氢（万千瓦）" => ec.capacity / 1e4,
        "储氢（吨）" => hc.capacity / 1e3,
        "储氢（万立方米）" => hc.capacity / 1e4 / 0.089,
        "售氢价格（元/kg）" => fin.H2price_sale,
        "系统设计寿命（年）" => fin.n_sys,
        "光伏电量（亿千瓦时）" => sum_pv_power / 1e8,
        "光伏利用小时数" => sum_pv_power ÷ pv.capacity,
        "风电电量（亿千瓦时）" => sum_wt_power / 1e8,
        "风电利用小时数" => sum_wt_power ÷ wt.capacity,
        "风电光伏电量（亿千瓦时）" => sum_RE_power / 1e8,
        "风电光伏利用率（%）" => utilization_rate * 100,
        "风电光伏弃电率（%）" => (1 - utilization_rate) * 100,
        "风光发电制氢电量（亿千瓦时）" => (sum_RE_power - ΔE_to_grid) / 1e8,
        "风光上网电量（亿千瓦时）" => abs(ΔE_to_grid) / 1e8,
        "电网供电量（亿千瓦时）" => abs(ΔE_from_grid) / 1e8,
        "制氢量（万吨）" => sum_mass_H2_load / 1e7,
        "制氢用电量（亿千瓦时）" => sum_ec_power / 1e8,
        "储氢用电量（亿千瓦时）" => sum_hc_power / 1e8,
        "制氢设备利用小时数（小时）" => count(>(0), ec_power),
        "风光电量占制氢用电量比例（%）" => (sum_RE_power - ΔE_to_grid) / (sum_ec_power + sum_hc_power) * 100,
        "静态总投资（亿元）" => cost_initial / 1e8,
        "年度售电盈利（亿元）" => sell_electricity_profit / 1e8,
        "年度买电制氢成本（亿元）" => buy_electricity_cost / 1e8,
        "年度售氢盈利（亿元）" => sell_H2_profit / 1e8,
        "年度运维成本（亿元）" => year_cost_OM / 1e8,
        "年度用水成本（亿元）" => cost_water / 1e8,
        "制氢价格（元/kg）" => LCOE_H2,
        "制氢价格（元/方）" => LCOE_H2 * 0.089,
        # "发电度电成本（元/kWh）" => LCOE,
        "年度现金流收益（亿元）" => annual_profit / 1e8,
        "静态总投资回收年限（年）" => ceil(cost_initial / annual_profit),
        "项目净现值NPV（亿元）" => NPV / 1e8,
        "内部收益率IRR" => IRR,
        "目标收益率下投资盈亏平衡年限（年）" => payback
    )
end

function economicAnalysisData(machines::Tuple, fin::Financial, powers::Tuple, ΔE::Tuple, ::Val{2})
    # 风机、光伏、电解槽、压缩机
    pv, wt, ec, hc, es = machines
    # 风机发电量、光伏发电量、电解槽电解量、压缩机压缩量
    wt_power, pv_power, ec_power, hc_power, es_power = powers
    # 风机发电总量、光伏发电总量、电解槽电解总量、压缩机压缩总量
    sum_pv_power, sum_wt_power, sum_ec_power, sum_hc_power, sum_es_power = map(sum, powers)
    # 风机、光伏总发电
    sum_RE_power = sum_pv_power + sum_wt_power
    # 余电上网，缺电购电
    ΔE_to_grid, ΔE_from_grid, to_discard = ΔE
    # 风光利用率
    utilization_rate = 1 - to_discard / sum_RE_power
    # 电解槽总产氢量
    sum_mass_H2_load = outputH2Mass(sum_ec_power, ec, 1.0)
    # 初始投资与替换成本
    cost_initial = sum(x -> initialInvestment(x) + replacementCost(x, fin), machines)
    # 运维成本
    year_cost_OM = sum(annualOperationCost, machines)
    # 用水成本
    cost_water = costWater(sum_mass_H2_load, fin)
    # 买电成本
    buy_electricity_cost = buyElectricityCost(ΔE_from_grid, fin)
    # 售氢收益
    sell_H2_profit = sellH2Profit(sum_mass_H2_load, fin)
    # 制氢成本
    LCOE_H2 = (buy_electricity_cost + cost_water + year_cost_OM) / sum_mass_H2_load
    # 年现金流收益
    annual_profit = -year_cost_OM - buy_electricity_cost + sell_H2_profit - cost_water

    # 经济性参数
    NPV, IRR, payback = financial_evaluation(cost_initial, annual_profit, ceil(fin.n_sys);
        rate_depreciation=fin.rate_depreciation,
        rate_discount=fin.rate_discount,
        rate_tax=fin.rate_tax)

    return OrderedDict(
        "风电（万千瓦）" => wt.capacity / 1e4,
        "光伏（万千瓦）" => pv.capacity / 1e4,
        "制氢（万千瓦）" => ec.capacity / 1e4,
        "储能（万千瓦时）" => es.capacity / 1e4,
        "储氢（吨）" => hc.capacity / 1e3,
        "储氢（万立方米）" => hc.capacity / 1e4 / 0.089,
        "售氢价格（元/kg）" => fin.H2price_sale,
        # "储氢设备充能阈值" => HT.SoC_cha_thre],
        "系统设计寿命（年）" => fin.n_sys,
        "光伏电量（亿千瓦时）" => sum_pv_power / 1e8,
        "光伏利用小时数" => sum_pv_power ÷ pv.capacity,
        "风电电量（亿千瓦时）" => sum_wt_power / 1e8,
        "风电利用小时数" => sum_wt_power ÷ wt.capacity,
        "风电光伏电量（亿千瓦时）" => sum_RE_power / 1e8,
        "风电光伏利用率（%）" => utilization_rate * 100,
        "风电光伏弃电率（%）" => (1 - utilization_rate) * 100,
        "风光发电制氢电量（亿千瓦时）" => (sum_RE_power - to_discard) / 1e8,
        "储能利用小时数" => sum_es_power ÷ es.capacity,
        "电网供电量（亿千瓦时）" => abs(ΔE_from_grid) / 1e8,
        "制氢量（万吨）" => sum_mass_H2_load / 1e7,
        "制氢用电量（亿千瓦时）" => sum_ec_power / 1e8,
        "储氢用电量（亿千瓦时）" => sum_hc_power / 1e8,
        "制氢设备利用小时数（小时）" => count(>(0), ec_power),
        "风光电量占制氢用电量比例（%）" => (sum_RE_power - to_discard) / (sum_ec_power + sum_hc_power) * 100,
        "静态总投资（亿元）" => cost_initial / 1e8,
        "年度买电制氢成本（亿元）" => buy_electricity_cost / 1e8,
        "年度售氢盈利（亿元）" => sell_H2_profit / 1e8,
        "年度运维成本（亿元）" => year_cost_OM / 1e8,
        "年度用水成本（亿元）" => cost_water / 1e8,
        "制氢价格（元/kg）" => LCOE_H2,
        "制氢价格（元/方）" => LCOE_H2 * 0.089,
        "年度现金流收益（亿元）" => annual_profit / 1e8,
        # "发电度电成本（元/kWh）" => LCOE,
        "静态总投资回收年限（年）" => ceil(cost_initial / annual_profit),
        "项目净现值NPV（亿元）" => NPV / 1e8,
        "内部收益率IRR" => IRR,
        "目标收益率下投资盈亏平衡年限（年）" => payback
    )
end

function economicAnalysisData(machines::Tuple, fin::Financial, powers::Tuple, ΔE::Tuple, ::Val{3})
    # 风机、光伏、电解槽、压缩机
    pv, wt, ec, hc, es = machines
    # 风机发电量、光伏发电量、电解槽电解量、压缩机压缩量
    wt_power, pv_power, ec_power, hc_power, es_power = powers
    # 风机发电总量、光伏发电总量、电解槽电解总量、压缩机压缩总量
    sum_pv_power, sum_wt_power, sum_ec_power, sum_hc_power, sum_es_power = map(sum, powers)
    # 风机、光伏总发电
    sum_RE_power = sum_pv_power + sum_wt_power
    # 余电上网，缺电购电
    ΔE_to_grid, ΔE_from_grid, to_discard, load_discount = ΔE
    # 风光利用率
    utilization_rate = 1 - to_discard / sum_RE_power
    # 电解槽总产氢量
    sum_mass_H2_load = outputH2Mass(sum(ec_power .* load_discount), ec, 1.0)

    # 初始投资与替换成本
    cost_initial = sum(x -> initialInvestment(x) + replacementCost(x, fin), machines)
    # 运维成本
    year_cost_OM = sum(annualOperationCost, machines)
    # 用水成本
    cost_water = costWater(sum_mass_H2_load, fin)
    # 买卖电收益
    sell_buy_electricity_profit = sellElectricityProfit(ΔE_to_grid, fin) - buyElectricityCost(ΔE_from_grid, fin)
    # 售氢收益
    sell_H2_profit = sellH2Profit(sum_mass_H2_load, fin)

    # LCOE 制氢成本
    LCOE_H2 = (-sell_buy_electricity_profit + cost_water + year_cost_OM) / sum_mass_H2_load
    # 年现金流收益
    annual_profit = -year_cost_OM + sell_buy_electricity_profit + sell_H2_profit - cost_water

    # 经济性参数
    NPV, IRR, payback = financial_evaluation(cost_initial, annual_profit, ceil(fin.n_sys);
        rate_depreciation=fin.rate_depreciation,
        rate_discount=fin.rate_discount,
        rate_tax=fin.rate_tax)

    return OrderedDict(
        "风电（万千瓦）" => wt.capacity / 1e4,
        "光伏（万千瓦）" => pv.capacity / 1e4,
        "制氢（万千瓦）" => ec.capacity / 1e4,
        "储能（万千瓦时）" => es.capacity / 1e4,
        "储氢（吨）" => hc.capacity / 1e3,
        "储氢（万立方米）" => hc.capacity / 1e4 / 0.089,
        "售氢价格（元/kg）" => fin.H2price_sale,
        "系统设计寿命（年）" => fin.n_sys,
        "光伏电量（亿千瓦时）" => sum_pv_power / 1e8,
        "光伏利用小时数" => sum_pv_power ÷ pv.capacity,
        "风电电量（亿千瓦时）" => sum_wt_power / 1e8,
        "风电利用小时数" => sum_wt_power ÷ wt.capacity,
        "风电光伏电量（亿千瓦时）" => sum_RE_power / 1e8,
        "风电光伏利用率（%）" => utilization_rate * 100,
        "风电光伏弃电率（%）" => (1 - utilization_rate) * 100,
        "风光发电制氢电量（亿千瓦时）" => (sum_RE_power - to_discard) / 1e8,
        "风光上网电量（亿千瓦时）" => abs(ΔE_to_grid) / 1e8,
        "储能利用小时数" => sum_es_power ÷ es.capacity,
        "电网供电量（亿千瓦时）" => abs(ΔE_from_grid) / 1e8,
        "制氢量（万吨）" => sum_mass_H2_load / 1e7,
        "制氢用电量（亿千瓦时）" => sum_ec_power / 1e8,
        "储氢用电量（亿千瓦时）" => sum_hc_power / 1e8,
        "制氢设备利用小时数（小时）" => count(>(0), ec_power),
        "风光电量占制氢用电量比例（%）" => (sum_RE_power - to_discard) / (sum_ec_power + sum_hc_power) * 100,
        "静态总投资（亿元）" => cost_initial / 1e8,
        "年度售电盈利（亿元）" => sell_buy_electricity_profit / 1e8,
        "年度售氢盈利（亿元）" => sell_H2_profit / 1e8,
        "年度运维成本（亿元）" => year_cost_OM / 1e8,
        "年度用水成本（亿元）" => cost_water / 1e8,
        "制氢价格（元/kg）" => LCOE_H2,
        "制氢价格（元/方）" => LCOE_H2 * 0.089,
        "年度现金流收益（亿元）" => annual_profit / 1e8,
        "静态总投资回收年限（年）" => ceil(cost_initial / annual_profit),
        "项目净现值NPV（亿元）" => NPV / 1e8,
        "内部收益率IRR" => IRR,
        "目标收益率下投资盈亏平衡年限（年）" => payback
    )
end

function economicAnalysisData(machines::Tuple, fin::Financial, powers::Tuple, ΔE::Tuple, ::Val{7})
    # 风机、光伏、储能、煤电、气电
    pv, wt, es, cp, gp = machines
    # 风机发电量、光伏发电量、煤电发电量、气电发电量、负荷（列表）
    wt_power, pv_power, cp_power, gp_power, load_power, es_power = powers
    # 风机发电总量、光伏发电总量、煤电发电总量、气电发电总量
    sum_pv_power, sum_wt_power, sum_cp_power, sum_gp_power, sum_load_power, sum_es_power = map(sum, powers)
    # 风机、光伏总发电
    sum_RE_power = sum_pv_power + sum_wt_power
    # 电上网
    ΔE_to_grid, ΔE_from_grid, to_discard = ΔE
    # 风光利用率
    utilization_rate = 1 - to_discard / sum_load_power
    # 初始投资与替换成本
    cost_initial = sum(x -> initialInvestment(x) + replacementCost(x, fin), machines)
    # 运维成本
    year_cost_OM = sum(annualOperationCost, machines)
    # 买卖电收益
    sell_buy_electricity_profit = sellElectricityProfit(sum_load_power, fin) - buyElectricityCost(ΔE_from_grid, fin)
    # 年燃煤成本
    cost_coal = costCoal(sum_cp_power, cp, fin)
    # 煤耗（kg）
    sum_coal = cost_coal / fin.price_coal_per_kg
    # 年燃气成本
    cost_gas = costGas(sum_gp_power, gp, fin)
    # 气耗（m³）
    sum_gas = cost_gas / fin.price_gas_per_Nm3
    # LCOE 发电度电成本（元/kWh）
    LCOE = (cost_coal + cost_gas + year_cost_OM) / sum_load_power
    # 年现金流收益
    annual_profit = -year_cost_OM + sell_buy_electricity_profit - cost_coal - cost_gas

    # 经济性参数
    NPV, IRR, payback = financial_evaluation(cost_initial, annual_profit, ceil(fin.n_sys);
        rate_depreciation=fin.rate_depreciation,
        rate_discount=fin.rate_discount,
        rate_tax=fin.rate_tax)

    year_cost = year_cost_OM + cost_coal + cost_gas + buyElectricityCost(ΔE_from_grid, fin)

    # 计算满足年度现金流收益的售电价格
    sell_price = find_price(cost_initial, year_cost, sum_load_power, ceil(fin.n_sys);
        rate_depreciation=fin.rate_depreciation,
        rate_discount=fin.rate_discount,
        rate_tax=fin.rate_tax)

    return OrderedDict(
        "风电（万千瓦）" => wt.capacity / 1e4,
        "光伏（万千瓦）" => pv.capacity / 1e4,
        "储能（万千瓦时）" => es.capacity / 1e4,
        "煤电（万千瓦）" => cp.capacity / 1e4,
        "气电（万千瓦）" => gp.capacity / 1e4,
        "系统设计寿命（年）" => fin.n_sys,
        "光伏电量（亿千瓦时）" => sum_pv_power / 1e8,
        "光伏利用小时数" => sum_pv_power ÷ pv.capacity,
        "风电电量（亿千瓦时）" => sum_wt_power / 1e8,
        "风电利用小时数" => sum_wt_power ÷ wt.capacity,
        "风电光伏电量（亿千瓦时）" => sum_RE_power / 1e8,
        "风电光伏利用率（%）" => utilization_rate * 100,
        "风电光伏弃电率（%）" => (1 - utilization_rate) * 100,
        "风光上网电量（亿千瓦时）" => (sum_RE_power - to_discard) / 1e8,
        "储能利用小时数" => sum_es_power ÷ es.capacity,
        "电网供电量(缺电量)（亿千瓦时）" => abs(ΔE_from_grid) / 1e8,
        "缺电率（%）" => abs(ΔE_from_grid / sum_load_power) * 100,
        "煤电发电量（亿千瓦时）" => sum_cp_power / 1e8,
        "气电发电量（亿千瓦时）" => sum_gp_power / 1e8,
        "外送总电量（亿千瓦时）" => sum_load_power / 1e8,
        "新能源电量外送通道占比（%）" => (sum_RE_power) / (sum_load_power) * 100,
        "静态总投资（亿元）" => cost_initial / 1e8,
        "年度售电收入（亿元）" => sell_buy_electricity_profit / 1e8,
        "年度运维成本（亿元）" => year_cost_OM / 1e8,
        "年度燃煤成本（亿元）" => cost_coal / 1e8,
        "年度燃气成本（亿元）" => cost_gas / 1e8,
        "年度燃料总成本（亿元）" => (cost_coal + cost_gas) / 1e8,
        "度电煤耗（kg/kwh）" => sum_coal == 0 ? 0 : sum_coal / sum_cp_power,
        "度电气耗（Nm3/kwh）" => sum_gas == 0 ? 0 : sum_gas / sum_gp_power,
        "煤电碳排放（万吨）" => sum_coal * fin.coal_factor / 1e7,
        "气电碳排放（万吨）" => sum_gas * fin.gas_factor / 1e7,
        "煤电成本（元/kwh）" => sum_cp_power == 0 ? 0 : cost_coal / sum_cp_power,
        "气电成本（元/kwh）" => sum_gp_power == 0 ? 0 : cost_gas / sum_gp_power,
        "发电度电成本（元/kwh）" => LCOE,
        "年度现金流收益（亿元）" => annual_profit / 1e8,
        "静态总投资回收年限（年）" => ceil(cost_initial / annual_profit),
        "综合正收益落地电价（元/kWh）" => sell_price,
        # "项目净现值NPV（亿元）" => NPV / 1e8,
        # "内部收益率IRR" => IRR,
        # "目标收益率下投资盈亏平衡年限（年）" => payback
    )
end
# Val{8} 停止于 2023-08-25版本，运行逻辑未修正
function economicAnalysisData(machines::Tuple, fin::Financial, powers::Tuple, ΔE::Tuple, ::Val{8})
    # 风机、光伏、储能、煤电、气电、电解槽、压缩储氢
    pv, wt, ec, hc, es, cp, gp = machines
    # 风机发电量、光伏发电量、煤电发电量、气电发电量、负荷、电解槽耗电量（列表）
    wt_power, pv_power, cp_power, gp_power, load_power, ec_power, es_power = powers
    # 风机发电总量、光伏发电总量、煤电发电总量、气电发电总量、负荷总量、电解槽耗电总量
    sum_pv_power, sum_wt_power, sum_cp_power, sum_gp_power, sum_load_power, sum_ec_power, sum_es_power = map(sum, powers)
    # 风机、光伏总发电
    sum_RE_power = sum_pv_power + sum_wt_power
    # 余电上网（该场景下0）、缺电购电（该场景下0）、弃电
    ΔE_to_grid, ΔE_from_grid, to_discard = ΔE
    # 风光利用率
    utilization_rate = 1 - to_discard / sum_RE_power
    # 初始投资与替换成本
    cost_initial = sum(x -> initialInvestment(x) + replacementCost(x, fin), machines)
    # 运维成本
    year_cost_OM = sum(annualOperationCost, machines)
    # 买卖电收益
    sell_buy_electricity_profit = sellElectricityProfit(sum_load_power, fin) - buyElectricityCost(ΔE_from_grid, fin)
    # 年燃煤成本
    cost_coal = costCoal(sum_cp_power, cp, fin)
    # 煤耗（kg）
    sum_coal = cost_coal / fin.price_coal_per_kg
    # 年燃气成本
    cost_gas = costGas(sum_gp_power, gp, fin)
    # 气耗（m³）
    sum_gas = cost_gas / fin.price_gas_per_Nm3
    # 电解槽总产氢量
    sum_mass_H2_load = sum(ec.load)
    # 用水成本
    cost_water = costWater(sum_mass_H2_load, fin)
    # 售氢收益
    sell_H2_profit = sellH2Profit(sum_mass_H2_load, fin)
    # # LCOE 发电度电成本（元/kWh）
    LCOE = (cost_coal + cost_gas + year_cost_OM) / sum_load_power
    # 年现金流收益
    annual_profit = -year_cost_OM + sell_buy_electricity_profit - cost_coal - cost_gas + sell_H2_profit - cost_water

    # 经济性参数
    NPV, IRR, payback = financial_evaluation(cost_initial, annual_profit, ceil(fin.n_sys);
        rate_depreciation=fin.rate_depreciation,
        rate_discount=fin.rate_discount,
        rate_tax=fin.rate_tax)


    return OrderedDict(
        "风电（万千瓦）" => wt.capacity / 1e4,
        "光伏（万千瓦）" => pv.capacity / 1e4,
        "储能（万千瓦时）" => es.capacity / 1e4,
        "煤电（万千瓦）" => cp.capacity / 1e4,
        "气电（万千瓦）" => gp.capacity / 1e4,
        "系统设计寿命（年）" => fin.n_sys,
        "光伏电量（亿千瓦时）" => sum_pv_power / 1e8,
        "光伏利用小时数" => sum_pv_power ÷ pv.capacity,
        "风电电量（亿千瓦时）" => sum_wt_power / 1e8,
        "风电利用小时数" => sum_wt_power ÷ wt.capacity,
        "风电光伏电量（亿千瓦时）" => sum_RE_power / 1e8,
        "风电光伏利用率（%）" => utilization_rate * 100,
        "风电光伏弃电率（%）" => (1 - utilization_rate) * 100,
        "风光上网电量（亿千瓦时）" => (sum_RE_power - to_discard) / 1e8,
        "储能利用小时数" => sum_es_power ÷ es.capacity,
        "电网供电量（亿千瓦时）" => abs(ΔE_from_grid) / 1e8,
        "煤电发电量（亿千瓦时）" => sum_cp_power / 1e8,
        "产氢用电量（亿千瓦时）" => sum_ec_power / 1e8,
        "产氢量（吨）" => sum_mass_H2_load / 1e3,
        "气电发电量（亿千瓦时）" => sum_gp_power / 1e8,
        "外送总电量（亿千瓦时）" => sum_load_power / 1e8,
        "风光电量占总发电量比例（%）" => (sum_RE_power - to_discard) / (sum_load_power) * 100,
        "静态总投资（亿元）" => cost_initial / 1e8,
        "年度售电收入（亿元）" => sell_buy_electricity_profit / 1e8,
        "年度售氢收入（亿元）" => sell_H2_profit / 1e8,
        "年度运维成本（亿元）" => year_cost_OM / 1e8,
        "年度燃煤成本（亿元）" => cost_coal / 1e8,
        "年度燃气成本（亿元）" => cost_gas / 1e8,
        "年度燃料总成本（亿元）" => (cost_coal + cost_gas) / 1e8,
        "年度制氢用水成本（亿元）" => cost_water / 1e8,
        "度电煤耗（kg/kwh）" => sum_coal == 0 ? 0 : sum_coal / sum_cp_power,
        "度电气耗（Nm3/kwh）" => sum_gas == 0 ? 0 : sum_gas / sum_gp_power,
        "煤电碳排放（万吨）" => sum_coal * fin.coal_factor / 1e7,
        "气电碳排放（万吨）" => sum_gas * fin.gas_factor / 1e7,
        "煤电成本（元/kwh）" => sum_cp_power == 0 ? 0 : cost_coal / sum_cp_power,
        "气电成本（元/kwh）" => sum_gp_power == 0 ? 0 : cost_gas / sum_gp_power,
        "发电度电成本（元/kwh）" => LCOE,
        "年度现金流收益（亿元）" => annual_profit / 1e8,
        "静态总投资回收年限（年）" => ceil(cost_initial / annual_profit),
        "项目净现值NPV（亿元）" => NPV / 1e8,
        "内部收益率IRR" => IRR,
        "目标收益率下投资盈亏平衡年限（年）" => payback
    )
end