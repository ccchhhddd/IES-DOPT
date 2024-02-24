using BlackBoxOptim
"""
返回优化结果的字典数据

- Val{1}：风光制氢余电上网
- Val{2}：风光制氢余电不上网
- Val{3}：离网制氢
- Val{4}：TODO
- Val{5}：TODO
- Val{6}：TODO
- Val{7}：风光气煤储
- Val{8}：风光煤气氢储
"""
function optimize_ies_ele!(machines::Tuple, isOpt::Vector, fin::Financial, ::Val{1})
    pv, wt, ec, hc, _ = machines
    isOpt = isOpt[1:4]
    obj = function (x)
        # 顺序为光伏、风机、电解槽、储氢，顺序不能错！！！
        machines = matchOptVars((pv, wt, ec, hc), isOpt, x)
        wt_power, pv_power, load_power, hc_power = map(outputEnergy, machines)
        powers = (wt_power, pv_power, load_power, hc_power)
        # 供给-需求=ΔE
        ΔE = wt_power + pv_power - load_power - hc_power
        # 余电上网，网汇购电
        ΔE_to_grid, ΔE_from_grid = pn_split(ΔE)
        # 返回 "制氢价格（元/kg）"，该数值即为待优化的目标值
        dictData = economicAnalysisData(machines, fin, powers,
            (sum(ΔE_to_grid), sum(ΔE_from_grid), 0), Val(1))
        objective = -abs(1 / dictData["静态总投资回收年限（年）"])
        return objective
    end
    # 调用优化求解器，可查BlackBoxOptim.jl文档
    res = bboptimize(obj; SearchRange=(1e1, 1e7),
        NumDimensions=sum(isOpt), TraceMode=:verbose)
    # 输出优化结果
    candidate, fitness = best_candidate(res), best_fitness(res)
    println("优化变量结果： $candidate", "目标值： $fitness")
    machines = matchOptVars((pv, wt, ec, hc), isOpt, candidate)
    # 返回最优解的仿真结果
    return simulate_ies_ele!((machines..., 0), fin, Val(1))
end

# function optimize!(machines::Tuple, isOpt::Vector, fin::Financial, ::Val{2})
#     pv, wt, ec, hc, e_es, ca_es, _ = machines
#     obj = function (x)
#         # 顺序为光伏、风机、电解槽、储氢罐，顺序不能错！！！
#         machines = matchOptVars((pv, wt, ec, hc, e_es, ca_es), isOpt, x)
#         pv_power, wt_power, load_power = map(outputEnergy, (pv, wt, ec))
#         hc.load = outputH2Mass(load_power, ec, 1.0)
#         hc_power = outputEnergy(hc)
#         # 供给-需求=ΔE
#         ΔE = wt_power + pv_power - load_power - hc_power
#         to_es, to_e_es, to_ca_es, es_power, e_es_power, ca_es_power = outputEnergy(e_es, ca_es, ΔE)
#         ΔE -= to_es
#         to_discard, ΔE_from_grid = pn_split(ΔE)
#         to_es, from_es = pn_split(to_es)
#         to_e_es, from_e_es = pn_split(to_e_es)
#         to_ca_es, from_ca_es = pn_split(to_ca_es)

#         powers = (pv_power, wt_power, load_power, hc_power, es_power, e_es_power, ca_es_power)
#         dictData = economicAnalysisData(machines, fin, powers,
#             (0, ΔE_from_grid, sum(to_discard)), Val(2))
#         if e_es.capacity == 0
#             if dictData["网供电量占制氢用电量比例（%）"] > 30 || ec.capacity < maximum(load_power)
#                 return Inf
#             end
#         else
#             if dictData["网供电量占制氢用电量比例（%）"] > 30 || ec.capacity < maximum(load_power) || dictData["风电光伏弃电率（%）"] > 10
#                 return Inf
#             end
#         end
#         # 优化目标
#         return 1.5 * dictData["综合售氢价格（元/kg）"] + dictData["风电光伏弃电率（%）"] + dictData["网供电量占制氢用电量比例（%）"]
#     end
#     # 调用优化求解器，可查BlackBoxOptim.jl文档
#     res = bboptimize(obj; SearchRange=(1e1, 1e7),
#         NumDimensions=sum(isOpt), TraceMode=:verbose)
#     # 输出优化结果
#     candidate, fitness = best_candidate(res), best_fitness(res)
#     candidate = map(x -> x < 10.0 ? 0 : x, candidate)
#     println("优化变量结果： $candidate", "目标值： $fitness")
#     machines = matchOptVars((pv, wt, ec, hc, e_es, ca_es), isOpt, candidate)
#     # 返回最优解的仿真结果
#     return simulate!((machines..., 0), fin, Val(2))
# end

