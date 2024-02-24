"""
返回设备的人员数
"""
staff_number(machine::RenewableEnergyMachine) = machine.capacity > 0.0 ? machine.staff_number : 0

function cp_staff_number(cp::CoalPower)
    if cp.capacity >200.0
        return 350
    elseif 0.0 < cp.capacity <= 200.0
        return 250
    elseif cp.capacity == 0.0
        return 0
    end
end
"""
返回设备的初始投资
"""
initialInvestment(machine::RenewableEnergyMachine) = machine.cost_initial * machine.capacity

"""
返回设备的替换投资
"""
replaceInvestment(machine::RenewableEnergyMachine) = machine.cost_replace * machine.capacity

"""
返回设备的年运维成本
"""
annualOperationCost(machine::RenewableEnergyMachine) = machine.cost_OM * machine.capacity

"""
返回设备的更换成本

- `machine` 设备
- `fin` 财务参数
"""
replacementCost(machine::RenewableEnergyMachine, fin::Financial) = fin.n_sys > machine.life_year ? machine.cost_replace * machine.capacity * ceil(fin.n_sys / machine.life_year) : 0

"""
返回设备的总成本

- `machine` 设备
- `fin` 财务参数
"""
totalCost(machine::RenewableEnergyMachine, fin::Financial) = initialInvestment(machine) + operationCost(machine, fin) + replacementCost(machine, fin)

"""
返回设备的年发电收益

- `capacity` 设备容量
- `fin` 财务参数
"""
sellElectricityProfit(capacity, fin::Financial) = fin.price_to_grid * abs(capacity)

"""
返回买电成本

- `capacity` 买电量
- `fin` 财务参数
"""
buyElectricityCost(capacity, fin::Financial) = fin.price_from_grid * abs(capacity)

function buyElectricityCost(capacity::Vector, fin::Financial) 
    cost = 0
    capacity = abs.(capacity)
    for i in 0:364
        cost += fin.peak_price_from_grid * (capacity[8+24*i] + capacity[9+24*i] + capacity[10+24*i] + capacity[18+24*i] + capacity[19+24*i] + capacity[20+24*i] + capacity[21+24*i] + capacity[22+24*i] + capacity[23+24*i])
                fin.valley_price_from_grid * (capacity[1+24*i] + capacity[2+24*i] + capacity[3+24*i] + capacity[4+24*i] + capacity[5+24*i] + capacity[6+24*i] + capacity[7+24*i])
                fin.flat_price_from_grid * (capacity[11+24*i] + capacity[12+24*i] + capacity[13+24*i] + capacity[14+24*i] + capacity[15+24*i] + capacity[16+24*i] + capacity[17+24*i] + capacity[24+24*i])
    end
    return cost
end

"""
返回氢气销售收益

- `capacity` 卖氢量
- `fin` 财务参数
"""
sellH2Profit(capacity, fin::Financial) = fin.H2price_sale * capacity


"""
返回年用水成本

- `capacity` 水量
- `fin` 财务参数
"""
costWater(capacity, fin::Financial) = fin.cost_water_per_kg_H2 * capacity

"""
返回年用煤成本

- `capacity` 煤电发电量
- `cp` 煤电参数
- `fin` 财务参数
"""
costCoal(capacity, cp::CoalPower, fin::Financial) = capacity * 3.6 / (cp.η_inverter * cp.η * cp.lhv_coal) * fin.price_coal_per_kg

"""
返回年用气成本

- `capacity` 气电发电量
- `gp` 气电参数
- `fin` 财务参数
"""
costGas(capacity, gp::GasPower, fin::Financial) = capacity * 3.6 / (gp.η_inverter * gp.η * gp.lhv_gas) * fin.price_gas_per_Nm3

"""
返回度电燃料消耗

- `p` 参数
"""
consumefuel(p::Union{CoalPower,GasPower}) = p isa CoalPower ? 3.6 / (p.η_inverter * p.η * p.lhv_coal) : 3.6 / (p.η_inverter * p.η * p.lhv_gas)

