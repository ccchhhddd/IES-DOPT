# PV:photovoltaic cell
@component function PhotovoltaicCell(; name, E_rated=0.65, Δt=1.0, A=3.1, f_PV=0.8, η_PV_ref=20.9/100,
    λ=-0.34/100, Tc_ref=25.0, tau_alpha=0.9, η_inverter=1.0,
    life_year=20.0, cost_initial=3800.0, cost_OM=190.0, cost_replace=3800.0)

    @named source = EnergySource()
    @unpack W,Q,m = source
    @named GI = RealInput() # Wh/m2
    @named Ta = RealInput()
    @named v = RealInput()

    @variables η(t)=0.0

    ps = @parameters(
        E_rated=E_rated, # 额定功率， kW
        Δt=Δt,
        A=A, # 不使用
        f_PV = f_PV,
        η_PV_ref = η_PV_ref,
        λ = λ,
        Tc_ref = Tc_ref,
        tau_alpha = tau_alpha,
        η_inverter = η_inverter, # 逆变器效率，如需使用逆变器，则改变此项及成本
        life_year=life_year,
        cost_initial=cost_initial,
        cost_OM=cost_OM,
        cost_replace=cost_replace)


    eqs = [
        W ~ η / η_PV_ref * GI.u / 1000 * E_rated * Δt * η_inverter
        η ~ f_PV * η_PV_ref * (1 + λ * (Ta.u - Tc_ref) + 
            λ * GI.u * tau_alpha / (5.7 + 3.8 * v.u) * (1 - η_PV_ref))
    ]

    sys = compose(ODESystem(eqs, t, [η], ps; name = name),[GI,Ta,v])

    extend(sys, source)

end

@component function PhotovoltaicCell(params::Dict; name)

    @named source = EnergySource()
    @unpack W,Q,m = source
    @named GI = RealInput() # Wh/m2
    @named Ta = RealInput()
    @named v = RealInput()

    @variables η(t)=0.0

    ps = @parameters begin
        num_device=get(params, :num_device, 1) # 机组数
        E_device_rated=get(params, :E_device_rated, 0.65*1000) # 单机容量 kW
        E_rated=get(params, :E_rated, num_device*E_device_rated) # 装机额定容量 kW，如果无输入指定则为 机组数*单机功率
        A=get(params, :A, 3.1) # m2
        f_PV=get(params, :f_PV, 0.8)  # 降容系数
        η_PV_ref=get(params, :η_PV_ref, 0.209)    # 额定效率
        η_inverter=get(params, :η_inverter, 1.0) # 逆变器效率，如需使用逆变器，则改变此项及成本
        λ=get(params, :λ, -0.34/100) # 温度系数
        Tc_ref = get(params, :Tc_ref, 25.0)
        tau_alpha = get(params, :tau_alpha, 0.9) # 透射系数
        Δt=get(params, :Δt, 1.0)
        life_year=get(params, :life_year, 20.0)
        cost_initial=get(params, :cost_initial, 3800.0)
        cost_OM=get(params, :cost_OM, 190.0)
        cost_replace=get(params, :cost_replace, 3800.0)
    end

    eqs = [
        W ~ η / η_PV_ref * GI.u / 1000 * E_rated * Δt * η_inverter
        η ~ f_PV * η_PV_ref * (1 + λ * (Ta.u - Tc_ref) + 
            λ * GI.u * tau_alpha / (5.7 + 3.8 * v.u) * (1 - η_PV_ref))
    ]

    sys = compose(ODESystem(eqs, t, [η], ps; name = name),[GI,Ta,v])

    extend(sys, source)

end
