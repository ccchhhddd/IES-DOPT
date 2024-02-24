"""
    economic_analysis(machines, fin, powers, ΔE, ::Val{1})

    返回设备的经济评价指标。

- `machines`：设备元组
- `fin`：金融参数
- `powers`：设备发电量、电解量等（储氢能耗忽略）
- `::Val{1}`：用于类型分派, 风光制氢余电上网
- `::Val{2}`：用于类型分派, 风光制氢余电不上网
- `::Val{3}`：用于类型分派, 离网制氢
- `::Val{7}`：用于类型分派, 风光气煤储
- `::Val{8}`：用于类型分派, 风光煤气氢储

"""
# function economicAnalysisData(machines::Tuple, fin::Financial, powers::Tuple, ΔE::Tuple, ::Val{1})
#     # 风机、光伏、电解槽、压缩机
#     pv, wt, ec, hc = machines
#     # 风机发电量、光伏发电量、电解槽电解量、压缩机压缩量
#     wt_power, pv_power, ec_power, hc_power = powers
#     # 风机发电总量、光伏发电总量、电解槽电解总量、压缩机压缩总量
#     sum_pv_power, sum_wt_power, sum_ec_power, sum_hc_power = map(sum, powers)
#     # 风机、光伏总发电
#     sum_RE_power = sum_pv_power + sum_wt_power
#     # 余电上网，网汇购电
#     ΔE_to_grid, ΔE_from_grid, to_discard = ΔE
#     # 风光利用率
#     utilization_rate = 1 - to_discard / sum_RE_power
#     # 电解槽总产氢量
#     sum_mass_H2_load = outputH2Mass(sum_ec_power, ec, 1.0)
#     # 初始投资与替换成本
#     cost_initial = sum(x -> initialInvestment(x) + replacementCost(x, fin), machines)
#     # 运维成本
#     year_cost_OM = sum(annualOperationCost, machines)
#     # 用水成本
#     cost_water = costWater(sum_mass_H2_load, fin)
#     # 买电成本
#     buy_electricity_cost = buyElectricityCost(ΔE_from_grid, fin)
#     # 卖电收益
#     sell_electricity_profit = sellElectricityProfit(ΔE_to_grid, fin)
#     # 售氢收益
#     sell_H2_profit = sellH2Profit(sum_mass_H2_load, fin)
#     # 制氢成本
#     LCOE_H2 = (buy_electricity_cost + cost_water + year_cost_OM) / sum_mass_H2_load
#     # 年现金流收益
#     annual_profit = -year_cost_OM + sell_electricity_profit - buy_electricity_cost + sell_H2_profit - cost_water

#     # 经济性参数
#     NPV, IRR, payback = financial_evaluation(cost_initial, annual_profit, ceil(fin.n_sys);
#         rate_depreciation=fin.rate_depreciation,
#         rate_discount=fin.rate_discount,
#         rate_tax=fin.rate_tax)

#     return OrderedDict(
#         "风电（万千瓦）" => wt.capacity / 1e4,
#         "光伏（万千瓦）" => pv.capacity / 1e4,
#         "制氢（万千瓦）" => ec.capacity / 1e4,
#         "储氢（吨）" => hc.capacity / 1e3,
#         "储氢（万立方米）" => hc.capacity / 1e4 / 0.089,
#         "售氢价格（元/kg）" => fin.H2price_sale,
#         "系统设计寿命（年）" => fin.n_sys,
#         "光伏电量（亿千瓦时）" => sum_pv_power / 1e8,
#         "光伏利用小时数" => sum_pv_power ÷ pv.capacity,
#         "风电电量（亿千瓦时）" => sum_wt_power / 1e8,
#         "风电利用小时数" => sum_wt_power ÷ wt.capacity,
#         "风电光伏电量（亿千瓦时）" => sum_RE_power / 1e8,
#         "风电光伏利用率（%）" => utilization_rate * 100,
#         "风电光伏弃电率（%）" => (1 - utilization_rate) * 100,
#         "风光发电制氢电量（亿千瓦时）" => (sum_RE_power - ΔE_to_grid) / 1e8,
#         "风光上网电量（亿千瓦时）" => abs(ΔE_to_grid) / 1e8,
#         "电网供电量（亿千瓦时）" => abs(ΔE_from_grid) / 1e8,
#         "制氢量（万吨）" => sum_mass_H2_load / 1e7,
#         "制氢用电量（亿千瓦时）" => sum_ec_power / 1e8,
#         "储氢用电量（亿千瓦时）" => sum_hc_power / 1e8,
#         # "制氢设备利用小时数（小时）" => count(>(0), ec_power),
#         "制氢设备利用小时数（小时）" => sum_ec_power / ec.capacity,
#         # "风光电量占制氢用电量比例（%）" => (sum_RE_power - ΔE_to_grid) / (sum_ec_power + sum_hc_power) * 100,
#         "风光电量占制氢用电量比例（%）" => sum_RE_power / (sum_ec_power + sum_hc_power) * 100,
#         "静态总投资（亿元）" => cost_initial / 1e8,
#         "年度售电盈利（亿元）" => sell_electricity_profit / 1e8,
#         "年度买电制氢成本（亿元）" => buy_electricity_cost / 1e8,
#         "年度售氢盈利（亿元）" => sell_H2_profit / 1e8,
#         "年度运维成本（亿元）" => year_cost_OM / 1e8,
#         "年度用水成本（亿元）" => cost_water / 1e8,
#         "制氢价格（元/kg）" => LCOE_H2,
#         "制氢价格（元/方）" => LCOE_H2 * 0.089,
#         # "发电度电成本（元/kWh）" => LCOE,
#         "年度现金流收益（亿元）" => annual_profit / 1e8,
#         "静态总投资回收年限（年）" => ceil(cost_initial / annual_profit),
#         "项目净现值NPV（亿元）" => NPV / 1e8,
#         "内部收益率IRR" => IRR,
#         "目标收益率下投资盈亏平衡年限（年）" => payback
#     )
# end

