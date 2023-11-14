using BlackBoxOptim
"""
返回优化结果的字典数据

- Val{1}：离网制氢

"""

function optimize!(machines::Tuple, isOpt::Vector, fin::Financial, ::Val{3})
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
    return simulate!((machines..., 0), fin, Val(3))
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