function optimize_ies_ele!(machines::Tuple, isOpt::Vector, fin::Financial, ::Val{2})
    pv, wt, ec, hc, hs, e_es, ca_es, _ = machines
    obj = function (x)
        # 顺序为光伏、风机、电解槽、压缩机、储氢罐，顺序不能错！！！
        machines = matchOptVars((pv, wt, ec, hc, hs, e_es, ca_es), isOpt, x)
        pv_power, wt_power, load_power_base = map(outputEnergy, (pv, wt, ec))
        hc.load = outputH2Mass(load_power_base, ec, 1.0)
        hc_power_base = outputEnergy(hc)
        # 供给-基础负荷=ΔE
        ΔE = wt_power + pv_power - load_power_base - hc_power_base
        to_ec_power, to_hc_power, to_hs, hs_mass, to_es, to_e_es, to_ca_es, es_power, e_es_power, ca_es_power, to_discard, ΔE_from_grid = outputEnergy(ec, hc, hs, e_es, ca_es, ΔE)
        to_es, from_es = pn_split(to_es)
        to_e_es, from_e_es = pn_split(to_e_es)
        to_ca_es, from_ca_es = pn_split(to_ca_es)
        ec_power = load_power_base .+ to_ec_power
        hc_power = hc_power_base .+ to_hc_power

        powers = (pv_power, wt_power, ec_power, hc_power, es_power, e_es_power, ca_es_power, load_power_base)
        dictData = economicAnalysisData(machines, fin, powers,
            (0, ΔE_from_grid, sum(to_discard)), Val(2))
        # if e_es.capacity == 0
        #     if dictData["网供电量占制氢用电量比例（%）"] > 30 || ec.capacity < maximum(load_power_base)
        #         return Inf
        #     end
        # else
            if dictData["网供电量占制氢用电量比例（%）"] > 30 || ec.capacity < maximum(load_power_base) || dictData["风电光伏弃电率（%）"] > 30
                return Inf
            end
        # end
        # 优化目标
        return 5 * dictData["综合含税售氢价格（元/kg）（IRR=6%）"] + 0.1 * dictData["风电光伏弃电率（%）"] + 0.05 * dictData["网供电量占制氢用电量比例（%）"]
    end
    # 调用优化求解器，可查BlackBoxOptim.jl文档
    res = bboptimize(obj; SearchRange=(1e1, 1e7),
        NumDimensions=sum(isOpt), TraceMode=:verbose)
    # 输出优化结果
    candidate, fitness = best_candidate(res), best_fitness(res)
    candidate = map(x -> x < 10.0 ? 0 : x, candidate)
    println("优化变量结果： $candidate", "目标值： $fitness")
    machines = matchOptVars((pv, wt, ec, hc, hs, e_es, ca_es), isOpt, candidate)
    # 返回最优解的仿真结果
    return simulate_ies_ele!((machines..., 0), fin, Val(2))
end