function economicAnalysisData(machines::Tuple, fin::Financial, powers::Tuple, ΔE::Tuple, ::Val{2})
   
   ########################   能量     #################################

    # 风机、光伏、电解槽、压缩机
    pv, wt, ec, hc, hs, e_es, ca_es = machines
    # 风机发电量、光伏发电量、电解槽电解量、压缩机压缩量
    # wt_power, pv_power, ec_power, hc_power, es_power = powers
    pv_power, wt_power, ec_power, hc_power, es_power, e_es_power, ca_es_power, load_power_base = powers
    # 风机发电总量、光伏发电总量、电解槽电解总量、压缩机压缩总量
    sum_pv_power, sum_wt_power, sum_ec_power, sum_hc_power, sum_es_power, sum_e_es_power, sum_ca_es_power, sum_load_power = map(sum, powers)
    # 总发电装机规模
    total_capacity = wt.capacity + pv.capacity
    # 余电上网，网汇购电
    ΔE_to_grid, ΔE_from_grid, to_discard = ΔE
    # 各电源上网量
    pv_to_grid = sum_pv_power - to_discard * pv.capacity / total_capacity
    wt_to_grid = sum_wt_power - to_discard * wt.capacity / total_capacity
    # 风机、光伏总发电
    sum_RE_power = sum_pv_power + sum_wt_power
    # 风光利用率
    utilization_rate = (pv_to_grid + wt_to_grid) / sum_RE_power

    #########################    财务        ###############################
    # 需求氢气量
    sum_mass_H2_sell = outputH2Mass(sum_load_power, ec, 1.0)
    # 电解槽总产氢量
    sum_mass_H2_load = outputH2Mass(sum_ec_power, ec, 1.0)
    # # 初始投资与替换成本
    # cost_initial = sum(x -> initialInvestment(x) + replacementCost(x, fin), machines)
    # # 运维成本
    # year_cost_OM = sum(annualOperationCost, machines)
    # # 用水成本
    # cost_water = costWater(sum_mass_H2_load, fin)
    # # 买电成本
    # buy_electricity_cost = buyElectricityCost(ΔE_from_grid, fin)
    # # 售氢收益
    # sell_H2_profit = sellH2Profit(sum_mass_H2_load, fin)
    # # 制氢成本
    # LCOE_H2 = (buy_electricity_cost + cost_water + year_cost_OM) / sum_mass_H2_load
    # # 年现金流收益
    # annual_profit = -year_cost_OM - buy_electricity_cost + sell_H2_profit - cost_water
 
    # NPV, IRR, payback = financial_evaluation(cost_initial, annual_profit, ceil(fin.n_sys);
    #     rate_depreciation=fin.rate_depreciation,
    #     rate_discount=fin.rate_discount,
    #     rate_tax=fin.rate_tax)
    machines = pv, wt, ec, hc, hs, e_es, ca_es
    # 计算经济性电量元组
    to_fin_sums = (pv_to_grid, wt_to_grid, sum_ec_power, sum_hc_power, ΔE_from_grid, sum_e_es_power, sum_ca_es_power, sum_load_power)
    # 计算经济性参数：净现值、内部收益率、投资回收年限    
    NPV, IRR, payback = financial_evaluation(fin, machines, to_fin_sums, Val(2))
    # 各类成本
    costs_self, costs_compare, buy_electricity_compare, other_costs = get_cost(fin, machines, to_fin_sums, Val(2))
    # 光伏、风电发电成本
    pv_cost, wt_cost, ec_cost, hc_cost, hs_cost, e_es_cost, ca_es_cost = costs_self
    # 各设备制氢成本比较
    pv_compare, wt_compare, ec_compare, hc_compare, hs_compare, e_es_compare, ca_es_compare = costs_compare
    buy_el_compare = buy_electricity_compare
    # 用水成本、买电成本、总制氢价格、 LCOE_H2、初始投资、年运营成本
    cost_water, buy_electricity_cost, total_cost, LCOE_H2, cost_initial, year_cost_OM = other_costs
    # 综合售氢价格
    sell_H2_price = find_H2_price(fin,machines, to_fin_sums)

    return OrderedDict(
        "输入" => "输入",
        "风电（万千瓦）" => wt.capacity / 1e4,
        "光伏（万千瓦）" => pv.capacity / 1e4,
        "制氢（万千瓦）" => ec.capacity / 1e4,
        "目标制氢量（万吨）" => sum_mass_H2_sell / 1e7,
        "电化学储能（万千瓦）" => e_es.capacity == 0 ? 0 : ceil(Int, (e_es.capacity) / (e_es.hours * 1e4)),
        "电化学储能小时数（时）" => e_es.hours,
        "压缩空气储能（万千瓦）" => ca_es.capacity == 0 ? 0 : ceil(Int, (ca_es.capacity) / (ca_es.hours * 1e4)),
        "压缩空气储能小时数（时）" => ca_es.hours,
        "储氢（吨）" => hs.capacity / 1e3,
        "储氢（万立方米）" => hs.capacity / 1e4 / 0.089,
        # "售氢价格（元/kg）" => fin.H2price_sale,
        # "储氢设备充能阈值" => HT.SoC_cha_thre],
        "系统设计寿命（年）" => fin.n_sys,
        "收益率（%）" => fin.rate_discount * 100,
        "所得税率（%）" => fin.rate_tax * 100,
        "输出" => "输出",
        "实际制氢量（万吨）" => sum_mass_H2_load / 1e7,
        "光伏发电量（亿千瓦时）" => sum_pv_power / 1e8,
        "光伏利用小时数" => pv.capacity == 0 ? 0 : sum_pv_power ÷ pv.capacity,
        "光伏制氢电量（亿千瓦时）" => pv_to_grid /1e8,
        "光伏等效利用小时数" => pv.capacity == 0 ? 0 : pv_to_grid ÷ pv.capacity,
        "风电发电量（亿千瓦时）" => sum_wt_power / 1e8,
        "风电利用小时数" => wt.capacity == 0 ? 0 : sum_wt_power ÷ wt.capacity,
        "风电制氢电量（亿千瓦时）" => wt_to_grid / 1e8,
        "风电等效利用小时数" => wt.capacity == 0 ? 0 : wt_to_grid ÷ wt.capacity,
        "风电光伏发电量（亿千瓦时）" => sum_RE_power / 1e8,
        "风光发电制氢电量（亿千瓦时）" => (pv_to_grid + wt_to_grid) / 1e8,
        "风电光伏利用率（%）" => utilization_rate * 100,
        "风电光伏弃电率（%）" => (1 - utilization_rate) * 100,
        "电化学储能利用小时数" => e_es.capacity == 0 ? 0 : sum(x -> x < 0 ? -x : 0, diff(e_es_power)) ÷ e_es.capacity * e_es.hours,
        "压缩空气储能利用小时数" => ca_es.capacity == 0 ? 0 : sum(x -> x < 0 ? -x : 0, diff(ca_es_power)) ÷ ca_es.capacity * ca_es.hours,
        "网供电量（亿千瓦时）" => abs(sum(ΔE_from_grid)) / 1e8,
        "电解用电量（亿千瓦时）" => sum_ec_power / 1e8,
        "压缩氢气用电量（亿千瓦时）" => sum_hc_power / 1e8,
        "制氢用电量（亿千瓦时）" =>(sum_ec_power + sum_hc_power) / 1e8,
        # "制氢设备利用小时数（小时）" => count(>(0), ec_power),
        "制氢设备利用小时数（小时）" => ec.capacity == 0 ? 0 : sum_ec_power / ec.capacity,
        # "风光电量占制氢用电量比例（%）" => sum_RE_power / (sum_ec_power + sum_hc_power) * 100,
        "风光电量占制氢用电量比例（%）" => (pv_to_grid + wt_to_grid) / (sum_ec_power + sum_hc_power) * 100,
        "网供电量占制氢用电量比例（%）" => abs(sum(ΔE_from_grid)) / (sum_ec_power + sum_hc_power) * 100, 
        "静态总投资（亿元）" => cost_initial / 1e8,
        "年运营成本（亿元）" => year_cost_OM / 1e8,
        # "年度售氢盈利（亿元）" => sell_H2_profit / 1e8,
        "用水成本（亿元）" => cost_water / 1e8,
        "总制氢成本（亿元）" => total_cost / 1e8,
        "光电制氢成本（亿元）" => pv_cost / 1e8,
        "风电制氢成本（亿元）" => wt_cost / 1e8,
        "电解槽制氢成本（亿元）" => ec_cost / 1e8,
        "压缩机制氢成本（亿元）" => hc_cost / 1e8,
        "储氢罐制氢成本（亿元）" => hs_cost / 1e8,
        "电化学储能制氢成本（亿元）" => e_es_cost / 1e8,
        "压缩空气储能制氢成本（亿元）" => ca_es_cost / 1e8,
        "买电制氢成本（亿元）" => buy_electricity_cost / 1e8,
        "综合制氢成本光电占比（%）" => pv_compare / LCOE_H2 * 100,
        "综合制氢成本风电占比（%）" => wt_compare / LCOE_H2 * 100,
        "综合制氢成本电解槽占比（%）" => ec_compare / LCOE_H2 * 100,
        "综合制氢成本压缩机占比（%）" => hc_compare / LCOE_H2 * 100,
        "综合制氢成本储氢罐占比（%）" => hs_compare / LCOE_H2 * 100,
        "综合制氢成本电化学储能占比（%）" => e_es_compare / LCOE_H2 * 100,
        "综合制氢成本压缩空气储能占比（%）" => ca_es_compare / LCOE_H2 * 100,
        "综合制氢成本买电占比（%）" => buy_el_compare / LCOE_H2 * 100,
        "制氢价格（元/kg）" => LCOE_H2,
        "制氢价格（元/方）" => LCOE_H2 * 0.089,
        # "年度现金流收益（亿元）" => annual_profit / 1e8,
        # "发电度电成本（元/kWh）" => LCOE,
        # "静态总投资回收年限（年）" => ceil(cost_initial / annual_profit),
        "给定售氢价格下净现值NPV（亿元）" => NPV / 1e8,
        "给定售氢价格下收益率IRR(%)" => IRR * 100,
        "给定售氢价格下盈亏平衡年限（年）" => payback,                                                
        "综合含税售氢价格（元/kg）（IRR=6%）" => sell_H2_price
    )
