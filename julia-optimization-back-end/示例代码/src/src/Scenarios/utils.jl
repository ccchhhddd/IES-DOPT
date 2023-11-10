# 常用函数
"""
# AEC操作策略:对接ELBUS
# 缺少HT.ΔE_cha_max
function W_AEC_oper(W_AEC_rated, W_RE, H2L, m_HT_disc_max, m_HT_cha_to_thre, m_HT_cha_max)
    W_AEC_max = min(W_AEC_rated, (H2L+m_HT_cha_to_thre) *33.4/0.6, (H2L+m_HT_cha_max) *33.4/0.6) # 由AEC提供H2为主,AEC多发
    W_AEC_min = max(0, min(W_AEC_rated, (H2L-m_HT_disc_max)*33.4/0.6)) # 由HT提供H2为主，AEC少发
    W_AEC = ifelse(W_RE<W_AEC_min, W_AEC_min, # RE不足：购电
                ifelse(W_AEC_min<= W_RE <= W_AEC_max, W_RE,  # RE全消纳
                    W_AEC_max)) # RE余电：上网
    
    return W_AEC
    
end
@register_symbolic W_AEC_oper(W_AEC_rated, W_RE, H2L, m_HT_disc_max, m_HT_cha_to_thre, m_HT_cha_max)

# AEC操作策略:对接ELBUS
function W_AEC_oper(PV, WT, AEC, HT, H2L)

    W_H2L = H2L.u.u * AEC.LHV_H2 / AEC.M_H2 * 1000 / 3600 /AEC.η_inverter/AEC.η_EC # kWh
    W_HT_disc_max = HT.ΔE_disc_max * AEC.LHV_H2 / AEC.M_H2 * 1000 / 3600 /AEC.η_inverter/AEC.η_EC
    W_HT_cha_max = HT.ΔE_cha_max * AEC.LHV_H2 / AEC.M_H2 * 1000 / 3600 /AEC.η_inverter/AEC.η_EC
    W_HT_cha_to_thre = HT.ΔE_cha_to_thre * AEC.LHV_H2 / AEC.M_H2 * 1000 / 3600 /AEC.η_inverter/AEC.η_EC

    W_AEC_rated = AEC.E_rated/AEC.η_inverter
    W_RE = PV.W + WT.W

    W_AEC_max = min(W_AEC_rated, W_H2L+W_HT_cha_to_thre, W_H2L+W_HT_cha_max) # 由AEC提供H2为主,AEC多发
    W_AEC_min = max(0, min(W_AEC_rated, W_H2L-W_HT_disc_max)) # 由HT提供H2为主，AEC少发
    W_AEC = ifelse(W_RE<W_AEC_min, W_AEC_min, # RE不足：购电
                ifelse(W_AEC_min<= W_RE <= W_AEC_max, W_RE,  # RE全消纳
                    W_AEC_max)) # RE余电：上网
    
    return W_AEC
end

@register_symbolic W_AEC_oper(PV, WT, AEC, HT, H2L)


# AEC操作策略:对接ELBUS
function W_AEC_oper(AEC_E_rated, AEC_LHV_H2, AEC_M_H2, AEC_η_inverter, AEC_η_EC,
                    H2L_u_u, HT_ΔE_disc_max, HT_ΔE_cha_max, HT_ΔE_cha_to_thre, PV_W, WT_W)

    W_H2L = H2L_u_u * AEC_LHV_H2 / AEC_M_H2 * 1000 / 3600 /AEC_η_inverter/AEC_η_EC # kWh
    W_HT_disc_max = HT_ΔE_disc_max * AEC_LHV_H2 / AEC_M_H2 * 1000 / 3600 /AEC_η_inverter/AEC_η_EC
    W_HT_cha_max = HT_ΔE_cha_max * AEC_LHV_H2 / AEC_M_H2 * 1000 / 3600 /AEC_η_inverter/AEC_η_EC
    W_HT_cha_to_thre = HT_ΔE_cha_to_thre * AEC_LHV_H2 / AEC_M_H2 * 1000 / 3600 /AEC_η_inverter/AEC_η_EC

    W_AEC_rated = AEC_E_rated/AEC_η_inverter
    W_RE = PV_W + WT_W

    W_AEC_max = min(W_AEC_rated, (W_H2L+W_HT_cha_to_thre), W_H2L+W_HT_cha_max) # 由AEC提供H2为主,AEC多发
    W_AEC_min = max(0, min(W_AEC_rated, W_H2L-W_HT_disc_max)) # 由HT提供H2为主，AEC少发
    W_AEC = ifelse(W_RE < W_AEC_min, W_AEC_min, # RE不足：购电
                ifelse(W_AEC_min <= W_RE <= W_AEC_max, W_RE,  # RE供电
                    W_AEC_max)) # RE余电：上网
    
    return W_AEC
end

@register_symbolic W_AEC_oper(AEC_E_rated, AEC_LHV_H2, AEC_M_H2, AEC_η_inverter, AEC_η_EC,
                              H2L_u_u, HT_ΔE_disc_max, HT_ΔE_cha_max, HT_ΔE_cha_to_thre, PV_W, WT_W)

ELBUS.AEC.u ~ W_AEC_oper(AEC.E_rated, AEC.LHV_H2, AEC.M_H2, AEC.η_inverter, AEC.η_EC,
                        H2L.u.u, HT.ΔE_disc_max, HT.ΔE_cha_max, HT.ΔE_cha_to_thre, PV.W, WT.W)

"""
# 计算CRF
function cal_CRF(n,r)
    crf = r*(1+r)^n / ((1+r)^n-1)
