using BlackBoxOptim

"""
返回优化结果的字典数据

- Val{1}：离网制氢,氢气成本最低
- Val{2}：离网制氢,额定投资,氢气产能最大
- Val{3}：离网制氢,额定制氢量,总投资成本最低

"""
function optimization!(machines::Tuple, isOpt, fin::Financial,op::OptimizeParas, ::Val{1})
    #从元组中取出各个机器参数
    wt,pv,gt,iv,ca_es,ec,hc,hs= machines
    isOpt = isOpt[1:8]
    obj = function (x)
        # 顺序为风、光、燃气轮机、逆变器、压缩空气储能、电解槽、氢气压缩机、储气罐
        machines = matchOptVars((wt,pv,gt,iv,ca_es,ec,hc,hs), isOpt, x)
        wt,pv,gt,iv,ca_es,ec,hc,hs= machines
        #一周时间后所制取的氢气 和 燃气轮机所需发电总量
        hydrogen_M,sum_gt_Ele = outputHydrogen(wt,pv,gt,iv,ca_es,ec,hc,hs)
        #计算用水量
        water = hydrogen_M[end]*9
        #计算用天然气总量=(燃烧的天然气量=天然气发电量*3600/发电效率/天然气低位发热值) Nm³
        natural_gas = sum_gt_Ele*3600/gt.η/(gt.lhv_gas*1000)

        #计算各设备的成本
        cost_wt= totalCost(wt,fin)
        cost_pv= totalCost(pv,fin)
        cost_gt= totalCost(gt,fin)
        cost_iv= totalCost(iv,fin)
        cost_ca_es= totalCost(ca_es,fin)
        cost_ec= totalCost(ec,fin)
        cost_hc= totalCost(hc,fin)
        cost_hs = totalCost(hs,fin)
        machine_cost = cost_wt+cost_pv+cost_gt+cost_iv+cost_ca_es+cost_ec+cost_hc+cost_hs

        #目前计算总成本的时候不考虑取样时间和系统设备寿命之间的关系
        #(可能会导致计算结果中运行时间越短单位氢气成本越高)

        #计算最终氢气的体积
        hydrogen_final_V = hydrogen_M[end] /2*22.4
        #计算总成本 = 水成本 + 天然气成本 + 设备成本(投资+运维+更换)
        cost_total = costWater(water,fin)+costGas(natural_gas,fin)+costH2Transport(hydrogen_M[end],hs,fin)+machine_cost

        #计算单位氢气成本
        cost_H2 = costH2(hydrogen_final_V,cost_total)

        objective = cost_H2
        return objective
    end


    # 根据 op.select_slo 的值获取相应的优化算法
    sol = get(slo_dict, op.select_slo,nothing)

    #调用优化求解器
    res = bboptimize(obj; SearchRange=(1.0e3, 5.0e7),
        NumDimensions=sum(isOpt),TraceMode=:verbose,Method= sol ,MaxTime = 60)

    # 输出优化结果
    candidate, fitness = best_candidate(res), best_fitness(res)
    println("优化变量结果： $candidate", "目标值： $fitness")
    machines = matchOptVars((wt,pv,gt,iv,ca_es,ec,hc,hs), isOpt, candidate)
    table = add_table(wt,pv,gt,iv,ca_es,ec,hc,hs, isOpt, candidate)

    # 返回最优解的仿真结果
    figure,figure2,table0 = simulate!((machines..., 0), fin)
    table["每方氢气的成本(元/m³)"] = table0["每方氢气的成本(元/m³)"]
    return figure,figure2,table
end