end

# function economicAnalysisData(machines::Tuple, fin::Financial, powers::Tuple, ΔE::Tuple, ::Val{3})
#     # 风机、光伏、电解槽、压缩机
#     pv, wt, ec, hc, es = machines
#     # 风机发电量、光伏发电量、电解槽电解量、压缩机压缩量
#     wt_power, pv_power, ec_power, hc_power, es_power = powers
#     # 风机发电总量、光伏发电总量、电解槽电解总量、压缩机压缩总量
#     sum_pv_power, sum_wt_power, sum_ec_power, sum_hc_power, sum_es_power = map(sum, powers)
#     # 风机、光伏总发电
#     sum_RE_power = sum_pv_power + sum_wt_power
#     # 余电上网，网汇购电
#     ΔE_to_grid, ΔE_from_grid, to_discard, load_discount = ΔE
#     # 风光利用率
#     utilization_rate = 1 - to_discard / sum_RE_power
#     # 电解槽总产氢量
#     sum_mass_H2_load = outputH2Mass(sum(ec_power .* load_discount), ec, 1.0)

#     # 初始投资与替换成本
#     cost_initial = sum(x -> initialInvestment(x) + replacementCost(x, fin), machines)
#     # 运维成本
#     year_cost_OM = sum(annualOperationCost, machines)
#     # 用水成本
#     cost_water = costWater(sum_mass_H2_load, fin)
#     # 买卖电收益
#     sell_buy_electricity_profit = sellElectricityProfit(ΔE_to_grid, fin) - buyElectricityCost(ΔE_from_grid, fin)
#     # 售氢收益
#     sell_H2_profit = sellH2Profit(sum_mass_H2_load, fin)