"""
返回设备的资金回收系数
"""
crf(fin::Financial) = (fin.r * (1 + fin.r)^fin.n_sys) / ((1 + fin.r)^fin.n_sys - 1)

"""
返回设备的财务评价指标。

# 参数
- `cost_initial`：初始投资，包括置换成本
- `year_profit`：年盈利收入
- `operation_life`：运营期限
- `rate_depreciation`：折旧率
- `rate_discount`：贴现率
- `rate_tax`：税率

# 返回值
- `NPV`：净现值
- `IRR`：内部收益率
- `payback`：投资回收期
"""
function financial_evaluation(cost_initial, year_profit, operation_life;
    rate_depreciation=0.05, rate_discount=0.06, rate_tax=0.25)

    # operation_life = Int(operation_life)
    # construction_life = Int(construction_life)
    # annual_investment_cost = vcat(cost_initial / construction_life .* ones(construction_life), zeros(operation_life))
    # annual_revenue = vcat(zeros(construction_life), year_profit .* ones(operation_life))
    # annual_operating_cost = vcat(zeros(construction_life), (year_cost_oper + year_cost_main) .* ones(operation_life))
    # depreciation = vcat(zeros(construction_life), cost_initial * rate_depreciation .* ones(operation_life)) # 折旧
    # cashflows = @. (annual_revenue - depreciation - annual_operating_cost) * (1 - rate_tax) - annual_investment_cost
    # cashflows = @. (annual_revenue - annual_operating_cost) * (1 - rate_tax) - annual_investment_cost

    # todo 建设期2年
    cashflows = append!([-cost_initial ÷ 2, -cost_initial ÷ 2], (year_profit * (1 - rate_tax) for _ in 1:Int(operation_life)))
    times = collect(0:length(cashflows)-1)
    NPV = present_value(rate_discount, cashflows, times)
    IRR = irr(cashflows)
    payback = breakeven(0, cashflows, times)
    IRR = isnothing(IRR) ? -1 : rate(IRR)
    payback = isnothing(payback) ? -1 : payback
    return NPV, IRR, payback
end

"""
返回设备的财务评价指标。

# 参数
- `fin`：财务参数
- `machines`：设备列表，顺序为(pv, wt, ec, hc, e_es, ca_es)
- `sums`：功率，顺序为(pv_to_grid, wt_to_grid, sum_ec_power, sum_hc_power, ΔE_from_grid, sum_e_es_power, sum_ca_es_power)

# 返回值
- `NPV`：净现值
- `IRR`：内部收益率
- `payback`：投资回收期
"""
function financial_evaluation(fin::Financial, machines::Tuple, sums::Tuple, ::Val{2})
    cashflows = get_cash_flow(fin, machines, sums, Val(2))
    NPV = present_value(fin.rate_discount, cashflows)
    IRR = irr(cashflows)
    payback = breakeven(0, cashflows)
    # 检查IRR, payback是否有值
    IRR = isnothing(IRR) ? -1 : rate(IRR)
    payback = isnothing(payback) ? -1 : payback
    return NPV, IRR, payback
end


"""
返回设备的财务评价指标。

# 参数
- `fin`：财务参数
- `machines`：设备列表，顺序为(pv, wt, p_es, ca_es, e_es, cp, gp)
- `sums`：总功率，顺序为(pv, wt, cp, gp, load, es, p_es, ca_es, e_es)

# 返回值
- `NPV`：净现值
- `IRR`：内部收益率
- `payback`：投资回收期
"""
function financial_evaluation(fin::Financial, machines::Tuple, sums::Tuple, ::Val{7})
    cashflows = get_cash_flow(fin, machines, sums, Val(7))
    NPV = present_value(fin.rate_discount, cashflows)
    IRR = irr(cashflows)
    payback = breakeven(0, cashflows)
    # 检查IRR, payback是否有值
    IRR = isnothing(IRR) ? -1 : rate(IRR)
    payback = isnothing(payback) ? -1 : payback
    return NPV, IRR, payback
end