function optimization!(machines::Tuple, isOpt, fin::Financial,op::OptimizeParas, ::Val{2})
    #从元组中取出各个机器参数
    wt,pv,gt,iv,ca_es,ec,hc,hs= machines
    isOpt = isOpt[1:8]
    obj = function (x)
        # 顺序为风、光、燃气轮机、逆变器、压缩空气储能、电解槽、氢气压缩机、储气罐
        machines = matchOptVars((wt,pv,gt,iv,ca_es,ec,hc,hs), isOpt, x)
        wt,pv,gt,iv,ca_es,ec,hc,hs= machines
        #一周时间后所制取的氢气 和 燃气轮机所需发电总量
        hydrogen_M,sum_gt_Ele = outputHydrogen(wt,pv,gt,iv,ca_es,ec,hc,hs)
        #计算用水量
        water = hydrogen_M[end]*9
        #计算用天然气总量=(燃烧的天然气量=天然气发电量*3600/发电效率/天然气低位发热值) Nm³
        natural_gas = sum_gt_Ele*3600/gt.η/(gt.lhv_gas*1000)

        #计算各设备的成本
        cost_wt= totalCost(wt,fin)
        cost_pv= totalCost(pv,fin)
        cost_gt= totalCost(gt,fin)
        cost_iv= totalCost(iv,fin)
        cost_ca_es= totalCost(ca_es,fin)
        cost_ec= totalCost(ec,fin)
        cost_hc= totalCost(hc,fin)
        cost_hs = totalCost(hs,fin)
        machine_cost = cost_wt+cost_pv+cost_gt+cost_iv+cost_ca_es+cost_ec+cost_hc+cost_hs

        #目前计算总成本的时候不考虑取样时间和系统设备寿命之间的关系
        #(可能会导致计算结果中运行时间越短单位氢气成本越高)

        #计算最终氢气的体积
        hydrogen_final_V = hydrogen_M[end] /2*22.4
        #计算总成本 = 水成本 + 天然气成本 + 设备成本(投资+运维+更换)
        cost_total = costWater(water,fin)+costGas(natural_gas,fin)+costH2Transport(hydrogen_M[end],hs,fin)+machine_cost

        #计算单位氢气成本
        cost_H2 = costH2(hydrogen_final_V,cost_total)

        #如果仿真后的总成本超过预算，氢气单位价格返回一个很大值1.0e7
        if cost_total > fin.investment
            cost_H2 = 1.0e7
        end
        objective = cost_H2

        return objective
    end

    # 根据 op.select_slo 的值获取相应的优化算法
    sol = get(slo_dict, op.select_slo)


    #调用优化求解器
    res = bboptimize(obj; SearchRange=(1.0e3, 1.0e4),
        NumDimensions=sum(isOpt),TraceMode=:verbose,Method= sol ,MaxTime = 30)
    candidate, fitness = best_candidate(res), best_fitness(res)
    for i in 1:5
        res0 = bboptimize(obj; SearchRange=(1.0e3, 10^(i+4)),
        NumDimensions=sum(isOpt),TraceMode=:verbose,Method= sol ,MaxTime = 30)
        # 输出优化结果
        if best_fitness(res0) < fitness
            candidate, fitness = best_candidate(res0), best_fitness(res0)
        end
    end
    println("优化变量结果： $candidate", "目标值： $fitness")

    machines = matchOptVars((wt,pv,gt,iv,ca_es,ec,hc,hs), isOpt, candidate)
    table = add_table(wt,pv,gt,iv,ca_es,ec,hc,hs, isOpt, candidate)

    # 返回最优解的仿真结果
    figure,figure2,table0 = simulate!((machines..., 0), fin)
    table["每方氢气的成本(元/m³)"] = table0["每方氢气的成本(元/m³)"]
    table["总成本(元)"] = table0["总成本(元)"]
    table["制氢量(kg)"] = table0["制氢量(kg)"]
    return figure,figure2,table
end


