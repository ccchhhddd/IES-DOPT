# ElectrolyticCell
@component function ElectrolyticCell(; name,  
    E_rated=5000.0, Δt=1.0, η_EC=0.6, LHV_H2=241, M_H2=2,η_inverter=1.0,η_load_min=0.0,
    life_year=10.0, cost_initial=2000.0, cost_OM=100.0, cost_replace=2000.0)

    @named source = EnergySource()
    @unpack W,Q,m = source
    @named W_source = RealInput()


    ps = @parameters(
        Δt = Δt,
        E_rated = E_rated, # 额定功率， kW
        η_EC = η_EC,
        LHV_H2 = LHV_H2,
        M_H2 = M_H2,
        η_inverter = η_inverter, # 逆变器效率，如需使用逆变器，则改变此项及成本
        η_load_min = η_load_min, # 最小负载
        life_year=life_year,
        cost_initial=cost_initial,
        cost_OM=cost_OM,
        cost_replace=cost_replace)

    W_idea = min(W_source.u*η_inverter, E_rated * Δt)
    W_min = E_rated * Δt * η_load_min

    eqs = [
        W ~ ifelse(W_idea < W_min, 0, W_idea)
        m ~ W * M_H2 / LHV_H2 * 3600 / 1000 * η_EC
    ]

    sys = compose(ODESystem(eqs, t, [], ps; name = name),[W_source])

    extend(sys, source)

end

@component function ElectrolyticCell(params::Dict; name)

    @named source = EnergySource()
    @unpack W,Q,m = source
    @named W_source = RealInput()

    ps = @parameters begin
        num_device=get(params, :num_device, 1) # 机组数
        E_device_rated=get(params, :E_device_rated, 5000.0) # 单机容量 kW
        E_rated=get(params, :E_rated, num_device*E_device_rated) # 装机额定容量 kW，如果无输入指定则为 机组数*单机功率
        η_EC=get(params, :η_EC, 0.6)
        LHV_H2=get(params, :LHV_H2, 241)  # kJ/mol H2
        M_H2=get(params, :M_H2, 2.0)    # g/mol H2
        η_inverter=get(params, :η_inverter, 1.0) # 逆变器效率，如需使用逆变器，则改变此项及成本
        η_load_min=get(params, :η_load_min, 0.0) # 最小负载
        Δt=get(params, :Δt, 1.0)
        life_year=get(params, :life_year, 20.0)
        cost_initial=get(params, :cost_initial, 2000.0)
        cost_OM=get(params, :cost_OM, 100.0)
        cost_replace=get(params, :cost_replace, 2000.0)
    end

    W_idea = min(W_source.u*η_inverter, E_rated * Δt)
    W_min = E_rated * Δt * η_load_min

    eqs = [
        W ~ ifelse(W_idea < W_min, 0, W_idea)
        m ~ W * M_H2 / LHV_H2 * 3600 / 1000 * η_EC
    ]

    sys = compose(ODESystem(eqs, t, [], ps; name = name),[W_source])

    extend(sys, source)

end