"""
计算满足年度现金流收益的售电价格

# 参数
- `cost_initial`：初始投资，包括置换成本
- `year_cost`：年成本（运营+燃料）
- `sum_load`：卖电量
- `operation_life`：运营期限
- `rate_depreciation`：折旧率
- `rate_discount`：贴现率
- `rate_tax`：税率

# 返回值
- `sell_price`：符合正收益要求的卖电电价
"""
function find_price(cost_initial, year_cost, sum_load, operation_life;
    rate_depreciation=0.05, rate_discount=0.06, rate_tax=0.25)

    sell_price = 0.3
    cashflows = append!([-cost_initial], ((sum_load * sell_price - year_cost) * (1 - rate_tax) for _ in 1:Int(operation_life)))
    IRR = irr(cashflows)

    while isnothing(IRR) || rate(IRR) < rate_discount
        sell_price += 0.01
        cashflows = append!([-cost_initial], ((sum_load * sell_price - year_cost) * (1 - rate_tax) for _ in 1:Int(operation_life)))
        IRR = irr(cashflows)
    end

    return sell_price
end

"""
计算满足年度现金流收益的售氢价格

# 参数
- `fin`：财务参数
- `machines`：设备列表，顺序为(pv, wt, ec, hc, e_es, ca_es)
- `sums`：功率，顺序为(pv_to_grid, wt_to_grid, sum_ec_power, sum_hc_power, ΔE_from_grid, sum_e_es_power, sum_ca_es_power)

# 返回值
- `sell_H2_price`：符合正收益要求的售氢电价
"""

function find_H2_price(fin::Financial, machines::Tuple, sums::Tuple)
    left_price = 50.0
    right_price = 20.0
    while left_price - right_price >= 5e-4
        fin.H2price_sale = (left_price + right_price) / 2
        cashflows = get_cash_flow(fin, machines, sums, Val(2))
        IRR = irr(cashflows)
        if isnothing(IRR) || rate(IRR) < fin.rate_discount
            right_price = fin.H2price_sale
        else
            left_price = fin.H2price_sale
        end
    end
    return round(fin.H2price_sale, digits=4)
end

"""
计算满足年度现金流收益的售电价格

# 参数
- `fin`：财务参数
- `machines`：设备列表，顺序为(pv, wt, p_es, ca_es, e_es, cp, gp)
- `sums`：总功率，顺序为(pv, wt, cp, gp, load, es, p_es, ca_es, e_es)

# 返回值
- `sell_price`：符合正收益要求的卖电电价
"""
function find_price(fin::Financial, machines::Tuple, sums::Tuple)
    left_price = 1.0
    right_price = 0.1
    while left_price - right_price >= 5e-4
        fin.price_to_grid = (left_price + right_price) / 2
        cashflows = get_cash_flow(fin, machines, sums, Val(7))
        IRR = irr(cashflows)
        if isnothing(IRR) || rate(IRR) < fin.rate_discount
            right_price = fin.price_to_grid
        else
            left_price = fin.price_to_grid
        end
    end
    return round(fin.price_to_grid, digits=4)
end

