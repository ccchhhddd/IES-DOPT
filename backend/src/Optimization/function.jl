"""

返回两个数组转化的n*2维数组,用于绘图
- `xAxis` x轴数据
- `yAxis` y轴数据
"""
function transposeMatrix(xAxis, yAxis)
    result = [[xAxis[i], yAxis[i]] for i in 1:length(yAxis)]
    #println(result)
    return result
end

"""
绘制data图像
- `data` n*2维数组

"""
function plot_local(data)
     # 提取x和y坐标
     xa = [point[1] for point in data]
     ya = [point[2] for point in data]
     # 创建散点图
    fig = plot(xa, ya, label="数据点",fontfamily="Arial", markersize=6)
    display(fig)
end

"""
 add_table(wt::WindTurbine,pv::Photovoltaic,gt::GasTurbine,iv::Inverter,ca_es::CompressAirEnergyStorage,ec::Electrolyzer,hc::HydrogenCompressor,hs::HydrogenStorage, isOpt::Array, candidate::Array)
 
 返回输出优化表格
 
"""
function add_table(wt::WindTurbine,pv::Photovoltaic,gt::GasTurbine,iv::Inverter,ca_es::CompressAirEnergyStorage,ec::Electrolyzer,hc::HydrogenCompressor,hs::HydrogenStorage, isOpt::Array, candidate::Array)
    i = 1
    table = Dict()
    if isOpt[1] == 1
        table["风力发电装机数"] = round(candidate[i]/wt.unit_capacity)
        table["风力发电总装机容量(kw)"] = table["风力发电装机数"]*wt.unit_capacity
        wt.capacity = table["风力发电总装机容量(kw)"]
        wt.machine_number = table["风力发电装机数"]
        i += 1
    end
    if isOpt[2] == 1
        table["光伏发电装机数"] = round(candidate[i]/pv.unit_capacity)
        table["光伏发电总装机容量(kw)"] = table["光伏发电装机数"]*pv.unit_capacity
        pv.capacity = table["光伏发电总装机容量(kw)"]
        pv.machine_number = table["光伏发电装机数"]
        i += 1
    end
    if  isOpt[3] == 1
        table["燃气轮机发电装机数"] = ceil(candidate[i]/gt.unit_capacity)
        table["燃气轮机发电总装机容量(kw)"] = table["燃气轮机发电装机数"]*gt.unit_capacity
        gt.capacity = table["燃气轮机发电总装机容量(kw)"]
        gt.machine_number = table["燃气轮机发电装机数"]
        i += 1
    end
    if  isOpt[4] == 1
        table["整流器装机数"] = round(candidate[i]/iv.unit_capacity)
        table["整流器总装机容量(kw)"] = table["整流器装机数"]*iv.unit_capacity
        iv.capacity = table["整流器总装机容量(kw)"]
        iv.machine_number = table["整流器装机数"]
        i += 1
    end
    if  isOpt[5] == 1
        table["压缩空气储能装机数"] = round(candidate[i]/ca_es.unit_capacity)
        table["压缩空气储能总装机容量(kw)"] = table["压缩空气储能装机数"]*ca_es.unit_capacity
        ca_es.capacity = table["压缩空气储能总装机容量(kw)"]
        ca_es.machine_number = table["压缩空气储能装机数"]
        i += 1
    end
    if  isOpt[6] == 1
        table["电解槽装机数"] = round(candidate[i]/ec.unit_capacity)
        table["电解槽总装机容量(kw)"] = table["电解槽装机数"]*ec.unit_capacity
        ec.capacity = table["电解槽总装机容量(kw)"]
        ec.machine_number = table["电解槽装机数"]
        i += 1
    end
    if  isOpt[7] == 1
        table["氢气压缩机装机数"] = round(candidate[i]/hc.unit_capacity)
        table["氢气压缩机总装机容量(kg)"] = table["氢气压缩机装机数"]*hc.unit_capacity
        hc.capacity = table["氢气压缩机总装机容量(kg)"]
        hc.machine_number = table["氢气压缩机装机数"]
        i += 1
    end
    if  isOpt[8] == 1
        table["储氢罐装机数"] = round(candidate[i]/hs.unit_capacity)
        table["储氢罐总装机容量(kg)"] = table["储氢罐装机数"]*hs.unit_capacity
        hs.capacity = table["储氢罐总装机容量(kg)"]
        hs.machine_number = table["储氢罐装机数"]
        i += 1
    end
    return table
end

"""
figureDictData(wt_power, pv_power, gt_power)

    返回绘图数据字典

- `wt_power` 风力发电功率(kw)
- `pv_power` 光伏发电功率(kw)
- `gt_power` 内燃机发电功率(kw)

"""
figureDictData(wt_power, pv_power, gt_power) = OrderedDict(
    "风力发电功率(kw)" => round.(wt_power / 1e4, digits=2),
    "光伏发电功率(kw)" => round.(pv_power / 1e4, digits=2),
    "内燃机发电功率(kw)" => round.(gt_power / 1e4, digits=2),
)

"""
figureDictData2(H2_unit)

    返回绘图数据字典

- `H2_unit` 单位制氢量(kg/h)

"""
figureDictData2(H2_unit) = OrderedDict(
    "单位制氢量(kg/h)" => round.(H2_unit / 1e2, digits=2),
)