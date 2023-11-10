

"""

Connector with one input signal of type Real.

# Parameters:
- `nin=1`: Number of inputs
- `u_start=0`: Initial value for `u`  

# States:
- `u`: Value of of the connector; if nin=1 this is a scalar
"""
@connector function RealInput(; name, nin=1, u_start=nin > 1 ? zeros(nin) : 0.0)
    if nin == 1
        @variables u(t) = u_start [input = true]
    else
        @variables u(t)[1:nin] = u_start [input = true]
        u = collect(u)
    end
    ODESystem(Equation[], t, [u...], []; name=name)
end
"""
Connector with one output signal of type Real.

# Parameters:
- `nout=1`: Number of inputs
- `u_start=0`: Initial value for `u`  

# States:
- `u`: Value of of the connector; if nout=1 this is a scalar
"""
@connector function RealOutput(; name, nout=1, u_start=nout > 1 ? zeros(nout) : 0.0)
    if nout == 1
        @variables u(t) = u_start [output = true]
    else
        @variables u(t)[1:nout] = u_start [output = true]
        u = collect(u)
    end
    ODESystem(Equation[], t, [u...], []; name=name)
end

"""

Generate constant signal.

# Parameters:
- `U`: Constant output value

# Connectors:
- `u`
"""
function Constant(; name, U=1)
    @named u = RealOutput()
    pars = @parameters U = U
    eqs = [
        u.u ~ U,
    ]
    compose(ODESystem(eqs, t, [], pars; name=name), [u])
end
"""

Generate secrete signal.

# Parameters:
- data: time-series array
- name: the name of datafile
- output_type: the type of sample time includes `s` or `min` or `hour` or `day`
- sampledt: user-defined sampling time, valid only when output_type is not in ["s","min","hour","day"]

# Connectors:
- `u`
"""
function Secrete(data; name, output_type="user-defined", sampledt=1)
    @named u = RealOutput()
    n = ifelse(output_type == "s", 1,
        ifelse(output_type == "min", 60,
            ifelse(output_type == "hour", 3600,
            ifelse(output_type == "day", 86400, sampledt))))
    eqs = [
        u.u ~ get_datas(t / n, data)
    ]
    compose(ODESystem(eqs, t, [], []; name=name), [u])
end

function get_datas(t, data)
    getindex(data, Int(floor(t) + 1))
end
@register_symbolic get_datas(t, data::Array)


# 定义能量流电流图中的主动能量生产设备：外界数据输入，输出生产的能量
@component function EnergySource(; name, W_start = 0.0, Q_start = 0.0, m_start = 0.0, Δt=1.0,
    life_year=0.0, cost_initial=0.0, cost_OM=0.0, cost_replace=0.0)

    sts = @variables begin
        W(t) = W_start
        Q(t) = Q_start
        m(t) = m_start
    end

    ps = @parameters begin
        Δt=Δt
        life_year=life_year
        cost_initial=cost_initial
        cost_OM=cost_OM
        cost_replace=cost_replace
    end

    return ODESystem(Equation[], t, sts, ps; name = name)
end

# 定义能量流电流图中的能量交换总线：多入（源荷）单出（能量平衡关系）
# 输入：提供具体数值的主动电源/负荷；
# 输出E：根据主动电源/负荷数值计算后的能量差值
@component function EnergyBus(; name, names_p::Vector, names_n::Vector, E_start = 0.0)
    
    sts = @variables begin
        E(t) = E_start
        sum_p(t)=0.0
        sum_n(t)=0.0
        ΔE(t) = 0.0 # 经能量存储设备操作后的最终供需能量差值
    end
    
    num_p = length(names_p)
    num_n = length(names_n)
    ODEs_p = Vector{ODESystem}(undef, num_p)
    ODEs_n = Vector{ODESystem}(undef, num_n)
    for i in 1:num_p
        ODEs_p[i] = RealInput(name=Symbol(names_p[i]))
    end
    for i in 1:num_n
        ODEs_n[i] = RealInput(name=Symbol(names_n[i]))
    end

    eqs = [
        E ~ sum_p - sum_n
        sum_p ~ sum([p.u for p in ODEs_p])
        sum_n ~ sum([n.u for n in ODEs_n])
        ]

    return compose(ODESystem(eqs, t, sts, []; name = name), append!(ODEs_p,ODEs_n))

end

