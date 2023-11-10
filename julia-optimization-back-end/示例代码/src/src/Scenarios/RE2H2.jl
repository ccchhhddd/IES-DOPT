# 可再生电力制氢：并网系统：电池模块即为电网

# 优化变量匹配，仿真求解带入
function match_vars_RE2H2(opt_var_components::Array, optvars,opt_var_lower_boundary,opt_var_upper_boundary;
    E_rated_device_components=[650.0,5000.0,5000.0,1000.0,0.05,1000.0])

    # opt_var_components = [0,0,1,1,1] # PV,WT,AEC,HT,SoC_HT_cha_thre,BAT是否优化
    # E_rated_device_components：PV,WT,AEC,HT,SoC_HT_cha_thre,BAT变量的设备额定功率，用于变量取整
    vc = @syms(
    PV₊E_rated::Real,
    WT₊E_rated::Real,
    AEC₊E_rated::Real,
    HT₊E_rated::Real,
    HT₊SoC_cha_thre::Real,
    BAT₊E_rated::Real
    )

    idx = 1
    vs = []

    for i in 1:length(opt_var_components)
        if opt_var_components[i] == 1
            vi = round(optvars[idx]/E_rated_device_components[i])*E_rated_device_components[i]
            vi_lower = opt_var_lower_boundary[idx]
            vi_upper = opt_var_upper_boundary[idx]
            push!(vs, vc[i] => max(vi_lower, min(vi,vi_upper)))
            idx += 1
        end
    end

    vs = [i for i in vs]

    return vs
end


# AEC操作策略:对接ELBUS
# HT.ΔE_cha_max:可不用
function W_AEC_oper(W_AEC_rated, η_EC, W_RE, H2L, m_HT_disc_max, m_HT_cha_to_thre, m_HT_cha_max)
    W_AEC_max = min(W_AEC_rated, (H2L + m_HT_cha_to_thre) * 33.4 / η_EC, (H2L + m_HT_cha_max) * 33.4 / η_EC) # 由AEC提供H2为主,AEC多发
    W_AEC_min = max(0, min(W_AEC_rated, (H2L + m_HT_disc_max) * 33.4 / η_EC)) # 由HT提供H2为主，AEC少发,m_HT_disc_max:-
    W_AEC = ifelse(W_RE < W_AEC_min, W_AEC_min, # RE不足：购电
        ifelse(W_AEC_min <= W_RE <= W_AEC_max, W_RE,  # RE全消纳
            W_AEC_max)) # RE余电：上网

    return W_AEC

end
@register_symbolic W_AEC_oper(W_AEC_rated, η_EC, W_RE, H2L, m_HT_disc_max, m_HT_cha_to_thre, m_HT_cha_max)



# 离网系统：电池模块
# TAG--2：优化
# 求解优化问题