#     # LCOE 制氢成本
#     LCOE_H2 = (-sell_buy_electricity_profit + cost_water + year_cost_OM) / sum_mass_H2_load
#     # 年现金流收益
#     annual_profit = -year_cost_OM + sell_buy_electricity_profit + sell_H2_profit - cost_water

#     # 经济性参数
#     NPV, IRR, payback = financial_evaluation(cost_initial, annual_profit, ceil(fin.n_sys);
#         rate_depreciation=fin.rate_depreciation,
#         rate_discount=fin.rate_discount,
#         rate_tax=fin.rate_tax)

#     return OrderedDict(
#         "风电（万千瓦）" => wt.capacity / 1e4,
#         "光伏（万千瓦）" => pv.capacity / 1e4,
#         "制氢（万千瓦）" => ec.capacity / 1e4,
#         "储能（万千瓦时）" => es.capacity / 1e4,
#         "储氢（吨）" => hc.capacity / 1e3,
#         "储氢（万立方米）" => hc.capacity / 1e4 / 0.089,
#         "售氢价格（元/kg）" => fin.H2price_sale,
#         "系统设计寿命（年）" => fin.n_sys,
#         "光伏电量（亿千瓦时）" => sum_pv_power / 1e8,
#         "光伏利用小时数" => sum_pv_power ÷ pv.capacity,
#         "风电电量（亿千瓦时）" => sum_wt_power / 1e8,
#         "风电利用小时数" => sum_wt_power ÷ wt.capacity,
#         "风电光伏电量（亿千瓦时）" => sum_RE_power / 1e8,
#         "风电光伏利用率（%）" => utilization_rate * 100,
#         "风电光伏弃电率（%）" => (1 - utilization_rate) * 100,
#         "风光发电制氢电量（亿千瓦时）" => (sum_RE_power - to_discard) / 1e8,
#         "风光上网电量（亿千瓦时）" => abs(ΔE_to_grid) / 1e8,
#         "储能利用小时数" => sum_es_power ÷ es.capacity,
#         "电网供电量（亿千瓦时）" => abs(ΔE_from_grid) / 1e8,
#         "制氢量（万吨）" => sum_mass_H2_load / 1e7,
#         "制氢用电量（亿千瓦时）" => sum_ec_power / 1e8,
#         "储氢用电量（亿千瓦时）" => sum_hc_power / 1e8,
#         "制氢设备利用小时数（小时）" => count(>(0), ec_power),
#         "风光电量占制氢用电量比例（%）" => (sum_RE_power - to_discard) / (sum_ec_power + sum_hc_power) * 100,
#         "静态总投资（亿元）" => cost_initial / 1e8,
#         "年度售电盈利（亿元）" => sell_buy_electricity_profit / 1e8,
#         "年度售氢盈利（亿元）" => sell_H2_profit / 1e8,
#         "年度运维成本（亿元）" => year_cost_OM / 1e8,
#         "年度用水成本（亿元）" => cost_water / 1e8,
#         "制氢价格（元/kg）" => LCOE_H2,
#         "制氢价格（元/方）" => LCOE_H2 * 0.089,
#         "年度现金流收益（亿元）" => annual_profit / 1e8,
#         "静态总投资回收年限（年）" => ceil(cost_initial / annual_profit),
#         "项目净现值NPV（亿元）" => NPV / 1e8,
#         "内部收益率IRR" => IRR,
#         "目标收益率下投资盈亏平衡年限（年）" => payback
#     )
# end

