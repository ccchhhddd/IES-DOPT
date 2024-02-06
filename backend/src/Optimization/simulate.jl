"""
返回仿真结果的字典数据
- cost_H2 '每方氢气的成本'

- 离网制氢（风、光、燃气轮机、整流器、电解槽、压缩空气储能、电解槽、氢气压缩机、储氢罐、燃料电池、经济性分析）
"""
function simulate!(machines::Tuple, fin::Financial)
    wt,pv,gt,iv,ca_es,ec,hc,hs= machines

    #一周时间后所制取的氢气 和 燃气轮机所需发电总量
    hydrogen_M,sum_gt_Ele = outputHydrogen(wt,pv,gt,iv,ca_es,ec,hc,hs)
    #计算用水量
    water = hydrogen_M[end]*9
    #计算用天然气总量=(燃烧的天然气量=所需用电量/发电效率*3600*1000/1e5/天然气低位发热值) Nm³
    natural_gas = sum_gt_Ele/gt.η*3600*1000/1e5/gt.lhv_gas
    
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
    #计算总成本 = 水成本 + 天然气成本 + 设备成本(投资+运维+更换)
    cost_total = costWater(water,fin)+costGas(natural_gas,fin)+machine_cost
    
    #计算最终氢气的体积
    hydrogen_final_V = hydrogen_M[end] /2*22.4
    cost_H2 = costH2(hydrogen_final_V,cost_total)


    #返回仿真结果的字典数据
    table = OrderedDict("每方氢气的成本(元/m³)" => cost_H2)
    x = [i for i in 1:length(wt.input_v)]
	y1 = hydrogen_M
	figure = transposeMatrix(x, y1)
    plot_local(figure)
    return figure,table
end