end


function probability_of_loss_of_load_supplied(sol, BUS, Load)
    ΔE_BUS_t = sol[BUS.ΔE]
    E_Load = sum(sol[Load.u.u])
    ΔE_BUS_lack = sum([i for i in ΔE_BUS_t if i < 0])
    LHSP = -ΔE_BUS_lack/E_Load
    return LHSP
end

function abandonment_rate_RE(sol,ELBUS)
    W_RE = sum(sol[ELBUS.sum_p])
    ΔW_ELBUS_t = sol[ELBUS.ΔE]
    ΔW_ELBUS_surplus = sum([i for i in ΔW_ELBUS_t if i > 0])

    return ΔW_ELBUS_surplus/W_RE
end

function profit_balance_grid(sol, GRID, eprice_from_grid, eprice_to_grid)
    ΔW_GRID_t = sol[GRID.ΔE]
    ΔW_GRID_to_grid = sum([i for i in ΔW_GRID_t if i > 0])
    ΔW_GRID_from_grid = sum([i for i in ΔW_GRID_t if i < 0])

    profit = eprice_to_grid * ΔW_GRID_to_grid + eprice_from_grid * ΔW_GRID_from_grid

    return profit
end

function profit_balance_grid(sol, GRID, eprice_from_grid)
    ΔW_GRID_t = sol[GRID.ΔE]
    ΔW_GRID_to_grid = 0
    ΔW_GRID_from_grid = sum([i for i in ΔW_GRID_t if i < 0])

    profit = ΔW_GRID_to_grid + eprice_from_grid * ΔW_GRID_from_grid

    return profit
end


function cost_system_initial_OM(components::Array,n_sys,r,sol)

    cost_ini_components = []
    cost_OM_components = []
    for c in components
        cost_ini_i = sol[c.cost_initial]*sol[c.E_rated]
        n_replace = sol[c.life_year]
        while n_replace < n_sys
            cost_ini_i += sol[c.cost_replace] * sol[c.E_rated] * (1+r)^n_replace

            n_replace += n_replace
        end
        cost_OM_i = sol[c.cost_OM] * sol[c.E_rated]

        push!(cost_ini_components,cost_ini_i)
        push!(cost_OM_components, cost_OM_i)
    end

    cost_initial = sum(cost_ini_components)
    year_cost_OM = sum(cost_OM_components)

    return cost_initial, year_cost_OM
end

# 财务评价
function financial_evaluation(cost_initial, 
    year_cost_oper, year_cost_main, year_revenue,
    operation_life, construction_life;
    rate_depreciation=0.05, rate_discount=0.08, rate_tax=0.25)

    operation_life = Int(operation_life)
    construction_life = Int(construction_life)
    annual_investment_cost = vcat(cost_initial/construction_life .* ones(construction_life),zeros(operation_life))
    annual_revenue = vcat(zeros(construction_life),  year_revenue .* ones(operation_life))
    annual_operating_cost = vcat(zeros(construction_life), (year_cost_oper + year_cost_main) .* ones(operation_life))
    depreciation = vcat(zeros(construction_life), cost_initial * rate_depreciation .* ones(operation_life)) # 折旧

    cashflows = (annual_revenue .- depreciation .- annual_operating_cost) .* (1-rate_tax) .- annual_investment_cost
    times = collect(0:length(cashflows)-1)

    NPV = present_value(rate_discount, cashflows, times)
    # 0.057483
    IRR = irr(cashflows)
    payback = breakeven(rate_discount, cashflows,times)

    if IRR === nothing
        println("内部收益率计算失败")
        IRR = -1
    else
        IRR = ActuaryUtilities.FinanceCore.rate(IRR)
    end

    if payback === nothing
        println("投资回收期超出项目期限")
        payback = -1
    end

    return NPV, IRR, payback

end

# 结果保存
function save_csv(dict_res, save_fn::String="test/results/result.csv")
    df = DataFrame(; items=collect(keys(dict_res)), value=collect(values(dict_res)))
    CSV.write(save_fn, df, encoding="UTF-8", transform=(col, val) -> something(val, missing))

end

function getSolution(sol, vars)
    return Dict(
        string(v) => sol[v] for v in vars
    )
end