function economicAnalysisData(machines::Tuple, fin::Financial, powers::Tuple, ΔE::Tuple, ::Val{7})

    ########################   能量     #################################

    # 风机、光伏、储能、煤电、气电
    pv, wt, p_es, ca_es, e_es, cp, gp = machines
    # 光伏发电量、风机发电量、煤电发电量、气电发电量、负荷（列表）
    pv_power, wt_power, cp_power, gp_power, load_power, es_power, p_es_power, ca_es_power, e_es_power = powers
    # 光伏发电总量、风机发电总量、煤电发电总量、气电发电总量
    sum_pv_power, sum_wt_power, sum_cp_power, sum_gp_power, sum_load_power, sum_es_power, sum_p_es_power, sum_ca_es_power, sum_e_es_power = map(sum, powers)
    # 总装机规模
    total_capacity = sum(x -> x.capacity, machines)
    # 电上网
    ΔE_to_grid, ΔE_from_grid, to_discard = ΔE
    # 各电源上网量
    pv_to_grid = sum_pv_power - to_discard * pv.capacity / total_capacity
    wt_to_grid = sum_wt_power - to_discard * wt.capacity / total_capacity
    cp_to_grid = sum_cp_power - to_discard * cp.capacity / total_capacity
    gp_to_grid = sum_gp_power - to_discard * gp.capacity / total_capacity
    # 风机、光伏总发电
    sum_RE_power = sum_pv_power + sum_wt_power
    # 风光利用率
    utilization_rate = (pv_to_grid + wt_to_grid) / (sum_pv_power + sum_wt_power)
    # utilization_rate = 1 - to_discard * (wt.capacity + pv.capacity) / (wt.capacity + pv.capacity + cp.capacity + gp.capacity) / sum_load_power

    #########################    财务        ###############################
    # 计算经济性电量元组
    to_fin_sums = (pv_to_grid, wt_to_grid, cp_to_grid, gp_to_grid, sum_load_power - ΔE_from_grid)
    # 计算经济性参数：净现值、内部收益率、投资回收年限 
    NPV, IRR, payback = financial_evaluation(fin, machines, to_fin_sums, Val(7))
    # 各类成本
    costs_self, costs_compare, other_costs = get_cost(fin, machines, to_fin_sums, Val(7))
    # 各电源发电成本
    pv_cost, wt_cost, cp_cost, gp_cost = costs_self
    # 各电源发电成本比较
    pv_compare, wt_compare, p_es_compare, ca_es_compare, e_es_compare, cp_compare, gp_compare = costs_compare
    # 综合成本、初始投资、运维成本、煤电成本、气电成本
    LCOE, cost_initial, year_cost_OM = other_costs
    # 计算综合上网电价
    sell_price = find_price(fin, machines, to_fin_sums)

    return OrderedDict(
        "输入" => "输入",
        "风电（万千瓦）" => wt.capacity / 1e4,
        "光伏（万千瓦）" => pv.capacity / 1e4,
        # "总储能（万千瓦时）" => (p_es.capacity + ca_es.capacity + e_es.capacity) / 1e4,
        "抽水蓄能（万千瓦）" => p_es.capacity == 0 ? 0 : ceil(Int, (p_es.capacity) / (p_es.hours * 1e4)),
        "抽水蓄能小时数（时）" => p_es.hours,
        "压缩空气储能（万千瓦）" => ca_es.capacity == 0 ? 0 : ceil(Int, (ca_es.capacity) / (ca_es.hours * 1e4)),
        "压缩空气储能小时数（时）" => ca_es.hours,
        "电化学储能（万千瓦）" => e_es.capacity == 0 ? 0 : ceil(Int, (e_es.capacity) / (e_es.hours * 1e4)),
        "电化学储能小时数（时）" => e_es.hours,
        "煤电（万千瓦）" => cp.capacity / 1e4,
        "气电（万千瓦）" => gp.capacity / 1e4,
        "系统设计寿命（年）" => fin.n_sys,
        "外送总电量（亿千瓦时）" => sum_load_power / 1e8,
        "外送通道利用小时数" => sum_load_power ÷ maximum(load_power),
        "煤价（￥/kg）" => fin.price_coal_per_kg,
        "气价（￥/Nm3）" => fin.price_gas_per_Nm3,
        "收益率（%）" => fin.rate_discount * 100,
        "所得税率（%）" => fin.rate_tax * 100,
        "输出" => "输出",
        "光伏发电量（亿千瓦时）" => sum_pv_power / 1e8,
        "光伏利用小时数" => pv.capacity == 0 ? 0 : sum_pv_power ÷ pv.capacity,
        "光伏上网电量（亿千瓦时）" => pv_to_grid / 1e8,
        "光伏等效利用小时数" => pv.capacity == 0 ? 0 : pv_to_grid ÷ pv.capacity,
        "风电发电量（亿千瓦时）" => sum_wt_power / 1e8,
        "风电利用小时数" => wt.capacity == 0 ? 0 : sum_wt_power ÷ wt.capacity,
        "风电上网电量（亿千瓦时）" => wt_to_grid / 1e8,
        "风电等效利用小时数" => wt.capacity == 0 ? 0 : wt_to_grid ÷ wt.capacity,
        "风电光伏电量（亿千瓦时）" => sum_RE_power / 1e8,
        "风电光伏利用率（%）" => utilization_rate * 100,
        "风电光伏弃电率（%）" => (1 - utilization_rate) * 100,
        "风光上网电量（亿千瓦时）" => (pv_to_grid + wt_to_grid) / 1e8,
        "抽水蓄能利用小时数" => p_es.capacity == 0 ? 0 : sum(x -> x < 0 ? -x : 0, diff(p_es_power)) ÷ p_es.capacity * p_es.hours,
        "压缩空气储能利用小时数" => ca_es.capacity == 0 ? 0 : sum(x -> x < 0 ? -x : 0, diff(ca_es_power)) ÷ ca_es.capacity * ca_es.hours,
        "电化学储能利用小时数" => e_es.capacity == 0 ? 0 : sum(x -> x < 0 ? -x : 0, diff(e_es_power)) ÷ e_es.capacity * e_es.hours,
        "主网网汇量(网汇量)（亿千瓦时）" => abs(ΔE_from_grid) / 1e8,
        "主网支撑电量占比（%）" => abs(ΔE_from_grid / sum_load_power) * 100,
        "煤电发电量（亿千瓦时）" => sum_cp_power / 1e8,
        "煤电小时利用数" => cp.capacity == 0 ? 0 : sum_cp_power ÷ cp.capacity,
        "气电发电量（亿千瓦时）" => sum_gp_power / 1e8,
        "气电小时利用数" => gp.capacity == 0 ? 0 : sum_gp_power ÷ gp.capacity,
        "新能源电量外送通道占比（%）" => (pv_to_grid + wt_to_grid) / sum_load_power * 100,
        "度电煤耗（kg/kwh）" => sum_cp_power == 0 ? 0 : consumefuel(cp),
        "度电气耗（Nm3/kwh）" => sum_gp_power == 0 ? 0 : consumefuel(gp),
        "综合度电碳排放（kg/kWh）" => sum_load_power == 0 ? 0 : (sum_cp_power * fin.coal_factor + sum_gp_power * fin.gas_factor) / sum_load_power,
        "静态总投资（亿元）" => cost_initial / 1e8,
        "年运营成本（亿元）" => year_cost_OM / 1e8,
        "光电度电成本（元/kwh）" => pv_cost ,
        "风电度电成本（元/kwh）" => wt_cost,
        "煤电度电成本（元/kwh）" => cp_cost,
        "气电度电成本（元/kwh）" => gp_cost,
        "综合度电成本（元/kwh）" => LCOE,
        "综合度电成本光电占比（%）" => pv_compare / LCOE * 100,
        "综合度电成本风电占比（%）" => wt_compare / LCOE * 100,
        "综合度电成本煤电占比（%）" => cp_compare / LCOE * 100,
        "综合度电成本气电占比（%）" => gp_compare / LCOE * 100,
        "综合度电成本抽水蓄能占比（%）" => p_es_compare / LCOE * 100,
        "综合度电成本压缩空气储能占比（%）" => ca_es_compare / LCOE * 100,
        "综合度电成本电化学储能占比（%）" => e_es_compare / LCOE * 100,
        "给定上网电价下净现值NPV（亿元）" => NPV / 1e8,
        "给定上网电价下收益率IRR（%）" => IRR * 100,
        "给定上网电价下盈亏平衡年（年）" => payback,
        # "静态总投资回收年限（年）" => ceil(cost_initial / annual_profit),
        "综合含税上网电价（元/kWh）（IRR=6%）" => sell_price,
    )