#API
function simulate!(paras, ::Val{1})
    day = paras["经济性分析参数"]["运行天数"]
    ΔT = [1.0 for i in 1:24* day  ]
    wt = WindTurbine(input_v = [6*(1+sin(2*pi*i/24)) for i in 1:length(ΔT)],
                    capacity = paras["风力发电参数"]["总装机容量(kW)"],
                    unit_capacity= paras["风力发电参数"]["单机容量(kW)"],
                    machine_number = paras["风力发电参数"]["机组数量"],
                    η_t = paras["风力发电参数"]["风轮传动效率"],
                    η_g = paras["风力发电参数"]["发电机效率"],
                    life_year = paras["风力发电参数"]["使用年限(年)"],
                    cost_initial = paras["风力发电参数"]["初始成本(元/kW)"],
                    cost_OM = paras["风力发电参数"]["年运维成本(元/kW)"],
                    cost_replace = paras["风力发电参数"]["更换成本(元/kW)"]
                     )
    pv = Photovoltaic(input_GI = [10^7*(1+sin(2*pi*i/24)) for i in 1:length(ΔT)],input_Ta= [30*(sin(2*pi*i/24)) for i in 1:length(ΔT)],
                    capacity = paras["光伏发电参数"]["总装机容量(kW)"],
                    unit_capacity = paras["光伏发电参数"]["单机容量(kW)"],
                    machine_number = paras["光伏发电参数"]["机组数量"],
                    A = paras["光伏发电参数"]["光伏板面积(m2)"],
                    tau_alpha = paras["光伏发电参数"]["光伏板吸收率"],
                    life_year = paras["光伏发电参数"]["使用年限(年)"],
                    cost_initial = paras["光伏发电参数"]["初始成本(元/kW)"],
                    cost_OM = paras["光伏发电参数"]["年运维成本(元/kW)"],
                    cost_replace = paras["光伏发电参数"]["更换成本(元/kW)"]
                    )
    gt = GasTurbine(Fuel_rate = [0.0 for i in 1:length(ΔT)],
                    capacity = paras["燃气轮机发电参数"]["总装机容量(kW)"],
                    load_min = paras["燃气轮机发电参数"]["最小出力效率"],
                    load_change = paras["燃气轮机发电参数"]["出力调整系数"],
                    η = paras["燃气轮机发电参数"]["发电效率"],
                    lhv_gas = paras["燃气轮机发电参数"]["低位发热值(MJ/Nm³)"],
                    life_year = paras["燃气轮机发电参数"]["使用年限(年)"],
                    cost_initial = paras["燃气轮机发电参数"]["初始成本(元/kW)"],
                    cost_OM = paras["燃气轮机发电参数"]["年运维成本(元/kW)"],
                    cost_replace = paras["燃气轮机发电参数"]["更换成本(元/kW)"]
                    )
    iv = Inverter(
                    capacity = paras["整流器参数"]["装机额定功率(kW)"],
                    η_inverter = paras["整流器参数"]["整流器综合效率"],
                    life_year = paras["整流器参数"]["使用年限(年)"],
                    cost_initial = paras["整流器参数"]["初始成本(元/kg)"],
                    cost_OM = paras["整流器参数"]["年运维成本(元/kg)"],
                    cost_replace = paras["整流器参数"]["更换成本(元/kg)"]
                    )
    ca_es = CompressAirEnergyStorage(
                    capacity = paras["压缩空气储能参数"]["装机额定功率(kW)"],
                    η_charging = paras["压缩空气储能参数"]["充电效率"],
                    life_year = paras["压缩空气储能参数"]["使用年限(年)"],
                    cost_initial = paras["压缩空气储能参数"]["初始成本(元/kW)"],
                    cost_OM = paras["压缩空气储能参数"]["年运维成本(元/kW)"],
                    cost_replace = paras["压缩空气储能参数"]["更换成本(元/kW)"]
                    )
    ec = Electrolyzer(
                    capacity = paras["电解槽参数"]["额定功率(kW)"],
                    LHV_H2 = paras["电解槽参数"]["氢燃料低位发热值(MJ/kg)"],
                    η_load_min = paras["电解槽参数"]["负载最小效率"],
                    life_year = paras["电解槽参数"]["使用年限(年)"],
                    cost_initial = paras["电解槽参数"]["初始成本(元/kW)"],
                    cost_OM = paras["电解槽参数"]["年运维成本(元/kW)"],
                    cost_replace = paras["电解槽参数"]["更换成本(元/kW)"]
                    )
    hc = HydrogenCompressor(
                    capacity = paras["氢气压缩机参数"]["装机容量(kg)"],
                    consumption = paras["氢气压缩机参数"]["单位耗电量(kWh/kg)"],
                    life_year = paras["氢气压缩机参数"]["使用年限(年)"],
                    cost_initial = paras["氢气压缩机参数"]["初始成本(元/kg)"],
                    cost_OM = paras["氢气压缩机参数"]["年运维成本(元/kg)"],
                    cost_replace = paras["氢气压缩机参数"]["更换成本(元/kg)"]
                    )
    hs = HydrogenStorage(
                    capacity = paras["储氢罐参数"]["装机容量(kg)"],
                    life_year = paras["储氢罐参数"]["使用年限(年)"],
                    cost_initial = paras["储氢罐参数"]["初始成本(元/kg)"],
                    cost_OM = paras["储氢罐参数"]["年运维成本(元/kg)"],
                    cost_replace = paras["储氢罐参数"]["更换成本(元/kg)"]
                    )
    fin = Financial(
                    
                    n_sys = paras["经济性分析参数"]["系统设计寿命(年)"],
                    cost_water_per_kg_H2 = paras["经济性分析参数"]["氢气生产成本(元/kg)"],
                    H2price_sale = paras["经济性分析参数"]["氢气销售价格(元/kg)"],
                    price_gas_per_Nm3 = paras["经济性分析参数"]["天然气价格(元/Nm³)"]
                    )
    machines = (wt,pv,gt,iv,ca_es,ec,hc,hs)
    cost_H2_hhh = simulate!(machines,fin)
    return cost_H2_hhh
end   