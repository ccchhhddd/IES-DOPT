# Inverter:已内置到源设备，不单独使用
@component function Inverter(; name, η=0.95, 
    Δt=1.0,life_year=20.0, cost_initial=100.0, cost_OM=5.0, cost_replace=100.0)

    @named W_input = RealInput()
    @variables W(t)

    ps = @parameters begin
        η=η
        Δt=Δt
        life_year=life_year
        cost_initial=cost_initial
        cost_OM=cost_OM
        cost_replace=cost_replace
    end

    eqs = [
        W ~ η * W_input.u
    ]

    compose(ODESystem(eqs, t, [W], ps; name = name),[W_input])

end