end

# Val{8} 停止于 2023-08-25版本，运行逻辑未修正
# function economicAnalysisData(machines::Tuple, fin::Financial, powers::Tuple, ΔE::Tuple, ::Val{8})
#     # 风机、光伏、储能、煤电、气电、电解槽、压缩储氢
#     pv, wt, ec, hc, es, cp, gp = machines
#     # 风机发电量、光伏发电量、煤电发电量、气电发电量、负荷、电解槽耗电量（列表）
#     wt_power, pv_power, cp_power, gp_power, load_power, ec_power, es_power = powers
#     # 风机发电总量、光伏发电总量、煤电发电总量、气电发电总量、负荷总量、电解槽耗电总量
#     sum_pv_power, sum_wt_power, sum_cp_power, sum_gp_power, sum_load_power, sum_ec_power, sum_es_power = map(sum, powers)
#     # 风机、光伏总发电
#     sum_RE_power = sum_pv_power + sum_wt_power
#     # 余电上网（该场景下0）、网汇购电（该场景下0）、弃电
#     ΔE_to_grid, ΔE_from_grid, to_discard = ΔE
#     # 风光利用率
#     utilization_rate = 1 - to_discard / sum_RE_power
#     # 初始投资与替换成本
#     cost_initial = sum(x -> initialInvestment(x) + replacementCost(x, fin), machines)
#     # 运维成本
#     year_cost_OM = sum(annualOperationCost, machines)
#     # 买卖电收益
#     sell_buy_electricity_profit = sellElectricityProfit(sum_load_power, fin) - buyElectricityCost(ΔE_from_grid, fin)
#     # 年燃煤成本
#     cost_coal = costCoal(sum_cp_power, cp, fin)
#     # 煤耗（kg）
#     sum_coal = cost_coal / fin.price_coal_per_kg
#     # 年燃气成本
#     cost_gas = costGas(sum_gp_power, gp, fin)
#     # 气耗（m³）
#     sum_gas = cost_gas / fin.price_gas_per_Nm3
#     # 电解槽总产氢量
#     sum_mass_H2_load = sum(ec.load)
#     # 用水成本
#     cost_water = costWater(sum_mass_H2_load, fin)
#     # 售氢收益
#     sell_H2_profit = sellH2Profit(sum_mass_H2_load, fin)
#     # # LCOE 发电度电成本（元/kWh）
#     LCOE = (cost_coal + cost_gas + year_cost_OM) / sum_load_power
#     # 年现金流收益
#     annual_profit = -year_cost_OM + sell_buy_electricity_profit - cost_coal - cost_gas + sell_H2_profit - cost_water

