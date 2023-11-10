# Compressed Hydrogen storage tank
@component function CompressedH2Tank(; name, E_rated=1000.0, 
    W_comp_per_kgH2=1.0, SoC_start=0.0, SoC_min=0.0, SoC_max=1.0, SoC_cha_thre=1.0,
    η_loss=0.0, η_cha=1.0, η_disc=1.0, ΔSoC_thre_cha=1.0, ΔSoC_thre_disc=1.0, 
    Δt=1.0,life_year=20.0, cost_initial=2300.0, cost_OM=46.0, cost_replace=2300.0)

    @named ht = EnergyStorage(E_rated=E_rated, SoC_start=SoC_start)
    @unpack ΔE, W_consume = ht

    ps = @parameters begin
        E_rated=E_rated # 额定容量，kg
        W_comp_per_kgH2=W_comp_per_kgH2
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

    eqs = [
        W_consume ~ W_comp_per_kgH2 * max(0, ΔE)
    ]

    extend(ODESystem(eqs, t, [], ps; name = name), ht)

end

@component function CompressedH2Tank(params::Dict; name)

    ps = @parameters begin
        num_device=get(params, :num_device, 1) # 机组数
        E_device_rated=get(params, :E_device_rated, 1000.0) # 单机容量 kg
        E_rated=get(params, :E_rated, num_device*E_device_rated) # 装机额定容量 kg，如果无输入指定则为 机组数*单机功率        
        W_comp_per_kgH2=get(params, :W_comp_per_kgH2, 1.0) # 压缩机耗电 kWh/kg H2
        SoC_start=get(params, :SoC_start, 0.0)
        SoC_min=get(params, :SoC_min, 0.0)
        SoC_max=get(params, :SoC_max, 1.0)
        SoC_cha_thre=get(params, :SoC_cha_thre, 0.0)
        η_loss=get(params, :η_loss, 0.0)
        η_cha=get(params, :η_cha, 1.0)
        η_disc=get(params, :η_disc, 1.)
        ΔSoC_thre_cha=get(params, :ΔSoC_thre_cha, 1.0)
        ΔSoC_thre_disc=get(params, :ΔSoC_thre_disc, 1.0)
        Δt=get(params, :Δt, 1.0)
        life_year=get(params, :life_year, 20.0)
        cost_initial=get(params, :cost_initial, 2300.0)
        cost_OM=get(params, :cost_OM, 46.0)
        cost_replace=get(params, :cost_replace, 2300.0)
    end

    @named ht = EnergyStorage(E_rated=E_rated, SoC_start=SoC_start)
    @unpack ΔE, W_consume = ht

    eqs = [
        W_consume ~ W_comp_per_kgH2 * max(0, ΔE)
    ]

    extend(ODESystem(eqs, t, [], ps; name = name), ht)

end
