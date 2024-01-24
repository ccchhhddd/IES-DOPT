"""
该程序构建模拟了一个小型的PID控制器仿真实验
利用电路构造各个控制器
单位负反馈
输入为阶跃输入
"""



# 导入多项式模块
include("Polynomial.jl")

Meta.parse(x::Number) = x

function solve_pid_I(paras)


    paras = paras["理想PID参数"]
    pid = IdealPid(Meta.parse(paras["K"]),
									Meta.parse(paras["T1"]),
									Meta.parse(paras["T2"]),
        					Meta.parse(paras["Ki"]),
        					Meta.parse(paras["Kj"]),
        					Meta.parse(paras["tspan"])
    )
    ans = solve_pid(pid)
    x = get!(ans, :x, nothing)
    delete!(ans, :x)
    result = Dict()
    for (k, v) in ans
        z = []
        for i in eachindex(v)
            push!(z, [x[i], v[i]])
        end
        push!(result, k => z)
    end
    return result
end
function solve_pid_A(paras)
    paras = paras["实际PID参数"]
    pid = ActualPid(Meta.parse(paras["K"]),
		Meta.parse(paras["T1"]),
		Meta.parse(paras["T2"]),
		Meta.parse(paras["k2"]),
		Meta.parse(paras["Ki"]),
		Meta.parse(paras["Kj"]),
		Meta.parse(paras["tspan"]
    ))
    ans = solve_pid(pid)
    x = get!(ans, :x, nothing)
    delete!(ans, :x)
    result = Dict()
    for (k, v) in ans
        z = []
        for i in eachindex(v)
            push!(z, [x[i], v[i]])
        end
        push!(result, k => z)
    end
    return result
end

# 受控对象为无自平衡能力系统
gp = Fraction([1], [0, 1, 1])

"""
理想PID控制器:\n
控制器传递函数:Gc(s)=K(1+1/(T1s)+T2s)\n
"""
struct IdealPid
    K::Number# 比例常数
    T1::Number# 积分时间常数
    T2::Number# 微分时间常数
    Ki::Number# 设定值
    Kj::Number# 扰动量
    tspan::Number # 仿真结束时间
end

"""
实际PID控制器:\n
控制器传递函数:Gc(s)=K(1+1/(T1s)+k2T2s/(T2s+1))\n
"""
struct ActualPid
    K::Number# 比例常数
    T1::Number# 积分时间常数
    T2::Number# 微分时间常数
    k2::Number# 微分增益
    Ki::Number# 设定值
    Kj::Number# 扰动量
    tspan::Number # 仿真结束时间
end

# 输入函数
global input_x = nothing

"""
生成控制器传递函数
"""
function transfer_function(x::IdealPid)
    if x.T1 == 0 && x.T2 != 0
        # PD控制
        return Polynomial([x.K, x.K * x.T2])
    elseif x.T2 == 0 && x.T1 != 0
        # PI控制
        return Fraction([x.K, x.K * x.T1], [0, x.T1])
    else
        # PID控制
        return Fraction([x.K, x.K * x.T1, x.K * x.T1 * x.T2], [0, x.T1])
    end
end
function transfer_function(x::ActualPid)
    i = Fraction([1], [0, x.T1])
    d = Fraction([0, x.k2 * x.T2], [1, x.T2])
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


"""
仿真问题函数
"""
function pid_simulation!(du, u, p, t)
    A, B = p
    du .= A * u + B * input_x
    nothing
end

"""
仿真问题求解
"""
function solve_pid(x::IdealPid)
    global input_x = [x.Ki, x.Kj]
    gc = transfer_function(x)
    g = [simplify(gc * gp / (Polynomial([1]) + gc * gp)), simplify(gp / (Polynomial([1]) + gc * gp))]
    A = system_matrix(g)
    B = input_matrix(g)
    n = broadcast((x) -> x.denominator.num_of_items - 1, g)
    u0 = zeros(sum(n))
    tspan = (0.0, x.tspan)
    prob = ODEProblem(pid_simulation!, u0, tspan, [A, B])
    sol = solve(prob, Tsit5())
    # 计算输出量,并利用插值使点分布均匀
    C = output_matrix(g)
    D = direct_transmission_matrix(g)
    x₀ = range(0, x.tspan, 50)
    y = []
    for j in eachindex(n)
        y₂ = Number[]
        for i in eachindex(sol.u)
            if j == 1
                y₁ = adjoint(C[1:n[j]]) * sol.u[i][1:n[j]] + adjoint(D) * input_x
            else
                y₁ = adjoint(C[n[j-1]+1:sum(n[1:j])]) * sol.u[i][n[j-1]+1:sum(n[1:j])] + adjoint(D) * input_x
            end
            push!(y₂, y₁)
        end
        itp = Spline1D(sol.t, y₂)
        push!(y, itp(x₀))
    end
    return Dict(:x => x₀, :r => y[1], :d => y[2])
end
function solve_pid(x::ActualPid)
    global input_x = [x.Ki, x.Kj]
    gc = transfer_function(x)
    g = [simplify(gc * gp / (Polynomial([1]) + gc * gp)), simplify(gp / (Polynomial([1]) + gc * gp))]
    n = broadcast((x) -> x.denominator.num_of_items - 1, g)
    A = system_matrix(g)
    B = input_matrix(g)
    u0 = zeros(sum(n))
    tspan = (0.0, x.tspan)
    prob = ODEProblem(pid_simulation!, u0, tspan, [A, B])
    sol = solve(prob, Tsit5())
    # 计算输出量,并利用插值使点分布均匀
    C = output_matrix(g)
    D = direct_transmission_matrix(g)
    x₀ = range(0, x.tspan, 50)
    y = []
    for j in eachindex(n)
        y₂ = Number[]
        for i in eachindex(sol.u)
            if j == 1
                y₁ = adjoint(C[1:n[j]]) * sol.u[i][1:n[j]] + adjoint(D) * input_x
            else
                y₁ = adjoint(C[n[j-1]+1:sum(n[1:j])]) * sol.u[i][n[j-1]+1:sum(n[1:j])] + adjoint(D) * input_x
            end
            push!(y₂, y₁)
        end
        ita = Spline1D(sol.t, y₂)
        push!(y, ita(x₀))
    end
    return Dict(:x => x₀, :r => y[1], :d => y[2])
end