#     # 经济性参数
#     NPV, IRR, payback = financial_evaluation(cost_initial, annual_profit, ceil(fin.n_sys);
#         rate_depreciation=fin.rate_depreciation,
#         rate_discount=fin.rate_discount,
#         rate_tax=fin.rate_tax)


#     return OrderedDict(
#         "风电（万千瓦）" => wt.capacity / 1e4,
#         "光伏（万千瓦）" => pv.capacity / 1e4,
#         "储能（万千瓦时）" => es.capacity / 1e4,
#         "煤电（万千瓦）" => cp.capacity / 1e4,
#         "气电（万千瓦）" => gp.capacity / 1e4,
#         "系统设计寿命（年）" => fin.n_sys,
#         "光伏电量（亿千瓦时）" => sum_pv_power / 1e8,
#         "光伏利用小时数" => sum_pv_power ÷ pv.capacity,
#         "风电电量（亿千瓦时）" => sum_wt_power / 1e8,
#         "风电利用小时数" => sum_wt_power ÷ wt.capacity,
#         "风电光伏电量（亿千瓦时）" => sum_RE_power / 1e8,
#         "风电光伏利用率（%）" => utilization_rate * 100,
#         "风电光伏弃电率（%）" => (1 - utilization_rate) * 100,
#         "风光上网电量（亿千瓦时）" => (sum_RE_power - to_discard) / 1e8,
#         "储能利用小时数" => sum_es_power ÷ es.capacity,
#         "电网供电量（亿千瓦时）" => abs(ΔE_from_grid) / 1e8,
#         "煤电发电量（亿千瓦时）" => sum_cp_power / 1e8,
#         "产氢用电量（亿千瓦时）" => sum_ec_power / 1e8,
#         "产氢量（吨）" => sum_mass_H2_load / 1e3,
#         "气电发电量（亿千瓦时）" => sum_gp_power / 1e8,
#         "外送总电量（亿千瓦时）" => sum_load_power / 1e8,
#         "风光电量占总发电量比例（%）" => (sum_RE_power - to_discard) / (sum_load_power) * 100,
#         "静态总投资（亿元）" => cost_initial / 1e8,
#         "年度售电收入（亿元）" => sell_buy_electricity_profit / 1e8,
#         "年度售氢收入（亿元）" => sell_H2_profit / 1e8,
#         "年度运维成本（亿元）" => year_cost_OM / 1e8,
#         "年度燃煤成本（亿元）" => cost_coal / 1e8,
#         "年度燃气成本（亿元）" => cost_gas / 1e8,
#         "年度燃料总成本（亿元）" => (cost_coal + cost_gas) / 1e8,
#         "年度制氢用水成本（亿元）" => cost_water / 1e8,
#         "度电煤耗（kg/kwh）" => sum_coal == 0 ? 0 : sum_coal / sum_cp_power,
#         "度电气耗（Nm3/kwh）" => sum_gas == 0 ? 0 : sum_gas / sum_gp_power,
#         "煤电碳排放（万吨）" => sum_coal * fin.coal_factor / 1e7,
#         "气电碳排放（万吨）" => sum_gas * fin.gas_factor / 1e7,
#         "煤电成本（元/kwh）" => sum_cp_power == 0 ? 0 : cost_coal / sum_cp_power,
#         "气电成本（元/kwh）" => sum_gp_power == 0 ? 0 : cost_gas / sum_gp_power,
#         "发电度电成本（元/kwh）" => LCOE,
#         "年度现金流收益（亿元）" => annual_profit / 1e8,
#         "静态总投资回收年限（年）" => ceil(cost_initial / annual_profit),
#         "项目净现值NPV（亿元）" => NPV / 1e8,
#         "内部收益率IRR" => IRR,
#         "目标收益率下投资盈亏平衡年限（年）" => payback
#     )
# end