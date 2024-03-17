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
- 输出功率 = 装机容量*发电机效率*风轮传动效率*采样时间*(环境风速-切入风速)/(切出风速-环境风速）*3600/1000
- 环境风速大于切出风速 同时 小于截止风速
- 输出功率 = 装机容量*发电机效率*风轮传动效率*采样时间*(截止风速-环境风速)/（环境风速-切出速度）*3600/1000

"""
function outputElectricity(wt::WindTurbine)
    #总小时数
    Number_hours = length(wt.input_v)
    wt_Ele = zeros(Float64,Number_hours)
    speed = @.wt.input_v*10.0
    for i in 1:Number_hours
        if (speed[i] > wt.h3) || (speed[i] < wt.h1)
            wt_Ele[i] = 0.0
        elseif (speed[i] >= wt.h1) && (speed[i] <= wt.h2)
            wt_Ele[i] = wt.capacity * wt.η_g * wt.η_t  * (speed[i]-wt.h1)/(wt.h2-speed[i])
        elseif (speed[i] > wt.h2) && (speed[i] <= wt.h3)
            wt_Ele[i] = wt.capacity * wt.η_g * wt.η_t  * (wt.h3-speed[i])/(speed[i]-wt.h2)
        end
    end
    return wt_Ele
end

"""
- 2号组件:光伏发电
- 'pv' 光伏设备
- 返回在一定光照强度和环境温度下光伏板的发电量 'pv_Ele'
- 光伏输出电量的计算公式(光伏板发电量<=总装机容量)
- 光伏板实际温度 = 实际环境温度 + 辐射温度系数 * 太阳辐射的光照强度
- 光伏发电输出电量 = 机组数量  * 太阳辐射强度 * 光伏板面积  * 光伏板温度修正系数
- 光伏板温度修正系数 = 1 + 0.004 * (光伏板实际温度 - 实际环境温度)

"""
function outputElectricity(pv::Photovoltaic)
    Number_hours = length(pv.input_GI)
    pv_Ele = zeros(Float64,Number_hours)
    pv.actual_T = zeros(Float64,Number_hours)
    pv.actual_T = @.pv.input_Ta+pv.λ * pv.input_GI
    pv_Ele = @.pv.machine_number * pv.A * pv.input_GI/6.83/100 * (1 + 0.004*(pv.actual_T+pv.input_Ta))
    pv_Ele = @.min.(pv_Ele,pv.capacity)
    return pv_Ele
end


"""
3号组件:燃气轮机最低出力 = 总装机容量(kw)*最小出力效率*发电效率
统一单位:1kwh
"""
function outputElectricity(gt::GasTurbine)
    Number_hours = length(gt.outputpower)
    gt.outputpower = zeros(Float64,Number_hours)
    gt.outputpower[1] = gt.capacity*gt.load_min*gt.η
return gt.outputpower
end