function optimization!(machines::Tuple, isOpt, fin::Financial,op::OptimizeParas, ::Val{3})
    #从元组中取出各个机器参数
    wt,pv,gt,iv,ca_es,ec,hc,hs= machines
    isOpt = isOpt[1:8]
    obj = function (x)
        # 顺序为风、光、燃气轮机、逆变器、压缩空气储能、电解槽、氢气压缩机、储气罐
        machines = matchOptVars((wt,pv,gt,iv,ca_es,ec,hc,hs), isOpt, x)
        wt,pv,gt,iv,ca_es,ec,hc,hs= machines
        #一周时间后所制取的氢气 和 燃气轮机所需发电总量
        hydrogen_M,sum_gt_Ele = outputHydrogen(wt,pv,gt,iv,ca_es,ec,hc,hs)
        #计算用水量
        water = hydrogen_M[end]*9
        #计算用天然气总量=(燃烧的天然气量=天然气发电量*3600/发电效率/天然气低位发热值) Nm³
        natural_gas = sum_gt_Ele*3600/gt.η/(gt.lhv_gas*1000)

        #计算各设备的成本
        cost_wt= totalCost(wt,fin)
        cost_pv= totalCost(pv,fin)
        cost_gt= totalCost(gt,fin)
        cost_iv= totalCost(iv,fin)
        cost_ca_es= totalCost(ca_es,fin)
        cost_ec= totalCost(ec,fin)
        cost_hc= totalCost(hc,fin)
        cost_hs = totalCost(hs,fin)
        machine_cost = cost_wt+cost_pv+cost_gt+cost_iv+cost_ca_es+cost_ec+cost_hc+cost_hs

        #目前计算总成本的时候不考虑取样时间和系统设备寿命之间的关系
        #(可能会导致计算结果中运行时间越短单位氢气成本越高)

        #计算最终氢气的体积
        hydrogen_final_V = hydrogen_M[end] /2*22.4
        #计算总成本 = 水成本 + 天然气成本 + 设备成本(投资+运维+更换)
        cost_total = costWater(water,fin)+costGas(natural_gas,fin)+costH2Transport(hydrogen_M[end],hs,fin)+machine_cost


        #如果氢气少于需求量，总成本返回一个很大值
        if hydrogen_M[end] < fin.H2production
            cost_total = 1.0e18
        end
        objective = cost_total

        return objective
    end

    # 根据 op.select_slo 的值获取相应的优化算法
    sol = get(slo_dict, op.select_slo)

    #调用优化求解器
    res = bboptimize(obj; SearchRange=(1.0e3, 1.0e4),
        NumDimensions=sum(isOpt),TraceMode=:verbose,Method= sol ,MaxTime = 30)
    candidate, fitness = best_candidate(res), best_fitness(res)
    for i in 1:5
        res0 = bboptimize(obj; SearchRange=(1.0e3, 10^(i+4)),
        NumDimensions=sum(isOpt),TraceMode=:verbose,Method= sol ,MaxTime = 30)
        # 输出优化结果
        if best_fitness(res0) < fitness
            candidate, fitness = best_candidate(res0), best_fitness(res0)
        end
    end
    println("优化变量结果： $candidate", "目标值： $fitness")

    machines = matchOptVars((wt,pv,gt,iv,ca_es,ec,hc,hs), isOpt, candidate)
    table = add_table(wt,pv,gt,iv,ca_es,ec,hc,hs, isOpt, candidate)

    # 返回最优解的仿真结果
    figure,figure2,table0 = simulate!((machines..., 0), fin)
    table["每方氢气的成本(元/m³)"] = table0["每方氢气的成本(元/m³)"]
    table["总成本(元)"] = table0["总成本(元)"]
    table["制氢量(kg)"] = table0["制氢量(kg)"]
    return figure,figure2,table
end