"""
返回建设期与运行期的建设投资列表

# 参数
- `fin`：财务参数
- `machines`：设备列表，顺序为(pv, wt, ec, hc, e_es, ca_es)
- `sums`：功率，顺序为(pv_to_grid, wt_to_grid, sum_ec_power, sum_hc_power, ΔE_from_grid, sum_e_es_power, sum_ca_es_power)
- `::Val{2}`：风光制氢余电不上网

# 返回值
- `cash_flow`：现金流列表
"""
function get_cash_flow(fin::Financial, machines::Tuple, sums::Tuple, ::Val{2})
   # 建设期投资列表、运行期投资列表
   construction_year_list = zeros(2)
   operation_year_list = zeros(round(Int, fin.n_sys))
   # 获得设备的初始投资
   pv_investment, wt_investment, ec_investment, hc_investment, hs_investment, e_es_investment, ca_es_investment = map(initialInvestment, machines)
   # 建设期分期投资建设
   construction_year_list[1] -= 0.5 * (ec_investment + hc_investment + hs_investment + e_es_investment + ca_es_investment)
   construction_year_list[2] -= 0.5 * (ec_investment + hc_investment + hs_investment + e_es_investment + ca_es_investment) + 1.0 * (pv_investment + wt_investment)
   # 运行期替换投资与回收固定资产余值
    for machine in machines
        replace_y = round(Int, machine.life_year)
        # 余值=建设成本×残值率
        replace_y <= fin.n_sys && (operation_year_list[replace_y] += fin.n_sys/ machine.life_year * initialInvestment(machine) * 0.05) * fin.rate_tax
        # 替换成本
        replace_y <= fin.n_sys - 1 && (operation_year_list[replace_y+1] -= replaceInvestment(machine))
    end
    pv, wt, ec, hc, hs, e_es, ca_es = machines
    sum_pv_power, sum_wt_power, sum_ec_power, sum_hc_power, ΔE_from_grid, sum_e_es_power, sum_ca_es_power, sum_load_power = sums
    # 风电、光伏、电解槽、储氢罐、电化学储能、压缩空气储能投资与容量
    INV = (pv_investment, wt_investment, ec_investment, hc_investment, hs_investment, e_es_investment, ca_es_investment)
    CAP = (pv.capacity, wt.capacity, ec.capacity, hc.capacity, hs.capacity, e_es.capacity, ca_es.capacity)

    # 风电、光伏、电解槽、压缩机、储氢罐、电化学储能、压缩空气储能折旧年限
    year_depreciation = (20.0, 20.0, 20.0, 20.0, 20.0, 10.0, 20.0)
    # 折旧率
    rate_depreciation = 1 ./ year_depreciation

    ############# 生产成本=材料费+用水成本+买电成本+人员费用+维护及修理费+其他制造费用 #############
    # 材料费
    material_cost = sum((8.0, 15.0, 0.0, 0.0, 0.0, 15.0, 0.0) .* CAP)
    # 用水成本
    sum_mass_H2_load = outputH2Mass(sum_ec_power, ec, 1.0) # 制氢量
    cost_water = costWater(sum_mass_H2_load, fin)
    #买电成本
    buy_electricity_cost = buyElectricityCost(ΔE_from_grid, fin)
    # 人员费用
    pv.staff_number, wt.staff_number, ec.staff_number, hc.staff_number, hs.staff_number, e_es.staff_number, ca_es.staff_number = map(staff_number, machines)
    staff_cost = sum((pv.staff_number, wt.staff_number, ec.staff_number, hc.staff_number, hs.staff_number, e_es.staff_number, ca_es.staff_number) .* 15e4)
    # 维护及修理费
    repair_cost = sum((1e-2, 1e-2, 3e-2, 3e-2, 3e-2, 1e-2, 1e-2) .* INV)
    # 其他制造费用
    other_cost = sum((5.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0) .* CAP)
    # 生产成本
    product_cost = material_cost + cost_water + buy_electricity_cost + staff_cost + repair_cost + other_cost

    #############   管理费用=保险费+其他管理费用  #############
    # 其他管理费用
    other_manage_cost = sum((10.0, 15.0, 15.0, 0.0, 0.0, 15.0, 0.0) .* CAP) 
    # 固定的经营成本
    operation_cost_fix = product_cost + other_manage_cost
    # 经营收入
    # operation_incomes = sellH2Profit(sum_mass_H2_load, fin)
    sum_mass_H2_sell = outputH2Mass(sum_load_power, ec, 1.0)
    operation_incomes = sellH2Profit(sum_mass_H2_sell, fin)
    # 销售税额 = 商品单价 × 销售量 × 增值税税率
    tax_sell = operation_incomes * 0.13
    # 进项成本税额
    tax_in = material_cost * 0.13

    for year in 1:round(Int, fin.n_sys)
        # 保险费 = 固定资产净值 × 保险费率
        insurance_cost = sum(map(x -> max(x[1] * 0.05, x[1] * (1 - x[2] * year)), zip(INV, rate_depreciation))) * 0.25e-2
        # 经营成本 = 固定的经营成本 + 保险费
        operation_cost = operation_cost_fix + insurance_cost
        # 增值税 = 销售税额 - 成本进项税额
        tax_add = tax_sell - tax_in
        tax_add = tax_add < 0 ? 0 : tax_add
        # 营业税金及附加
        tax_business = tax_add * 0.12
        # 所得税前净现金流 = 现金流入 - 现金流出
        net_cash_flow = (operation_incomes + tax_sell)- (operation_cost + tax_in + tax_add + tax_business)
        #所得税税率
        income_tax_rate = year < 4 ? 0.0 : (year < 7 ? fin.rate_tax / 2 : fin.rate_tax)
        #调整所得税
        income_tax = (net_cash_flow - sum(map(x -> x[2] >= year ? INV[x[1]] * rate_depreciation[x[1]] : 0, enumerate(year_depreciation)))) * income_tax_rate
        # 所得税后净现金流
        operation_year_list[year] += net_cash_flow - income_tax
    end
    return vcat(construction_year_list, operation_year_list)
