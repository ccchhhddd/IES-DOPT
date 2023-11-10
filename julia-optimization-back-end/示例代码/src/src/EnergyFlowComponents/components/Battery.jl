# Battery
@component function Battery(; name, E_rated=1000.0, SoC_start=0.0, SoC_min=0.0, SoC_max=1.0,SoC_cha_thre=1.0,
    η_loss=0.2/100/24, η_cha=0.95, η_disc=0.95, ΔSoC_thre_cha=1.0, ΔSoC_thre_disc=1.0, 
    Δt=1.0,life_year=10.0, cost_initial=1000.0, cost_OM=50.0, cost_replace=1000.0)

    @named bat = EnergyStorage(E_rated=E_rated, SoC_start=SoC_start)

    ps = @parameters begin
        E_rated=E_rated # 额定容量 kWh
        SoC_start=SoC_start
        SoC_min=SoC_min
        SoC_max=SoC_max
        SoC_cha_thre=SoC_cha_thre
        η_loss=η_loss
        η_cha=η_cha
        η_disc=η_disc 
        ΔSoC_thre_cha=ΔSoC_thre_cha
        ΔSoC_thre_disc=ΔSoC_thre_disc
        Δt=Δt
        life_year=life_year
        cost_initial=cost_initial
        cost_OM=cost_OM
        cost_replace=cost_replace
    end

    extend(ODESystem(Equation[], t, [], ps; name = name), bat)

end

@component function Battery(params::Dict; name)

    ps = @parameters begin
        num_device=get(params, :num_device, 1) # 机组数
        E_device_rated=get(params, :E_device_rated, 1000.0) # 单机容量 kWh
        E_rated=get(params, :E_rated, num_device*E_device_rated) # 装机额定容量 kWh，如果无输入指定则为 机组数*单机功率
        SoC_start=get(params, :SoC_start, 0.0)
        SoC_min=get(params, :SoC_min, 0.0)
        SoC_max=get(params, :SoC_max, 1.0)
        SoC_cha_thre=get(params, :SoC_cha_thre, 0.0)
        η_loss=get(params, :η_loss, 0.2/100/24)
        η_cha=get(params, :η_cha, 0.95)
        η_disc=get(params, :η_disc, 0.95)
        ΔSoC_thre_cha=get(params, :ΔSoC_thre_cha, 1.0)
        ΔSoC_thre_disc=get(params, :ΔSoC_thre_disc, 1.0)
        Δt=get(params, :Δt, 1.0)
        life_year=get(params, :life_year, 10.0)
        cost_initial=get(params, :cost_initial, 1000.0)
        cost_OM=get(params, :cost_OM, 50.0)
        cost_replace=get(params, :cost_replace, 1000.0)
    end

    @named bat = EnergyStorage(E_rated=E_rated, SoC_start=SoC_start)

    extend(ODESystem(Equation[], t, [], ps; name = name), bat)

end