# Val(3)未进行更新
function optimize_ies_ele!(machines::Tuple, isOpt::Vector, fin::Financial, ::Val{3})
    pv, wt, ec, hc, es, _ = machines
    obj = function (x)
        # 顺序为光伏、风机、电解槽、储氢罐，顺序不能错！！！
        machines = matchOptVars((pv, wt, ec, hc, es), isOpt, x)
        wt_power, pv_power, load_power, hc_power = map(outputEnergy, (pv, wt, ec, hc))
        # 供给-需求=ΔE
        ΔE = wt_power + pv_power - load_power - hc_power
        to_es, es_power = outputEnergy(es, ΔE)
        ΔE -= to_es
        ΔE_to_grid, ΔE_from_grid = pn_split(ΔE)
        load_discount = @. 1 + ΔE_from_grid / (load_power + hc_power)
        to_es, from_es = pn_split(to_es)
        powers = (wt_power, pv_power, load_power, hc_power, es_power)
        dictData = economicAnalysisData(machines, fin, powers,
            (0, 0, sum(ΔE_to_grid), load_discount), Val(3))
        # 返回 "制氢价格（元/kg）"，该数值即为待优化的目标值
        return dictData["制氢价格（元/kg）"]
    end
    # 调用优化求解器，可查BlackBoxOptim.jl文档
    res = bboptimize(obj; SearchRange=(1e1, 1e7),
        NumDimensions=sum(isOpt), TraceMode=:verbose)
    # 输出优化结果
    candidate, fitness = best_candidate(res), best_fitness(res)
    println("优化变量结果： $candidate", "目标值： $fitness")
    machines = matchOptVars((pv, wt, ec, hc, es), isOpt, candidate)
    # 返回最优解的仿真结果
    return simulate_ies_ele!((machines..., 0), fin, Val(3))
end

function optimize_ies_ele!(machines::Tuple, isOpt::Vector, fin::Financial, ::Val{7})
    pv, wt, ec, hc, p_es, ca_es, e_es, cp, gp, channelpower = machines
    load_power = generateChannelConstrainData()
    # max_power = maximum(load_power)
    # 目标函数
    obj = function (x)
        # 顺序为光伏、风机、抽水蓄能、压缩空气储能、电化学储能、煤电、气电，顺序不能错！！！
        machines = matchOptVars((pv, wt, p_es, ca_es, e_es, cp, gp), isOpt, x)
        pv_power, wt_power, cp_power_base, gp_power_base = map(outputEnergy, (pv, wt, cp, gp))
        load_power = generateChannelConstrainData(channelpower["winter"], channelpower["summer"])
        # 供给-需求=ΔE
        ΔE = @. wt_power + pv_power + cp_power_base + gp_power_base - load_power
        # 计算煤气电与储能分配
        cp_to_add, gp_to_add, to_es, to_p_es, to_ca_es, to_e_es, es_power, p_es_power, ca_es_power, e_es_power = outputEnergy(gp, cp, p_es, ca_es, e_es, ΔE)
        ΔE += (cp_to_add + gp_to_add - to_es)
        to_discard, ΔE_from_grid = pn_split(ΔE)
        to_es, from_es = pn_split(to_es)
        to_p_es, from_p_es = pn_split(to_p_es)
        to_ca_es, from_ca_es = pn_split(to_ca_es)
        to_e_es, from_e_es = pn_split(to_e_es)
        # from_es = @.from_p_es + from_ca_es + from_e_es
        cp_power = cp_to_add .+ cp_power_base
        gp_power = gp_to_add .+ gp_power_base
        powers = (pv_power, wt_power, cp_power, gp_power, load_power, es_power, p_es_power, ca_es_power, e_es_power)
        # 返回计算结果字典
        dictData = economicAnalysisData(machines, fin, powers,
            (0, sum(ΔE_from_grid), sum(to_discard)), Val(7))
        if dictData["风电光伏弃电率（%）"] > 10 || dictData["新能源电量外送通道占比（%）"] < 50
            return Inf
        end
        # 优化目标
        res = (dictData["综合含税上网电价（元/kWh）（IRR=6%）"] + 0.01 * dictData["主网支撑电量占比（%）"] + 0.005 * dictData["风电光伏弃电率（%）"])
        return res
    end
    # 调用优化求解器，可查BlackBoxOptim.jl文档
    res = bboptimize(obj; SearchRange=(1.0, 2.0e7),
        NumDimensions=sum(isOpt), TraceMode=:verbose)
    # 输出优化结果
    candidate, fitness = best_candidate(res), best_fitness(res)
    candidate = map(x -> x < 10.0 ? 0 : x, candidate)
    println("优化变量结果： $candidate", "目标值： $fitness")
    pv, wt, p_es, ca_es, e_es, cp, gp = matchOptVars((pv, wt, p_es, ca_es, e_es, cp, gp), isOpt, candidate)
    machines = (pv, wt, ec, hc, p_es, ca_es, e_es, cp, gp, channelpower)
    # 返回最优解的仿真结果
    return simulate_ies_ele!(machines, fin, Val(7))