end


"""
返回建设期与运行期的建设投资列表

# 参数
- `fin`：财务参数
- `machines`：设备列表，顺序为(pv, wt, p_es, ca_es, e_es, cp, gp)
- `sums`：总功率，顺序为(pv, wt, cp, gp, load)
- `::Val{7}`：风光气煤储能系统

# 返回值
- `cash_flow`：现金流列表
"""
function get_cash_flow(fin::Financial, machines::Tuple, sums::Tuple, ::Val{7})
    # 建设期投资列表、运行期投资列表
    construction_year_list = zeros(3)
    operation_year_list = zeros(round(Int, fin.n_sys))
    # 获得设备的初始投资
    pv_investment, wt_investment, p_es_investment, ca_es_investment, e_es_investment, cp_investment, gp_investment = map(initialInvestment, machines)
    # 建设期分期投资建设 
    construction_year_list[1] -= 0.3 * (cp_investment + p_es_investment)
    construction_year_list[2] -= 0.3 * (cp_investment + p_es_investment) + 0.5 * (gp_investment + e_es_investment + ca_es_investment)
    construction_year_list[3] -= 0.3 * (cp_investment + p_es_investment) + 0.5 * (gp_investment + e_es_investment + ca_es_investment) + 1.0 * (pv_investment + wt_investment)
    # 运行期替换投资与回收固定资产余值
    for machine in machines
        replace_y = round(Int, machine.life_year)
        # 余值=建设成本×残值率
        replace_y <= fin.n_sys && (operation_year_list[replace_y] += fin.n_sys/ machine.life_year * initialInvestment(machine) * 0.05) * fin.rate_tax
        # 替换成本
        replace_y <= fin.n_sys - 1 && (operation_year_list[replace_y+1] -= replaceInvestment(machine))
    end
    pv, wt, p_es, ca_es, e_es, cp, gp = machines
    sum_pv_power, sum_wt_power, sum_cp_power, sum_gp_power, sum_load_power = sums
    # 各设备投资与容量
    INV = (pv_investment, wt_investment, p_es_investment, ca_es_investment, e_es_investment, cp_investment, gp_investment)
    CAP = (pv.capacity, wt.capacity, p_es.capacity, ca_es.capacity, e_es.capacity, cp.capacity, gp.capacity)

    # 光伏衰减
    # pv_depreciation = fill(0.45e-2, round(Int, fin.n_sys))
    # pv_depreciation[1] = 0
    # pv_depreciation[2] = 2e-2
    # 折旧年限
    year_depreciation = (20.0, 20.0, 20.0, 20.0, 10.0, 20.0, 10.0)
    # 折旧率
    rate_depreciation = 1 ./ year_depreciation
    
    ############# 生产成本=材料费+燃料费+人员费用+维护及修理费+其他制造费用 #############
    # 材料费
    material_cost = sum((8.0, 15.0, 0.0, 0.0, 15.0, 0.0, 8.0) .* CAP)
    # 燃料费
    coal_cost = costCoal(sum_cp_power, cp, fin)
    gas_cost = costGas(sum_gp_power, gp, fin)
    fuel_cost = coal_cost + gas_cost
    # 人员费用
    machines = (pv, wt, p_es, ca_es, e_es, gp )
    pv.staff_number, wt.staff_number, p_es.staff_number, ca_es.staff_number, e_es.staff_number, gp.staff_number = map(staff_number, machines)
    cp.staff_number = cp_staff_number(cp)
    # cp.staff_number = cp.capacity >200.0 ? 350 : 250
    staff_cost = sum((pv.staff_number, wt.staff_number, p_es.staff_number, ca_es.staff_number, e_es.staff_number, cp.staff_number, gp.staff_number) .* 15e4)
    # 维护及修理费
    repair_cost = sum((1e-2, 1e-2, 1e-2, 1e-2, 1e-2, 3e-2, 3e-2) .* INV)
    # 其他制造费用
    other_cost = sum((5.0, 10.0, 10.0, 10.0, 10.0, 10.0, 4.0) .* CAP)
    # 生产成本
    product_cost = material_cost + fuel_cost + staff_cost + repair_cost + other_cost

    #############   管理费用=保险费+其他管理费用  #############
    # 其他管理费用
    other_manage_cost = sum((10.0, 15.0, 0.0, 0.0, 15.0, 0.0, 8.0) .* CAP)
    # 固定的经营成本
    operation_cost_fix = product_cost + other_manage_cost
    # 经营收入
    operation_incomes = sellElectricityProfit(sum_load_power, fin)
    # 销售税额 = 商品单价 × 销售量 × 增值税税率
    tax_sell = operation_incomes * 0.13
    # 进项成本税
    tax_in = (coal_cost + material_cost) * 0.13 + gas_cost * 0.09

    for year in 1:round(Int, fin.n_sys)
        # 保险费 =固定资产净值×保险费率
        insurance_cost = sum(map(x -> max(x[1] * 0.05, x[1] * (1 - x[2] * year)), zip(INV, rate_depreciation))) * 0.25e-2
        # 经营成本 = 固定的经营成本 + 保险费
        operation_cost = insurance_cost + operation_cost_fix
        # 增值税 = 销售税额 - 成本进项税额
        tax_add = tax_sell - tax_in
        tax_add = tax_add < 0 ? 0 : tax_add
        # 营业税金及附加
        tax_business = tax_add * 0.12
        # 所得税前净现金流
        net_cash_flow = (operation_incomes + tax_sell)- (operation_cost + tax_in + tax_add + tax_business)
        #所得税税率
        income_tax_rate = year < 4 ? 0.0 : (year < 7 ? fin.rate_tax / 2 : fin.rate_tax)
        #调整所得税
        income_tax = (net_cash_flow - sum(map(x -> x[2] >= year ? INV[x[1]] * rate_depreciation[x[1]] : 0, enumerate(year_depreciation)))) * income_tax_rate
        # 所得税后净现金流
        operation_year_list[year] += net_cash_flow - income_tax
    end
    return vcat(construction_year_list, operation_year_list)