# 定义能量流电流图中的能量存储设备
@component function EnergyStorage(; name, E_rated, 
    SoC_start=0.0, SoC_min=0.0, SoC_max=1.0, SoC_cha_thre=0.0, η_loss=0.0, η_cha=1.0, η_disc=1.0, 
    ΔSoC_upthre_cha=1.0, ΔSoC_upthre_disc=1.0, ΔSoC_downthre_cha=0.0, ΔSoC_downthre_disc=0.0,
    Δt=1.0,life_year=0.0, cost_initial=0.0, cost_OM=0.0, cost_replace=0.0)

    @named ebus = RealInput()  # 上级源荷的能量不匹配量； +：供大于求，充能； -：供低于求，放能

    sts = @variables begin
        ΔE(t)   # 对外能力（考虑充放效率损失）,+ 对设备充能，- 设备对外放能
        ΔE_device(t) # 装置实际能量变化
        ΔE_cha_to_thre(t) # 装置充能到设定充能阈值所需的输入能量 >= 0
        ΔE_cha_max(t) # +
        ΔE_disc_max(t) # -
        ΔE_cha_min(t) # +
        ΔE_disc_min(t) # -
        SoC(t) = SoC_start
        ΔE_bus_left(t) = ebus.u
        # 为实现储能所消耗的能源量
        W_consume(t) = 0.0 
        Q_consume(t) = 0.0
        m_consume(t) = 0.0
    end

    ps = @parameters begin
        E_rated=E_rated
        SoC_start=SoC_start
        SoC_min=SoC_min
        SoC_max=SoC_max
        SoC_cha_thre=SoC_cha_thre # 充能阈值
        η_loss=η_loss   # 自放能率
        η_cha=η_cha     # 充能效率
        η_disc=η_disc   # 放能效率
        ΔSoC_upthre_cha=ΔSoC_upthre_cha     # 充能上限
        ΔSoC_upthre_disc=ΔSoC_upthre_disc   # 放能上限
        ΔSoC_downthre_cha=ΔSoC_downthre_cha     # 充能下限
        ΔSoC_downthre_disc=ΔSoC_downthre_disc   # 放能下限，如最小负载
        Δt=Δt
        life_year=life_year
        cost_initial=cost_initial
        cost_OM=cost_OM
        cost_replace=cost_replace
    end

    eqs = [
        ΔE_cha_to_thre ~ max(0, SoC_cha_thre - SoC) / η_cha * E_rated

        ΔE_cha_min ~ ΔSoC_downthre_cha * E_rated * Δt / η_cha
        ΔE_disc_min ~ - ΔSoC_downthre_disc * E_rated * Δt * η_disc

        ΔE_cha_max ~ max(ΔE_cha_min, min(max(0, SoC_max - SoC), ΔSoC_upthre_cha) * E_rated * Δt / η_cha)     # 耗电能力
        ΔE_disc_max ~ - max(-ΔE_disc_min, min(max(0, SoC - SoC_min), ΔSoC_upthre_disc) * E_rated * Δt * η_disc) # 放电能力

        ΔE ~ compare_energy(ebus.u, ΔE_cha_max, ΔE_disc_max, ΔE_cha_min, ΔE_disc_min)
        ΔE_bus_left ~ ebus.u - ΔE
        ΔE_device ~ cal_energy_device(ΔE, η_cha, η_disc)
        ∂(SoC) ~ (1-η_loss)* (ΔE_device / E_rated)
    ]

    return compose(ODESystem(eqs, t, sts, ps; name = name), [ebus])

end

function compare_energy(ΔE_bus, ΔE_cha_max, ΔE_disc_max, ΔE_cha_min, ΔE_disc_min)
    # +:充电； -：放电
    ΔE = ifelse(ΔE_bus > ΔE_cha_max, ΔE_cha_max,
            ifelse(ΔE_cha_max >= ΔE_bus >= ΔE_cha_min, ΔE_bus,
                ifelse(ΔE_cha_min > ΔE_bus > ΔE_disc_min, 0,
                    ifelse(ΔE_disc_min >= ΔE_bus >= ΔE_disc_max, ΔE_bus, ΔE_disc_max))))
end

@register_symbolic compare_energy(ΔE_bus, ΔE_cha_max, ΔE_disc_max, ΔE_cha_min, ΔE_disc_min)

function cal_energy_device(ΔE, η_cha, η_disc)
    # +:充电； -：放电
    ΔE_device = ifelse(ΔE >= 0, ΔE * η_cha, ΔE / η_disc)
    
end

@register_symbolic cal_energy_device(ΔE, η_cha, η_disc)


# 定义能量流中的被动能源供给设备：外界输入能源需求量（-），输出可供给的能源量（-），计算方式参考EnergyStorage，但不考虑充能
# 连接至EnergyBus的储能接口
@component function PassiveEnergySource(; name, E_rated, 
    η_disc=1.0, ΔSoC_upthre_disc=1.0, ΔSoC_downthre_disc=0.0,
    Δt=1.0,life_year=0.0, cost_initial=0.0, cost_OM=0.0, cost_replace=0.0)

    @named ebus = RealInput()  # 上级源荷的能量不匹配量； +：供大于求，充能； -：供低于求，放能

    sts = @variables begin
        # 用于计算
        ΔE(t)   # 对外能力（考虑充放效率损失）, - 设备对外放能
        ΔE_device(t) # 装置实际能量变化
        ΔE_disc_max(t) # -
        ΔE_disc_min(t) # -
        SoC(t) = 0.0
        ΔE_bus_left(t) = ebus.u
        # 用于对外展示: +
        W(t) = 0.0
        Q(t) = 0.0
        m(t) = 0.0
        # 为实现储能所消耗的能源量: +
        W_consume(t) = 0.0 
        Q_consume(t) = 0.0
        m_consume(t) = 0.0
    end

    ps = @parameters begin
        E_rated=E_rated
        η_disc=η_disc   # 放能效率，如逆变器效率
        ΔSoC_upthre_disc=ΔSoC_upthre_disc   # 放能上限，如最大负荷
        ΔSoC_downthre_disc=ΔSoC_downthre_disc   # 放能下限，如最小负载
        Δt=Δt
        life_year=life_year
        cost_initial=cost_initial
        cost_OM=cost_OM
        cost_replace=cost_replace
    end

    eqs = [
        ΔE_disc_min ~ - ΔSoC_downthre_disc * E_rated * Δt * η_disc
        ΔE_disc_max ~ - ΔSoC_upthre_disc * E_rated * Δt * η_disc # 放电能力
        ΔE ~ compare_energy(ebus.u, 0, ΔE_disc_max, 0, ΔE_disc_min)
        ΔE_bus_left ~ ebus.u - ΔE
        ΔE_device ~ ΔE / η_disc
        SoC ~ - ΔE_device / E_rated # 输出功率百分比
    ]

    return compose(ODESystem(eqs, t, sts, ps; name = name), [ebus])

end