#API
"""
- Val{1} :离网制氢（风、光、燃气轮机、整流器、电解槽、压缩空气储能、电解槽、氢气压缩机、储氢罐、燃料电池、经济性分析）
"""
function optimize!(paras, opt_paras, isOpt ,area::Int64, ::Val{1})
    day = paras["经济性分析参数"]["运行天数"]
    ΔT = [1.0 for i in 1:24* day  ]
    if area == 1
        data_weather = CSV.File("src/Optimization/data/weather_Yulin_2005.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
        data_weather0 = CSV.File("src/Optimization/data/weather_Yulin_2005.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
    elseif area == 2
        data_weather = CSV.File("src/Optimization/data/weather_Ruoqiang_2005.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
        data_weather0 = CSV.File("src/Optimization/data/weather_Ruoqiang_2005.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
    elseif area == 3
        data_weather = CSV.File("src/Optimization/data/weather_Lenghu_2018.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
        data_weather0 = CSV.File("src/Optimization/data/weather_Lenghu_2018.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
    elseif area == 4
        data_weather = CSV.File("src/Optimization/data/weather_Haixi_Delingha_2021.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
        data_weather0 = CSV.File("src/Optimization/data/weather_Haixi_Delingha_2021.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
    end
    for i in 1:floor(day/365)
        data_weather = vcat(data_weather, data_weather0)
    end
    GI = data_weather.glob_hor_rad[1:length(ΔT)] # 光照强度Wh/m2
    TA = data_weather.DBT[1:length(ΔT)].+273.15  # 环境温度℃
    WS = data_weather.wind_speed[1:length(ΔT)]   # 风速m/s
    wt = WindTurbine(input_v = WS,
                    unit_capacity= paras["风电参数"]["单机容量(kw)"],
                    machine_number = paras["风电参数"]["机组数量"],
                    η_t = paras["风电参数"]["风轮传动效率"],
                    η_g = paras["风电参数"]["发电机效率"],
                    h1 = paras["风电参数"]["风速切入速度(m/s)"],
                    h2 = paras["风电参数"]["风速切出速度(m/s)"],
                    h3 = paras["风电参数"]["截止风速速度(m/s)"],
                    life_year = paras["风电参数"]["使用年限(年)"],
                    cost_initial = paras["风电参数"]["初始成本(元/kw)"],
                    cost_OM = paras["风电参数"]["年运维成本(元/kw)"],
                    cost_replace = paras["风电参数"]["更换成本(元/kw)"]
                     )
    pv = Photovoltaic(input_GI = GI,input_Ta= TA,
                    unit_capacity = paras["光电参数"]["单机容量(kw)"],
                    machine_number = paras["光电参数"]["机组数量"],
                    A = paras["光电参数"]["光伏板面积(m2)"],
                    λ = paras["光电参数"]["光伏板温度系数"],
                    life_year = paras["光电参数"]["使用年限(年)"],
                    cost_initial = paras["光电参数"]["初始成本(元/kw)"],
                    cost_OM = paras["光电参数"]["年运维成本(元/kw)"],
                    cost_replace = paras["光电参数"]["更换成本(元/kw)"]
                    )
    gt = GasTurbine(outputpower = [0.0 for i in 1:length(ΔT)],
                    unit_capacity = paras["气电参数"]["单机容量(kw)"],
                    machine_number = paras["气电参数"]["机组数量"],
                    load_min = paras["气电参数"]["最小出力效率"],
                    load_change = paras["气电参数"]["出力调整系数"],
                    η = paras["气电参数"]["发电效率"],
                    life_year = paras["气电参数"]["使用年限(年)"],
                    cost_initial = paras["气电参数"]["初始成本(元/kw)"],
                    cost_OM = paras["气电参数"]["年运维成本(元/kw)"],
                    cost_replace = paras["气电参数"]["更换成本(元/kw)"]
                    )
    iv = Inverter(
                    unit_capacity = paras["整流器参数"]["单机容量(kw)"],
                    machine_number = paras["整流器参数"]["机组数量"],
                    η_inverter = paras["整流器参数"]["综合效率"],
                    life_year = paras["整流器参数"]["使用年限(年)"],
                    cost_initial = paras["整流器参数"]["初始成本(元/kw)"],
                    cost_OM = paras["整流器参数"]["年运维成本(元/kw)"],
                    cost_replace = paras["整流器参数"]["更换成本(元/kw)"]
                    )
    ca_es = CompressAirEnergyStorage(
                    unit_capacity = paras["压缩空气储能参数"]["单机容量(kw)"],
                    machine_number = paras["压缩空气储能参数"]["机组数量"],
                    η_charging = paras["压缩空气储能参数"]["充电效率"],
                    life_year = paras["压缩空气储能参数"]["使用年限(年)"],
                    cost_initial = paras["压缩空气储能参数"]["初始成本(元/kw)"],
                    cost_OM = paras["压缩空气储能参数"]["年运维成本(元/kw)"],
                    cost_replace = paras["压缩空气储能参数"]["更换成本(元/kw)"]
                    )
    ec = Electrolyzer(
                    unit_capacity = paras["电解槽参数"]["单机容量(kw)"],
                    machine_number = paras["电解槽参数"]["机组数量"],
                    life_year = paras["电解槽参数"]["使用年限(年)"],
                    cost_initial = paras["电解槽参数"]["初始成本(元/kw)"],
                    cost_OM = paras["电解槽参数"]["年运维成本(元/kw)"],
                    cost_replace = paras["电解槽参数"]["更换成本(元/kw)"]
                    )
    hc = HydrogenCompressor(
                    unit_capacity = paras["氢气压缩机参数"]["单机容量(kg)"],
                    machine_number = paras["氢气压缩机参数"]["机组数量"],
                    consumption = paras["氢气压缩机参数"]["单位耗电量(kWh/kg)"],
                    life_year = paras["氢气压缩机参数"]["使用年限(年)"],
                    cost_initial = paras["氢气压缩机参数"]["初始成本(元/kg)"],
                    cost_OM = paras["氢气压缩机参数"]["年运维成本(元/kg)"],
                    cost_replace = paras["氢气压缩机参数"]["更换成本(元/kg)"]
                    )
    hs = HydrogenStorage(
                    unit_capacity = paras["储氢罐参数"]["单机容量(kg)"],
                    machine_number = paras["储氢罐参数"]["机组数量"],
                    life_year = paras["储氢罐参数"]["使用年限(年)"],
                    cost_initial = paras["储氢罐参数"]["初始成本(元/kg)"],
                    cost_OM = paras["储氢罐参数"]["年运维成本(元/kg)"],
                    cost_replace = paras["储氢罐参数"]["更换成本(元/kg)"]
                    )
    fin = Financial(
                    day = paras["经济性分析参数"]["运行天数"],
                    cost_water_per_kg_H2 = paras["经济性分析参数"]["氢气生产成本(元/kg)"],
                    H2price_sale = paras["经济性分析参数"]["氢气销售价格(元/kg)"],
                    price_gas_per_Nm3 = paras["经济性分析参数"]["天然气价格(元/Nm³)"],
                    cost_unit_transport = paras["经济性分析参数"]["氢气单次运输费用(元/次)"],
                    investment = paras["经济性分析参数"]["投资金额(元)"],
                    H2production = paras["经济性分析参数"]["制氢量(kg)"]
                    )
    op = OptimizeParas(
                    select_obj = opt_paras["select_obj"],
                    select_slo = opt_paras["select_slo"]
                    )
    machines = (wt,pv,gt,iv,ca_es,ec,hc,hs)
    isOpt = isOpt[1:8]
    if opt_paras["select_obj"] == 1
        figure,figure2,table = optimization!(machines,isOpt,fin,op,Val(1))
    elseif opt_paras["select_obj"] == 2
        figure,figure2,table = optimization!(machines,isOpt,fin,op,Val(2))
    elseif opt_paras["select_obj"] == 3
        figure,figure2,table = optimization!(machines,isOpt,fin,op,Val(3))
    end
    figure1 =OrderedDict(
        "风速" => WS,
        "辐射强度" => GI,
    )

    return figure,figure1,figure2,table
end





"""
更新被选择的优化变量值

- machines:项数元组
- isOpt:是否优化的标志,1为优化,0为不优化
"""
function matchOptVars(machines::Tuple, isOpt, new_machines::Vector)
    @assert sum(isOpt) == length(new_machines) "待优化‘变量数’与‘更新变量数组’长度不一致"
    new_index = 1
    for i in eachindex(isOpt)
        if isOpt[i] == 1
            machines[i].capacity = new_machines[new_index]
            new_index += 1
        end
    end
    return machines
end