end

function get_cost(fin::Financial, machines::Tuple, sums::Tuple, ::Val{2})
    # 成本列表
    costs = zeros(7)
    pv, wt, ec, hc, hs, e_es, ca_es = machines
    sum_pv_power, sum_wt_power, sum_ec_power, sum_hc_power, ΔE_from_grid, sum_e_es_power, sum_ca_es_power, sum_load_power = sums
    # 设备的初始投资
    pv_investment, wt_investment, ec_investment, hc_investment, hs_investment, e_es_investment, ca_es_investment = map(initialInvestment, machines)
    # 风电、光伏、电解槽、储氢罐、电化学储能、压缩空气储能投资与容量
    INV = (pv_investment, wt_investment, ec_investment, hc_investment, hs_investment, e_es_investment, ca_es_investment)
    CAP = (pv.capacity, wt.capacity, ec.capacity, hc.capacity, hs.capacity, e_es.capacity, ca_es.capacity)
    # 初始投资
    costs .+= INV
    # 运行期替换投资与回收固定资产余值
    for (index, machine) in enumerate((pv, wt, ec, hc, hs, e_es, ca_es))
        replace_y = round(Int, machine.life_year)
        replace_y <= fin.n_sys && (costs[index] -= fin.n_sys / machine.life_year * (initialInvestment(machine) * 0.05))
        replace_y <= fin.n_sys - 1 && (costs[index] += replaceInvestment(machine))
    end
    # 初始投资
    init_costs = sum(costs)
    # 折回20年
    costs ./= fin.n_sys
    # 风电、光伏、电解槽、压缩机、储氢罐、电化学储能、压缩空气储能折旧年限
    year_depreciation = (20.0, 20.0, 20.0, 20.0, 20.0, 10.0, 20.0)
    # 折旧率
    rate_depreciation = 1 ./ year_depreciation

    ############# 生产成本=材料费+用水成本+买电成本+人员费用+维护及修理费+其他制造费用 #############
    # 材料费
    material_cost = (8.0, 15.0, 0.0, 0.0, 0.0, 15.0, 0.0) .* CAP
    # 用水成本
    sum_mass_H2_load = outputH2Mass(sum_ec_power, ec, 1.0) # 制氢量
    cost_water = costWater(sum_mass_H2_load, fin)
    water_cost = (0.0, 0.0, cost_water, 0.0, 0.0, 0.0, 0.0)
    #买电成本
    buy_electricity_cost = buyElectricityCost(ΔE_from_grid, fin)
    # 人员费用
    pv.staff_number, wt.staff_number, ec.staff_number, hc.staff_number, hs.staff_number, e_es.staff_number, ca_es.staff_number = map(staff_number, machines)
    staff_cost = (pv.staff_number, wt.staff_number, ec.staff_number, hc.staff_number, hs.staff_number, e_es.staff_number, ca_es.staff_number) .* 15e4
    # 维护及修理费
    repair_cost = (1e-2, 1e-2, 3e-2, 3e-2, 3e-2, 1e-2, 1e-2) .* INV
    # 其他制造费用
    other_cost = (5.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0) .* CAP
    # 各设备生产成本(未加买电成本)
    product_cost = @. material_cost + water_cost  + staff_cost + repair_cost + other_cost

    #############   管理费用=保险费+其他管理费用  #############
    # 其他管理费用
    other_manage_cost = (10.0, 15.0, 15.0, 0.0, 0.0, 15.0, 0.0) .* CAP
    # 税费年平均成本
    insurance_costs = zeros(7)
    for year in 1:round(Int, fin.n_sys)
        # 保险费 =固定资产净值×保险费率
        insurance_costs .+= map(x -> max(x[1] * 0.05, x[1] * (1 - x[2] * year)), zip(INV, rate_depreciation)) .* 0.25e-2
    end
    insurance_costs ./= fin.n_sys
    # 各设备经营成本
    operation_cost = @. product_cost + insurance_costs + other_manage_cost 
    # 各设备总成本 
    costs .+= operation_cost
    # 各类成本
    # costs_self = map(x -> x[2] == 0 ? 0 : x[1] / x[2], zip(costs, (sum_pv_power, sum_wt_power)))
    costs_self = costs
    costs_compare = costs ./ sum_mass_H2_load
    buy_electricity_compare = buy_electricity_cost / sum_mass_H2_load
    # 用水成本、买电成本、总制氢成本、LCOE_H2、初始投资、年运营成本
    costs_other = (cost_water, buy_electricity_cost, sum(costs) + buy_electricity_cost, (sum(costs) + buy_electricity_cost) / sum_mass_H2_load, init_costs, sum(operation_cost) + buy_electricity_cost)
    # 修正NaN和Inf
    costs = map(x -> isnan(x) || isinf(x) ? 0 : x, costs)
    return costs_self, costs_compare, buy_electricity_compare, costs_other
