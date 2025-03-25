```julia
"""
生成控制器传递函数
"""
function transfer_function(x::IdealPid)
    if x.T1 == 0 && x.T2 != 0
        # PD控制
        return Polynomial1([x.K, x.K * x.T2])
    elseif x.T2 == 0 && x.T1 != 0
        # PI控制
        return Fraction1([x.K, x.K * x.T1], [0, x.T1])
    else
        # PID控制
        return Fraction1([x.K, x.K * x.T1, x.K * x.T1 * x.T2], [0, x.T1])
    end
end
function transfer_function(x::ActualPid)
    i = Fraction1([1], [0, x.T1])
    d = Fraction1([0, x.k2 * x.T2], [1, x.T2])
    if x.T1 == 0 && x.T2 != 0
        # PD控制
        return x.K * (1 + d)
    elseif x.T2 == 0 && x.T1 != 0
        # PI控制
        return x.K * (1 + i)
    else
        # PID控制
        return x.K * (1 + i + d)
    end
end

"""
单位正阶跃函数
"""
function positive_step(t; τ₀=0.0)
    if t <= τ₀
        return 0
    else
        return 1
    end
end

```
