using DifferentialEquations, Dierckx

# 导入传递函数分析模块
include("StateSpace.jl")

global input = () -> ()

"""
仿真问题函数
"""
function simulation!(du, u, p, t)
    A, B = p
    du .= A * u + B * input(t)
    nothing
end

"""
控制系统前处理
"""
function pretreatment(input::Dict)
    link = AbstractLink[]
    lines = map((x) -> (x["nid"]), input["map"])
    sys_map = zeros(length(lines), length(lines))
    for i in eachindex(input["map"])
        sys_map[i, :] += input["map"][i]["nnodes"]
    end
    order = 1
    for id in lines
        msg = input["nodes"][id]
        if msg["type"] == "Sum"
            push!(link, Sum(order))
            order += 1
        elseif msg["type"] == "TransFunction"
            push!(link, Tf(order, Fraction(eval(Meta.parse(msg["num"])), eval(Meta.parse(msg["den"])))))
            order += 1
    		elseif msg["type"] == "ZeroPole"
      			z = eval(Meta.parse(msg["num"]))
      			p = eval(Meta.parse(msg["den"]))
      			push!(link, Tf(order, Fraction(*(map(x->Polynomial([-x,1]),z)...), *(map(x->Polynomial([-x,1]),p)...))))
      			order += 1
        elseif msg["type"] in ["阶跃输入", "斜坡输入", "抛物线输入"]
            push!(link, Input(order, (x) -> basic_input(msg["type"], Meta.parse(msg["args"]["K"]), Meta.parse(msg["args"]["t"]), x)))
            order += 1
        elseif msg["type"] == "output"
            push!(link, Output(order))
            order += 1
        elseif msg["type"] == "P"
            push!(link, Tf(order, Fraction([Meta.parse(msg["Kp"])], [1])))
            order += 1
        elseif msg["type"] == "I"
            push!(link, Tf(order, Fraction([1], [0, Meta.parse(msg["Ti"])])))
            order += 1
        elseif msg["type"] == "D_I"
            push!(link, Tf(order, Fraction([0, Meta.parse(msg["Td"])], [1])))
            order += 1
        elseif msg["type"] == "D_A"
            push!(link, Tf(order, Fraction([0, Meta.parse(msg["Td"]) * Meta.parse(msg["kd"])], [1, Meta.parse(msg["Td"])])))
            order += 1
        end
    end
    return SystemMap(link, sys_map)
end

function solve_by_state_space(space::StateSpace, tend::Number, func::Function)
    # 判断状态量个数,若为零跳过求解
    sol = []
    global input = func
    if space.states != 0
        # 初值必为0
        u0 = zeros(space.states)
        tspan = (0.0, tend)
        prob = ODEProblem(simulation!, u0, tspan, [space.A, space.B])
        sol = solve(prob, Tsit5())
    end
    # 生成输出(对于当前输入的部分)
    t = range(0, tend, 100)
    if isempty(sol)
        return space.D[1, 1] * input.(t)
    else
        y = [(space.C*sol.u[i])[1] + space.D[1, 1] * input(sol.t[i]) for i in eachindex(sol.u)]
        ita = Spline1D(sol.t, y)
        return ita(t)
    end
end

function get_link_by_order(order::Int64, links)
    for i in links
        order == i.order && return i
    end
end

"""
控制系统仿真问题求解主函数
"""
function ControlSystem(msg::Dict)
    @info "正在解析系统参数与结构..."
    sys = pretreatment(msg)
    @info "完成!"
    @info "正在生成传递矩阵..."
    sys_transfer_matrix, iorder, oorder = transfer_matrix(sys)
    inputs = map(iorder) do x
        k = get_link_by_order(x, sys.links)
        return k.expr
    end
    @info "完成!"
    @info "正在生成系统的状态空间..."
    sys_state_space = map(StateSpace, sys_transfer_matrix)
    @info "完成!"
    @info "开始求解..."
    ans = Dict()
    for i in eachindex(oorder)
        out = Dict()
        for j in eachindex(iorder)
            push!(out, msg["map"][iorder[j]]["nid"] => solve_by_state_space(sys_state_space[i, j], 50.0, inputs[j]))
        end
        push!(ans, msg["map"][oorder[i]]["nid"] => out)
    end
    @info "求解结束!"
    return Dict(:x => range(0, 50, 100), :ans => ans)
end