end

function optimize_ies_ele!(machines::Tuple, isOpt::Vector, fin::Financial, ::Val{8})
    pv, wt, ec, hc, es, cp, gp = machines
    electricity_load_power = generateChannelConstrainData(1.0e5 .* [3, 3, 3, 3, 3, 3, 3, 3, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 3, 3, 3, 3, 3, 3], 1.0e5 .* [4, 4, 4, 4, 4, 4, 4, 5.6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 4, 4, 4, 4, 4])
    max_power = maximum(electricity_load_power)
    # 1千瓦时电量制氢产量
    unit_mass = ec.Δt * ec.M_H2 / ec.LHV_H2 * 3.6 * ec.η_EC
    # 电解槽制氢总耗费电量的系数
    coefficient_H2 = (hc.comsumption * unit_mass + 1)
    obj = function (x)
        # 顺序为光伏、风机、电解槽、储氢罐、储能、煤电、气电，顺序不能错！！！
        machines = matchOptVars((pv, wt, ec, hc, es, cp, gp), isOpt, x)
        if cp.capacity + gp.capacity < max_power
            return Inf
        end
        wt_power, pv_power, cp_power_base, gp_power_base = map(outputEnergy, (pv, wt, cp, gp))
        # 供给-需求=ΔE
        ΔE = @. wt_power + pv_power + cp_power_base + gp_power_base - electricity_load_power
        # 计算煤气电与储能分配
        cp_to_add, gp_to_add, to_es, es_power, ec_power = outputEnergy(gp, cp, es, ec, coefficient_H2, ΔE)
        # 计算电解槽和氢压缩机的氢产量负荷
        h2_mass = outputH2Mass(ec_power, ec, coefficient_H2)
        ec.load, hc.load = copy(h2_mass), copy(h2_mass)
        # 添加 煤气电 补充电量 与储能、电解槽的分配
        ΔE += (cp_to_add + gp_to_add - to_es - ec_power)
        to_discard, ΔE_from_grid = pn_split(ΔE)
        to_es, from_es = pn_split(to_es)
        cp_power = cp_to_add .+ cp_power_base
        gp_power = gp_to_add .+ gp_power_base
        powers = (wt_power, pv_power, cp_power, gp_power, electricity_load_power, ec_power, es_power)
        # 返回计算结果字典
        dictData = economicAnalysisData(machines, fin, powers,
            (0, 0, sum(to_discard)), Val(8))

        # 优化目标
        return -dictData["年度现金流收益（亿元）"] / dictData["静态总投资（亿元）"]
    end
    # 调用优化求解器，可查BlackBoxOptim.jl文档
    res = bboptimize(obj; SearchRange=(1e1, 1e7),
        NumDimensions=sum(isOpt), TraceMode=:verbose)
    # 输出优化结果
    candidate, fitness = best_candidate(res), best_fitness(res)
    println("优化变量结果： $candidate", "目标值： $fitness")
    machines = matchOptVars((pv, wt, ec, hc, es, cp, gp), isOpt, candidate)
    # 返回最优解的仿真结果
    return simulate_ies_ele!(machines, fin, Val(8))
end




"""
自制的优化器，用于验证优化器的正确性
- obj：目标函数
- searchRange：搜索范围
- NumDimensions：搜索维度
- TraceMode：追踪模式
"""
function myOptimizer(obj::Function; searchRange::Tuple=(1e5, 1e7), NumDimensions=sum(isOpt), TraceMode...)
    function findMin(level::Int, Min::Vector, x::Vector, searchRange::AbstractRange)
        for range in searchRange
            x[level] = range
            if level == NumDimensions
                o = obj(x)
                if Min[1] > o
                    Min[1:end] = [o, x...]
                end
            else
                findMin(level + 1, Min, x, searchRange)
            end
        end
    end
    x = zeros(NumDimensions)
    Min = [Inf, x...]
    findMin(1, Min, x, range(searchRange[1], searchRange[2], length=100))
    return Min
end


"""
更新被选择的优化变量值

- machines：项数元组
- isOpt：是否优化的标志，1为优化，0为不优化
"""
function matchOptVars(machines::Tuple, isOpt::Vector, new_machines::Vector)
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
