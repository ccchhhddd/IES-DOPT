#产氢、用气过程中的函数
"""
电解槽产氢 
    电解槽氢气总产生率max(kg/h) = (0.0046+0.0030*电解槽额定功率)/1000*3600
    电解槽氢气总产生率(kg/h) =  (0.0046+0.0030*输入电功率)/1000*3600
"""
outputHydrogen(ec::Electrolyzer) = (0.0046+0.003*ec.capacity)/1000*3600

outputHydrogen(Elc_load::Float64) = (0.0046+0.003*Elc_load)/1000*3600

"""
计算在一个时间段后制取的氢气量
同时通过下面这个式子也可以得到 燃气轮机功率和储能在这个时间段内的变化量

返回
'hs.capacity':储氢罐储氢量
'sum_gt_Ele':燃气轮机在这一段时间内的发电总量
"""
function outputHydrogen(wt::WindTurbine,pv::Photovoltaic,gt::GasTurbine,iv::Inverter,ca_es::CompressAirEnergyStorage,ec::Electrolyzer,hc::HydrogenCompressor,hs::HydrogenStorage)
    #先做一周的仿真
    Number_hours = length(wt.input_v)

    pv_Ele = outputElectricity(pv)
    wt_Ele = outputElectricity(wt)
    gt_Ele = outputElectricity(gt)

    iv.P_input = zeros(Float64,Number_hours)
    iv.P_output = zeros(Float64,Number_hours)
    hs.load = zeros(Float64,Number_hours)
    ca_es.load = zeros(Float64,Number_hours)
    sum_gt_Ele::Float64 = 0
    for i in 1:Number_hours
        # 第一小时 输入给整流器的电力总量 = (光+风+最低出力的燃气轮机)
        iv.P_input[i] = pv_Ele[i] + wt_Ele[i] + gt_Ele[i]
        # 第一小时 整流器输出的电力总量=(光+风+最低出力的燃气轮机)*整流器综合效率
        iv.P_output[i] = iv.P_input[i] * iv.η_inverter
        # ΔE_limit = 供给-需求max
        ΔE_limit = iv.P_output[i] - (ec.capacity + outputHydrogen(ec)*hc.consumption)
        # 供<求(ΔE_limit<0) :
        #储能不充电
        #制氢量等于供给量转化的氢气量
        #同时下一时间的燃气轮机功率增加5%(出力调整系数)
        #若i>=2还要考虑储能放电：
            if ΔE_limit <= 0 
                if i == 1
                ca_es.load[1] = 0
                hs.load[1]= outputHydrogen(iv.P_output[1])

                #i>=2
                else
                ca_es.load[i] = ca_es.load[i-1]
        #若储能全部放出后超出电解槽和氢气压缩机所能工作的最大功率,计算剩下的储能量和总制氢量
                    if ca_es.load[i] > -ΔE_limit
                        ca_es.load[i] = ca_es.load[i] - ΔE_limit
                        hs.load[i]= outputHydrogen(ec) + hs.load[i-1]
                    
        #若储能全部放出后没有超出电解槽和氢气压缩机所能工作的最大功率,电解槽和氢气压缩机的最大功率,制氢量重新计算,剩下的储能量=0 
                    else
                        hs.load[i]= outputHydrogen(ca_es.load[i]) + hs.load[i-1]
                        ca_es.load[i] = 0
                    end
                end
        #这里还需要判断一下调整燃气轮机出力功率后下一时刻的功率是否达到了装机容量
            gt_Ele[i+1] = gt_Ele[i]* (1+gt.load_change)
            if gt_Ele[i+1] >= gt.capacity
                gt_Ele[i+1] = gt.capacity
            else
                #燃气轮机功率调整
                gt_Ele[i+1] = gt_Ele[i]* (1+gt.load_change)
            end

        # 供>求(ΔE_limit>0) :
        #储能充电
        #制氢量等于电解槽在额定容量下制取的氢气,氢气送到储氢罐中
        #同时下一时间的燃气轮机功率减少5%(出力调整系数)
            else
                if i == 1
                    ca_es.load[1] = ΔE_limit
                else
                    ca_es.load[i] = ca_es.load[i-1]+ΔE_limit
                    #这里需要判断一下，看储能是否达到了最大值
                    #如果大于,多余的储能弃掉,此时储能的量等于装机容量
                    if ca_es.load[i] >= ca_es.capacity*3600/1000
                        ca_es.load[i] = ca_es.capacity*3600/1000
                    #如果小于,无影响
                    else 
                        ca_es.load[i] = ca_es.load[i]
                    end
    
                    hs.load[i] = hs.load[i-1]+ outputHydrogen(ec)
                end
            #燃气轮机功率调整
            if i < Number_hours
                gt_Ele[i+1] = gt_Ele[i]* (1-gt.load_change)
            end
        end
    end
    #求一下燃气轮机在这一段时间内燃气轮机发电总量
    for i in 1:Number_hours
        sum_gt_Ele += gt_Ele[i]
    end
    
    return hs.load,sum_gt_Ele
end
