#这里的发电、耗电、负荷均以1小时为单位时间（采样时间）
#设计优化————宏观层面上的设计，不用把单位时间精确到秒，小时的量级即可
#先仿真一个星期（7天）168h的量
#统一一下能量单位：1kwh

#能源装置中发电和耗电相关的函数
"""
- 1号组件:风力发电 
- 'wt' 风机设备
- 返回在一定的风速下风机的发电量 'wt_Ele'
- 单位时间 1h
- 输出功率:统一单位  1kwh
- 风机发电量的计算公式： 

- 环境风速大于截止风速或小于切入风速 
- 输出功率 = 0 
- 环境风速大于等于切入风速 同时 小于等于切出风速 
- 输出功率 = 机组数量*单机容量*发电机效率*风轮传动效率*采样时间*(环境风速-切入风速)/(切出风速-环境风速）*3600/1000
- 环境风速大于切出风速 同时 小于截止风速
- 输出功率 = 机组数量*单机容量*发电机效率*风轮传动效率*采样时间*(截止风速-环境风速)/（环境风速-切出速度）*3600/1000

"""
function outputElectricity(wt::WindTurbine)
    #总小时数
    Number_hours = length(wt.input_v)
    wt_Ele = zeros(Float64,Number_hours)
    for i in 1:Number_hours
        if (wt.input_v[i] > wt.h3) || (wt.input_v[i] < wt.h1)
            wt_Ele[i] = 0.0
        elseif (wt.input_v[i] >= wt.h1) && (wt.input_v[i] <= wt.h2)
            wt_Ele[i] = wt.machine_number * wt.unit_capacity * wt.η_g * wt.η_t * wt.Δt * (wt.input_v[i]-wt.h1)/(wt.h2-wt.input_v[i])*3600/1000
        elseif (wt.input_v[i] > wt.h2) && (wt.input_v[i] <= wt.h3)
            wt_Ele[i] = wt.machine_number * wt.unit_capacity * wt.η_g * wt.η_t * wt.Δt * (wt.h3-wt.input_v[i])/(wt.input_v[i]-wt.h2)*3600/1000
        end
    end
    return wt_Ele
end

"""
- 2号组件:光伏发电 
- 'pv' 光伏设备
- 返回在一定光照强度和环境温度下光伏板的发电量 'pv_Ele'
- 光伏输出电量的计算公式 
- 光伏板实际温度 = 实际环境温度 + 辐射温度系数 * 太阳辐射的光照强度
- 光伏发电输出电量 = 机组数量 * 单机容量 * 太阳辐射强度 * 光伏板面积 * 采样时间 * 光伏板吸收率 * 光伏板实际温度

"""
function outputElectricity(pv::Photovoltaic)
    Number_hours = length(pv.input_GI)
    pv_Ele = zeros(Float64,Number_hours)
    pv.actual_T = zeros(Float64,Number_hours)
    
    for i in 1:Number_hours
        pv.actual_T[i]= pv.input_Ta[i]+pv.λ * pv.input_GI[i]   
    end 

    for i in 1:Number_hours
        pv_Ele[i] = pv.machine_number*pv.unit_capacity * pv.input_GI[i] * pv.A * pv.Δt * pv.tau_alpha * pv.actual_T[i]
    end
    return pv_Ele
end


"""
3号组件:燃气轮机最低出力 = 总装机容量(kw)*最小出力效率*发电效率*采样时间(1h)*3600/1000
统一单位:1kwh
"""
function outputElectricity(gt::GasTurbine)
    #先仿真一个星期（7天）的量
    Number_hours = length(gt.Fuel_rate) 
    gt_Ele = zeros(Float64,Number_hours) 
    gt_Ele[1] = gt.capacity*gt.load_min*gt.η*gt.Δt*3600/1000

return gt_Ele
end