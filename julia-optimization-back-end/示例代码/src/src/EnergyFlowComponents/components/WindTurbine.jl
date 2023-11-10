# WT: WindTurbine
@component function WindTurbine(; name, 
    E_rated=5000.0, Δt=1.0, η_t=0.96, η_g=0.93, h1=10.0, h2=135.0, α=1.0/7.0, η_inverter=1.0,
    life_year=20.0, cost_initial=4800.0, cost_OM=720.0, cost_replace=4800.0)

    @named source = EnergySource()
    @unpack W,Q,m = source
    @named v1 = RealInput()

    @variables v2(t)=0.0

    ps = @parameters(
        E_rated = E_rated, # 额定功率， kW
        Δt = Δt,
        η_t = η_t,
        η_g = η_g,
        h1 = h1,
        h2 = h2,
        α = α,
        η_inverter = η_inverter, # 逆变器效率，如需使用逆变器，则改变此项及成本
        life_year=life_year,
        cost_initial=cost_initial,
        cost_OM=cost_OM,
        cost_replace=cost_replace)

    # 计算风速
    
    expr = k(v2) * E_rated * η_t * η_g * Δt * η_inverter # 电量

    eqs = [
        W ~ expr
        v2 ~ v1.u * (h2/h1)^α
    ]

    sys = compose(ODESystem(eqs, t, [v2], ps; name = name),[v1])

    extend(sys, source)

end

function k(v2)
    kv = ifelse(v2 < 3.0, 0.0,
            ifelse(3.0 <= v2 <9.5, (-30.639*v2^3 + 623.5*v2^2 - 3130.4*v2 + 4928)/5000,
                ifelse(9.5 <= v2 <19.5, 1.0,
                    ifelse(19.5 <= v2 <= 25.0, (-203.97*v2 + 9050.9)/5000, 0.0))))

end
@register_symbolic k(v2)

@component function WindTurbine(params::Dict; name)

    @named source = EnergySource()
    @unpack W,Q,m = source
    @named v1 = RealInput()

    @variables v2(t)=0.0

    ps = @parameters begin
        num_device=get(params, :num_device, 1) # 机组数
        E_device_rated=get(params, :E_device_rated, 5000.0) # 单机容量 kW
        E_rated=get(params, :E_rated, num_device*E_device_rated) # 装机额定容量 kW，如果无输入指定则为 机组数*单机功率
        η_t=get(params, :η_t, 0.96) # 
        η_g=get(params, :η_g, 0.93)  # 
        h1=get(params, :h1, 10.0)    # 
        η_inverter=get(params, :η_inverter, 1.0) # 逆变器效率，如需使用逆变器，则改变此项及成本
        h2=get(params, :h2, 135.0) # 温度系数
        α = get(params, :α, 1.0/7.0)
        Δt=get(params, :Δt, 1.0)
        life_year=get(params, :life_year, 20.0)
        cost_initial=get(params, :cost_initial, 4800.0)
        cost_OM=get(params, :cost_OM, 720.0)
        cost_replace=get(params, :cost_replace, 4800.0)
    end

    # 计算风速
    
    expr = k(v2) * E_rated * η_t * η_g * Δt * η_inverter # 电量

    eqs = [
        W ~ expr
        v2 ~ v1.u * (h2/h1)^α
    ]

    sys = compose(ODESystem(eqs, t, [v2], ps; name = name),[v1])

    extend(sys, source)

end
