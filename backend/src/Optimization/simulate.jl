"""
返回仿真结果的字典数据
- cost_H2 '每方氢气的成本'

- 离网制氢（风、光、燃气轮机、整流器、电解槽、压缩空气储能、电解槽、氢气压缩机、储氢罐、燃料电池、经济性分析）
"""
function simulate!(machines::Tuple,fin::Financial)
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

    #计算最终氢气的体积
    hydrogen_final_V = hydrogen_M[end] /2*22.4

    machine_cost = cost_wt+cost_pv+cost_gt+cost_iv+cost_ca_es+cost_ec+cost_hc+cost_hs
    #目前计算总成本的时候不考虑取样时间和系统设备寿命之间的关系
    #(可能会导致计算结果中运行时间越短单位氢气成本越高)
    #计算总成本 = 水成本 + 天然气成本 + 设备成本(投资+运维+更换)
    cost_total = costWater(water,fin)+costGas(natural_gas,fin)+costH2Transport(hydrogen_M[end],hs,fin) + machine_cost
    
    #计算单位氢气成本
    cost_H2 = costH2(hydrogen_final_V,cost_total)

        #绘制风力发电、光伏发电、燃气轮机发电、储氢罐储氢量、总储氢量曲线
        x = 1 : length(wt.input_v)
        pv_power = outputElectricity(pv)
        wt_power = outputElectricity(wt)
        gt_power = gt.outputpower
        H2_unit = hs.load
        H2_total = hydrogen_M
        display(plot(x,pv_power,label="pv"))
        display(plot(x,wt_power,label="wt"))
        display(plot(x,gt_power,label="gt"))
        display(plot(x,H2_unit,label="H2_unit"))
        display(plot(x,H2_total,label="H2_total"))

    #返回仿真结果的字典数据
    table = Dict(
                "风力发电装机数" => wt.machine_number,
                "风力发电总装机容量(kw)" => wt.capacity,
                "光伏发电装机数" => pv.machine_number,
                "光伏发电总装机容量(kw)" => pv.capacity,
                "燃气轮机发电装机数" => gt.machine_number,
                "燃气轮机发电总装机容量(kw)" => gt.capacity,
                "整流器装机数" => iv.machine_number,
                "整流器总装机容量(kw)" => iv.capacity,
                "压缩空气储能装机数" => ca_es.machine_number,
                "压缩空气储能总装机容量(kw)" => ca_es.capacity,
                "电解槽装机数" => ec.machine_number,
                "电解槽总装机容量(kw)" => ec.capacity,
                "氢气压缩机装机数" => hc.machine_number,
                "氢气压缩机总装机容量(kg)" => hc.capacity,
                "储氢罐装机数" => hs.machine_number,
                "储氢罐总装机容量(kg)" => hs.capacity,
                "每方氢气的成本(元/m³)" => cost_H2,
                "总成本(元)" => cost_total,
                "制氢量(kg)"=> hydrogen_M[end])

	figure = figureDictData(wt_power, pv_power, gt_power)
    figure2 = figureDictData2(H2_unit)
    return figure,figure2,table
end


#API
function simulate!(paras, area, ::Val{1})
    day = paras["经济性分析参数"]["运行天数"]
    ΔT = [1.0 for i in 1:24* day  ]
    if area == 1
        data_weather = CSV.File("src/data/weather_Yulin_2005.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
        data_weather0 = CSV.File("src/data/weather_Yulin_2005.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
    elseif area == 2
        data_weather = CSV.File("src/data/weather_Ruoqiang_2005.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
        data_weather0 = CSV.File("src/data/weather_Ruoqiang_2005.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
    elseif area == 3
        data_weather = CSV.File("src/data/weather_Lenghu_2018.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
        data_weather0 = CSV.File("src/data/weather_Lenghu_2018.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
    elseif area == 4
        data_weather = CSV.File("src/data/weather_Haixi_Delingha_2021.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
        data_weather0 = CSV.File("src/data/weather_Haixi_Delingha_2021.CSV"; select=["glob_hor_rad", "DBT", "wind_speed"])|> DataFrame
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
                    )
    machines = (wt,pv,gt,iv,ca_es,ec,hc,hs)
    figure,figure2,table = simulate!(machines,fin)
    figure1 =OrderedDict(
        "风速" => WS,
        "辐射强度" => GI,
    )
    return figure,figure1,figure2,table
end   