end

function get_cost(fin::Financial, machines::Tuple, sums::Tuple, ::Val{7})
    # 成本列表
    costs = zeros(7)
    pv, wt, p_es, ca_es, e_es, cp, gp = machines
    sum_pv_power, sum_wt_power, sum_cp_power, sum_gp_power, sum_load_power = sums
    # 获得设备的初始投资
    pv_investment, wt_investment, p_es_investment, ca_es_investment, e_es_investment, cp_investment, gp_investment = map(initialInvestment, machines)
    # 各设备投资与容量
    INV = (pv_investment, wt_investment, p_es_investment, ca_es_investment, e_es_investment, cp_investment, gp_investment)
    CAP = (pv.capacity, wt.capacity, p_es.capacity, ca_es.capacity, e_es.capacity, cp.capacity, gp.capacity)
    # 初始投资
    costs .+= INV
    # 运行期替换投资与回收固定资产余值
    for (index, machine) in enumerate((pv, wt, p_es, ca_es, e_es, cp, gp))
        replace_y = round(Int, machine.life_year)
        replace_y <= fin.n_sys && (costs[index] -= fin.n_sys / machine.life_year * (initialInvestment(machine) * 0.05))
        replace_y <= fin.n_sys - 1 && (costs[index] += replaceInvestment(machine))
    end
    # 初始投资
    init_costs = sum(costs)
    # 折回20年
    costs ./= fin.n_sys
    # 折旧年限
    year_depreciation = (20.0, 20.0, 20.0, 20.0, 10.0, 20.0, 10.0)
    # 折旧率
    rate_depreciation = 1 ./ year_depreciation

    ############# 生产成本=材料费+燃料费+人员费用+维护及修理费+其他制造费用 #############
    # 材料费
    material_cost = (8.0, 15.0, 0.0, 0.0, 15.0, 0.0, 8.0) .* CAP
    # 燃料费
    coal_cost = costCoal(sum_cp_power, cp, fin)
    gas_cost = costGas(sum_gp_power, gp, fin)
    fuel_cost = (0.0, 0.0, 0.0, 0.0, 0.0, coal_cost, gas_cost)
    # 人员费用
    machines = (pv, wt, p_es, ca_es, e_es, gp )
    pv.staff_number, wt.staff_number, p_es.staff_number, ca_es.staff_number, e_es.staff_number,  gp.staff_number = map(staff_number, machines)
    cp.staff_number = cp_staff_number(cp)
    staff_cost = (pv.staff_number, wt.staff_number, p_es.staff_number, ca_es.staff_number, e_es.staff_number, cp.staff_number, gp.staff_number) .* 15e4
    # 维护及修理费
    repair_cost = (1e-2, 1e-2, 1e-2, 1e-2, 1e-2, 3e-2, 3e-2) .* INV
    # 其他制造费用
    other_cost = (5.0, 10.0, 10.0, 10.0, 10.0, 10.0, 4.0) .* CAP
    # 生产成本
    product_cost = @. material_cost + fuel_cost + staff_cost + repair_cost + other_cost
    #############   管理费用=保险费+其他管理费用  #############
    # 其他管理费用
    other_manage_cost = (10.0, 15.0, 0.0, 0.0, 15.0, 0.0, 8.0) .* CAP
    # # 进项成本税
    # tax_in = @. (coal_cost + material_cost) * 0.13 + gas_cost * 0.09
    # 税费年平均成本
    insurance_costs = zeros(7)
    for year in 1:round(Int, fin.n_sys)
        # 保险费 =固定资产净值×保险费率
        insurance_costs .+= map(x -> max(x[1] * 0.05, x[1] * (1 - x[2] * year)), zip(INV, rate_depreciation)) .* 0.25e-2
    end
    insurance_costs ./= fin.n_sys
    # 经营成本
    operation_cost = @. product_cost + insurance_costs + other_manage_cost 
    # 总成本 
    costs .+= operation_cost
    # println(costs[6])
    # 各类成本
    costs_self = map(x -> x[2] == 0 ? 0 : x[1] / x[2], zip(costs, (sum_pv_power, sum_wt_power, sum_cp_power, sum_gp_power)))
    costs_compare = costs ./ sum_load_power
    # LCOE、初始投资、年运营成本
    costs_other = (sum(costs) / sum_load_power, init_costs, sum(operation_cost))
    # 修正NaN和Inf
    costs = map(x -> isnan(x) || isinf(x) ? 0 : x, costs)
    return costs_self, costs_compare, costs_other
end