function optimization_RE2H2(data_GI::Vector,
    data_Ta::Vector,
    data_WS::Vector,
    data_H2L::Vector,
    param_PV::Dict,
    param_WT::Dict,
    param_AEC::Dict,
    param_HT::Dict,
    param_BAT::Dict,
    opt_var_components::Array, # # PV,WT,AEC,HT,SoC_HT_cha_thre是否优化
    opt_var_lower_boundary::Array, # 优化变量下界
    opt_var_upper_boundary::Array; # 优化变量上界
    max_opt_time=60.0,
    LHSP_thre=0.0,
    ar_RE_thre=0.1,
    n_sys=20.0,
    r=0.05,
    construction_life=1.0,
    year_cost_oper=0.0, # 电站运营成本（人力成本）
    rate_depreciation=0.0,
    rate_discount=0.08,
    rate_tax=0.0,
    cost_water_per_kg_H2=0.021,
    H2price_sale=25.58, # ￥/kg
    gas_factor=1,
    coal_factor=0.5
)

    @info "创建组件..."

    @named PV = PhotovoltaicCell(param_PV)   # 50万kW
    @named WT = WindTurbine(param_WT)   # 50万kW, 成本+逆变器
    @named BAT = Battery(param_BAT) # 1e6 
    @named AEC = ElectrolyticCell(param_AEC) # 500000 kWh; 9000kg H2
    @named HT = CompressedH2Tank(param_HT) # 16万立方米 ~ 15000 kg

    @named GI = Secrete(data_GI)
    @named Ta = Secrete(data_Ta)
    @named WS = Secrete(data_WS)
    @named H2L = Secrete(data_H2L)
    @named ELBUS = EnergyBus(names_p=["PV", "WT"], names_n=["AEC", "HT"])
    @named H2BUS = EnergyBus(names_p=["AEC"], names_n=["H2L"])

    @info "创建系统..."


    eqs = [
        GI.u.u ~ PV.GI.u#connect(GI.u, PV.GI)
        Ta.u.u ~ PV.Ta.u#connect(Ta.u, PV.Ta)
        WS.u.u ~ PV.v.u#connect(WS.u, PV.v)
        WS.u.u ~ WT.v1.u#    connect(WS.u, WT.v1)
        PV.W ~ ELBUS.PV.u#connect(PV.W, ELBUS.PV.u)
        WT.W ~ ELBUS.WT.u
        ELBUS.AEC.u ~ W_AEC_oper(AEC.E_rated / AEC.η_inverter, AEC.η_EC, PV.W + WT.W, H2L.u.u,
            HT.ΔE_disc_max, HT.ΔE_cha_to_thre, HT.ΔE_cha_max)
        AEC.W_source.u ~ ELBUS.AEC.u + min(0, ELBUS.ΔE)
        ELBUS.HT.u ~ max(0,HT.ΔE)*HT.W_comp_per_kgH2
        ELBUS.E ~ BAT.ebus.u
        ELBUS.ΔE ~ BAT.ΔE_bus_left
        AEC.m ~ H2BUS.AEC.u
        H2L.u.u ~ H2BUS.H2L.u
        H2BUS.E ~ HT.ebus.u
        H2BUS.ΔE ~ HT.ΔE_bus_left
    ]


    @named model = compose(ODESystem(eqs, t, name=:funs),
        [PV, WT, BAT, AEC, HT, GI, Ta, WS, H2L, ELBUS, H2BUS])

    @info "系统化简..."
    sys = structural_simplify(model)#dae_index_lowering(model))

    @info "创建仿真..."
    prob = ODEProblem(sys, [], (0.0, length(data_H2L) - 1))
    sol = solve(prob, saveat=1.0, Rosenbrock23())

    @info "创建优化..."

    E_rated_device_components = [sol[PV.E_device_rated], 
                                 sol[WT.E_device_rated], 
                                 sol[AEC.E_device_rated], 
                                 sol[HT.E_device_rated], 
                                 0.05,#SoC
                                 sol[BAT.E_device_rated]]

    crf = cal_CRF(n_sys, r)


    function obj_bl(opt_var_components::Array, optvars, E_rated_device_components,opt_var_lower_boundary,opt_var_upper_boundary; 
        prob, H2BUS, H2L,
        n_sys, crf, cost_water_per_kg_H2,
        LHSP_thre, ar_RE_thre)

        pnew = match_vars_RE2H2(opt_var_components, optvars, opt_var_lower_boundary,opt_var_upper_boundary;
                          E_rated_device_components=E_rated_device_components)

        prob = remake(prob, p=pnew)
        sol = solve(prob, saveat=1.0, Rosenbrock23())

        LHSP = probability_of_loss_of_load_supplied(sol, H2BUS, H2L) # +
        W_RE = sum(sol[ELBUS.sum_p])
        ΔW_RE_abon = sum([i for i in sol[ELBUS.ΔE] if i > 0])

        ar_RE = ΔW_RE_abon / W_RE

        penalty_Δm = 100000.0 * max(LHSP_thre, min(1.0,LHSP)) # thre=-0.0
        penalty_RE = 10000.0 * max(ar_RE_thre, min(1.0,ar_RE)) #thre=0.1

        m_H2L = sum(sol[H2L.u.u])
        cost_ini, year_cost_OM = cost_system_initial_OM([PV, WT, AEC, HT, BAT], n_sys,r, sol)
        profit = 0
        m_H2_AEC = sum(sol[AEC.m])
        cost_water = cost_water_per_kg_H2 * m_H2_AEC
        LCOE_H2 = (crf * cost_ini - profit + cost_water + year_cost_OM) / (m_H2L * (1 - LHSP)) #￥/kg H2

        return ob = LCOE_H2 + penalty_Δm + penalty_RE

    end

    #opt_var_components = [0,0,1,1,1] # PV,WT,AEC,HT,SoC_HT_cha_thre是否优化
    optobj(optvars) = obj_bl(opt_var_components, optvars, E_rated_device_components,opt_var_lower_boundary,opt_var_upper_boundary; 
        prob, H2BUS, H2L,
        n_sys, crf, cost_water_per_kg_H2,
        LHSP_thre, ar_RE_thre)

    # AEC,PV,WT,Bat,HT
    lower = opt_var_lower_boundary
    upper = opt_var_upper_boundary
    # SearchRange = (collect(zip(lower,upper)))

    @info "开始优化..."

    # 调用bboptimize函数进行优化

    res = bboptimize(optobj; SearchRange=(collect(zip(lower, upper))), 
                     MaxTime=max_opt_time,
                     Method=:de_rand_2_bin)

    # MaxSteps = 1e3)#, MaxRelativeFitnessChange = 1e-2) # 

    #res = compare_optimizers(optobj; SearchRange = (collect(zip(lower,upper))), MaxTime = max_opt_time)

    # 打印优化结果摘要
    println(BlackBoxOptim.summary(res))
    # 
    # 获取最优解和最优值
    xopt = best_candidate(res)
    fopt = best_fitness(res)
    println("xopt = $xopt")
    println("fopt = $fopt")

    pnew = match_vars_RE2H2(opt_var_components, xopt,opt_var_lower_boundary,opt_var_upper_boundary; E_rated_device_components)
    prob = remake(prob, p=pnew)
    sol = solve(prob, saveat=1.0, Rosenbrock23())

    @info "系统评价..."
    components = [PV, WT, AEC, HT, BAT]

    W_AEC = sum(sol[AEC.W])
    W_HT = sum([i for i in sol[HT.ΔE] if i > 0])*sol[HT.W_comp_per_kgH2]
    cost_ini, year_cost_OM = cost_system_initial_OM(components, n_sys,r, sol)
    profit = 0
    m_H2_AEC = sum(sol[AEC.m])
    cost_water = cost_water_per_kg_H2 * m_H2_AEC

    crf = cal_CRF(n_sys, r)

    LCOE = (crf * cost_ini - profit + cost_water + year_cost_OM) / (W_AEC + W_HT)

    LHSP = probability_of_loss_of_load_supplied(sol, H2BUS, H2L)
    #ar_RE = abandonment_rate_RE(sol, ELBUS)

    H2L_total = sum(sol[H2L.u.u])
    H2L_supplied = H2L_total * (1 - LHSP)
    LCOE_H2 = (crf * cost_ini - profit + cost_water + year_cost_OM) / H2L_supplied  # ￥/kg H2

    m_H2_ab = sum(sol[H2BUS.ΔE])
    m_AEC = sum(sol[AEC.m])
    ar_H2 = m_H2_ab / m_AEC

    W_load = sum(sol[ELBUS.sum_n])
    W_RE = sum(sol[ELBUS.sum_p])

    W_AEC = sum(sol[AEC.W])
    W_PV = sum(sol[PV.W])
    W_WT = sum(sol[WT.W])
    ΔW_BAT_t = sol[BAT.ΔE]
    ΔW_to_BAT = sum([i for i in ΔW_BAT_t if i > 0])
    ΔW_from_BAT = sum([i for i in ΔW_BAT_t if i < 0])

    ΔW_RE_abon = sum([i for i in sol[ELBUS.ΔE] if i > 0])

    ar_RE = ΔW_RE_abon / W_RE

    # 经济性评价
    cost_ini_components = []
    cost_OM_components = []
    for c in components
        cost_ini_i = sol[c.cost_initial] * sol[c.E_rated]
        n_replace = sol[c.life_year]
        while n_replace < n_sys
            cost_ini_i += sol[c.cost_replace] * sol[c.E_rated] * (1 + r)^n_replace

            n_replace += n_replace
        end
        cost_OM_i = sol[c.cost_OM] * sol[c.E_rated]

        push!(cost_ini_components, cost_ini_i)
        push!(cost_OM_components, cost_OM_i)
    end

    cost_initial = sum(cost_ini_components)
    year_cost_main = sum(cost_OM_components)
    revenue_H2 = H2price_sale * H2L_supplied

    operation_life = ceil(n_sys)
    construction_life = ceil(construction_life)
    year_revenue = revenue_H2 + profit - cost_water

    NPV, IRR, payback = financial_evaluation(cost_initial,
        year_cost_oper, year_cost_main, year_revenue,
        operation_life, construction_life,
        rate_depreciation=rate_depreciation,
        rate_discount=rate_discount,
        rate_tax=rate_tax)


    dict_res = OrderedDict(
        "风电（万千瓦）" => sol[WT.E_rated] / 1e4,
        "光伏（万千瓦）" => sol[PV.E_rated] / 1e4,
        "制氢（万千瓦）" => sol[AEC.E_rated] / 1e4,
        "储氢（吨）" => sol[HT.E_rated] / 1e3,
        "储氢（万立方米）" => sol[HT.E_rated] / 1e4 / 0.089,
        "储氢设备充能阈值" => sol[HT.SoC_cha_thre],
        "锂电池（万千瓦时）" => sol[BAT.E_rated] / 1e4,
        "系统设计寿命（年）" => n_sys,
        "光伏电量（亿千瓦时）" => W_PV / 1e8,
        "风电电量（亿千瓦时）" => W_WT / 1e8,
        "风电光伏电量（亿千瓦时）" => W_RE / 1e8,
        "风电光伏利用率（%）" => (1 - ar_RE) * 100,
        "风电光伏弃电率（%）" => ar_RE * 100,
        "风光发电制氢电量（亿千瓦时）" => (W_RE - ΔW_RE_abon) / 1e8,
        "制氢用电量（亿千瓦时）" => W_AEC / 1e8,
        "储氢用电量（亿千瓦时）" => W_HT / 1e8,
        "制氢设备利用小时数（小时）" => sum([1 for i in sol[AEC.W] if i > 0]),
        "制氢量（万吨）" => m_AEC / 1e7,
        "氢气负荷（万吨）" => H2L_total / 1e7,
        "氢负荷失负率（%）" => LHSP * 100,
        "静态总投资（亿元）" => cost_ini / 1e8,
        "年度售氢盈利（亿元）" => revenue_H2 / 1e8,
        "年度运维成本（亿元）" => year_cost_OM / 1e8,
        "年度用水成本（亿元）" => cost_water / 1e8,
        "制氢价格（元/kg）" => LCOE_H2,
        "制氢价格（元/方）" => LCOE_H2 * 0.089,
        "度电成本（元/kWh）" => LCOE,
        "项目净现值NPV（亿元）" => NPV / 1e8,
        "内部收益率IRR" => IRR,
        "投资回收期（年）" => payback
    )

    return getSolution(sol, [PV.W, WT.W, AEC.W, BAT.ΔE]), dict_res

end



