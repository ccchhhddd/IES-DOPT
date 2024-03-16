#朗肯循环
@info "定义接口..."
@connector function StreamNode(; name)
    sts = @variables begin
        p(t0) = 1.0e5
        t(t0) = 300.0
        s(t0) = 1.0e5
		h(t0) = 1.0e5
    end
    ODESystem(Equation[], t0, sts, []; name=name)
end

function StreamPort(; name)
    @named in = StreamNode()
    @named out = StreamNode()
    sts = @variables begin
        Δp(t0) = 1.0e5
        Δt(t0) = 300.0
        Δs(t0) = 1.0e5
		Δh(t0) = 1.0e5
    end
    eqs = [
        Δp ~ out.p - in.p
        Δt ~ out.t - in.t
        Δs ~ out.s - in.s
		Δh ~ out.h - in.h
    ]
    compose(ODESystem(eqs, t0, sts, []; name=name), in,out)
end

@info "定义组件..."
# 汽轮机turbine
function Turbine(; name,P = 4000,fluid ="Water")
    @named oneport = StreamPort()
    @unpack Δs, out = oneport
    ps = @parameters P = P
    eqs = [
        out.p ~ P
        out.t ~ PropsSI("T", "P", out.p, "S",out.s, fluid)
        Δs ~ 0
         #等熵过程
        ]
    return extend(ODESystem(eqs, t0, [], ps; name=name), oneport)
end

# 冷凝器condenser
function Condenser(; name,fluid ="Water")
    @named oneport = StreamPort()
    @unpack Δp, out = oneport
    eqs = [
        out.t ~ PropsSI("T", "P", out.p, "Q", 0, fluid)
        out.s ~ PropsSI("S", "P", out.p, "Q", 0, fluid)
        out.h ~ PropsSI("H", "P", out.p, "Q", 0, fluid)
        Δp ~ 0  #等压过程
    ]
    return extend(ODESystem(eqs, t0, [], []; name=name), oneport)
end

# 水泵pump
function Pump(; name, P = 3000000,fluid ="Water")
    @named oneport = StreamPort()
    @unpack Δs, out = oneport
    ps = @parameters P = P
    eqs = [
        out.p ~ P
        out.t ~ PropsSI("T", "P", out.p, "S",out.s, fluid)
        Δs ~ 0 #等熵过程
        ]
    return extend(ODESystem(eqs, t0, [], ps; name=name), oneport)
end
#eqs = equations(pump)

# 锅炉boiler
function Boiler(; name, T = 700 +273.15,fluid ="Water")
    @named oneport = StreamPort()
    @unpack Δp, out = oneport
    ps = @parameters T = T
    #sts = @variables T(t0) pp(t0)
    #ps = @parameters Tmax = Tmax
    #Dt(T) = ifelse(T>Tmax, 0.0, 10.0)
    eqs = [
        out.t ~ T
        out.s ~ PropsSI("S", "T", out.t, "P",out.p, fluid)
        Δp ~ 0 #等压过程
    ]
    return extend(ODESystem(eqs, t0, [], ps; name=name), oneport)
end


#节气门throttle
function Throttle(; name,P=10000,fluid ="Water")
	@named oneport = StreamPort()
	@unpack Δh, out = oneport
    ps = @parameters P = P
    eqs = [
        out.p ~ P
        out.t ~ PropsSI("T", "P", out.p, "H",out.h, fluid)
        out.s ~ PropsSI("S", "P", out.p, "H",out.h, fluid)
        Δh ~ 0 #等焓过程
        ]
    return extend(ODESystem(eqs, t0, [], ps; name=name), oneport)
end

#压缩机compressor
function Compressor(; name,P = 1000000,fluid ="Water")
		@named oneport = StreamPort()
    @unpack Δs, out = oneport
    ps = @parameters P = P
    eqs = [
        out.p ~ P
        out.t ~ PropsSI("T", "P", out.p, "S",out.s, fluid)
        out.h ~ PropsSI("H", "P", out.p, "S",out.s, fluid)
        Δs ~ 0 #等熵过程
        ]
    return extend(ODESystem(eqs, t0, [], ps; name=name), oneport)
end

#蒸发器evaporator
function Evaporator(;name,fluid ="Water")
	@named oneport = StreamPort()
    @unpack Δt, out = oneport
    eqs = [
        out.p ~ PropsSI("P", "T", out.t, "Q", 1, fluid)
        out.s ~ PropsSI("S", "T", out.t, "Q", 1, fluid)
        out.h ~ PropsSI("H", "T", out.t, "Q", 1, fluid)
        Δt ~ 0  #等温过程
    ]
    return extend(ODESystem(eqs, t0, [], []; name=name), oneport)
end


simulate_0!(paras,::Val{1}) = rankine(paras["朗肯循环参数"]["冷凝器冷却压力(pa)"],
                                    paras["朗肯循环参数"]["水泵供给压力(pa)"],
                                    paras["朗肯循环参数"]["锅炉出口温度(k)"],
							        paras["朗肯循环参数"]["工质"])

#有再热的朗肯循环
simulate_0!(paras,::Val{2}) = reheat_rankine(paras["再热循环参数"]["冷凝器冷却压力(pa)"],
                                           paras["再热循环参数"]["水泵供给压力(pa)"],
                                           paras["再热循环参数"]["锅炉出口温度(k)"],
                                           paras["再热循环参数"]["再热器出口温度(k)"],
                                           paras["再热循环参数"][ "汽轮机一级出口压力(pa)"],
										   paras["再热循环参数"][ "工质"])

#制冷循环
simulate_0!(paras,::Val{3}) = refrigeration(paras["制冷循环参数"]["压缩机出口压力(pa)"],
										  paras["制冷循环参数"]["节气门出口压力(pa)"],
										  paras["制冷循环参数"]["工质"])


function refrigeration(压缩机出口压力,节气门出口压力,工质)
  压缩机出口压力 = 压缩机出口压力 isa Number ? 压缩机出口压力 : parse(Float64,压缩机出口压力)
  节气门出口压力 = 节气门出口压力 isa Number ? 节气门出口压力 : parse(Float64,节气门出口压力)

	#创建组件...
	@named compressor = Compressor(P = 压缩机出口压力,fluid = 工质)
	@named throttle= Throttle(P = 节气门出口压力,fluid = 工质)
	@named condenser = Condenser(fluid = 工质)
	@named evaporator = Evaporator(fluid = 工质)

	#构建连接关系
	rc_eqs = [
		connect(compressor.out, condenser.in)
    connect(condenser.out, throttle.in)
    connect(throttle.out, evaporator.in)
    connect(evaporator.out, compressor.in)
		D(x) ~ 0
	]
	@named _rc_model = ODESystem(rc_eqs, t0) #连接关系也需要放到ODESystem中

	# 组件与组件连接关系一起构建系统
	@named rc_model = compose(_rc_model,[compressor,condenser,throttle,evaporator])

	# 系统化简
	sys = structural_simplify(rc_model)

	# 查看方程
	#equations(sys)

	# 求解
	prob = ODAEProblem(sys, [0], (0, 0.0))
	sol = solve(prob)


	table = OrderedDict("压缩机出口温度(K)" => sol[compressor.out.t][1],
	"节气门出口温度(K)" => sol[throttle.out.t][1],
  "压缩机入口温度(K)" => sol[compressor.in.t][1],
	"节气门入口温度(K)" => sol[throttle.in.t][1])

	plot_sys = [evaporator,compressor, condenser,throttle];
	propx = :s
	propy = :t

	ss = [sol[getproperty(i.out, propx)][1] for i in plot_sys]
	tt = [sol[getproperty(i.out, propy)][1] for i in plot_sys]

	xAxis = collect(range(ss[1], ss[2], 15))
	yAxis = collect(range(tt[1], tt[2], 15))

	append!(xAxis, collect(range(ss[2], ss[3], 15)))
	append!(yAxis,CoolProp.PropsSI.("T", "P", sol[condenser.out.p], "S", collect(range(ss[2], ss[3], 15)), 工质))

	append!(xAxis,collect(range(ss[3], ss[4], 15)))
	append!(yAxis,CoolProp.PropsSI.("T", "H", sol[throttle.out.h], "S", collect(range(ss[3], ss[4], 15)), 工质))

	append!(xAxis,collect(range(ss[4], ss[1], 15)))
	append!(yAxis,collect(range(tt[4], tt[1], 15)))


	# println(xAxis)
	# println(yAxis)
	figure = transposeMatrix(xAxis, yAxis)
	#在本地绘图
	plot_local(figure)
	return figure,table
end





function reheat_rankine(冷凝器冷却压力,
                        水泵供给压力,
                        锅炉出口温度,
                        再热器出口温度,
                        汽轮机一级出口压力,
						工质)

    冷凝器冷却压力 = 冷凝器冷却压力 isa Number ? 冷凝器冷却压力 : parse(Float64,冷凝器冷却压力)
    水泵供给压力 = 水泵供给压力 isa Number ? 水泵供给压力 : parse(Float64,水泵供给压力)
    锅炉出口温度 = 锅炉出口温度 isa Number ? 锅炉出口温度 : parse(Float64,锅炉出口温度)
    再热器出口温度 = 再热器出口温度 isa Number ? 再热器出口温度 : parse(Float64,再热器出口温度)
    汽轮机一级出口压力 = 汽轮机一级出口压力 isa Number ? 汽轮机一级出口压力 : parse(Float64,汽轮机一级出口压力)

    #创建组件...
    @named pump = Pump(P = 水泵供给压力,fluid = 工质)
    @named boiler = Boiler(T = 锅炉出口温度,fluid = 工质)
    @named turbine = Turbine(P = 汽轮机一级出口压力,fluid = 工质)
    @named reboiler = Boiler(T = 再热器出口温度,fluid = 工质)
    @named returbine = Turbine(P = 冷凝器冷却压力,fluid = 工质)
    @named condenser = Condenser(fluid = 工质)

    #构建连接关系
    rc_eqs = [
      connect(pump.out, boiler.in)
      connect(boiler.out, turbine.in)
      connect(turbine.out, reboiler.in)
      connect(reboiler.out, returbine.in)
      connect(returbine.out, condenser.in)
      connect(condenser.out, pump.in)
      D(x) ~ 0
    ]
    @named _rc_model = ODESystem(rc_eqs, t0) #连接关系也需要放到ODESystem中

    # 组件与组件连接关系一起构建系统
    @named rc_model = compose(_rc_model,[turbine, condenser , pump, boiler,reboiler,returbine ])

    # 系统化简
    sys = structural_simplify(rc_model)
    equations(sys) # 查看方程
    # 求解
    prob = ODAEProblem(sys, [0], (0, 0.0))
    sol = solve(prob)

    #println(sol)
    table = OrderedDict("汽轮机一级入口压力(pa)" => sol[turbine.in.p][1],
    "汽轮机一级入口温度(k)" => sol[turbine.in.t][1],
    "汽轮机一级出口温度(k)" => sol[turbine.out.t][1],
    "汽轮机一级出口熵(J/(mol*k))" => sol[turbine.out.s][1],
    "锅炉入口温度(k)"=> sol[boiler.in.t][1],
    "锅炉出口压力(pa)"=> sol[boiler.out.p][1],
    "锅炉入口压力(pa)"=> sol[boiler.in.p][1])

    plot_sys = [pump, boiler, turbine, reboiler, returbine, condenser];
    propx = :s
    propy = :t

    ss = [sol[getproperty(i.out, propx)][1] for i in plot_sys]
    tt = [sol[getproperty(i.out, propy)][1] for i in plot_sys]

    xAxis = collect(range(ss[1], ss[2], 15))
    yAxis = CoolProp.PropsSI.("T", "P", sol[pump.out.p], "S", collect(range(ss[1], ss[2], 15)), 工质)

    append!(xAxis, collect(range(ss[2], ss[3], 15)))
    append!(yAxis,collect(range(tt[2], tt[3], 15)))

    append!(xAxis,collect(range(ss[3], ss[4], 15)))
    append!(yAxis,CoolProp.PropsSI.("T", "P", sol[reboiler.out.p], "S", collect(range(ss[3], ss[4], 15)), 工质))

    append!(xAxis,collect(range(ss[4], ss[5], 15)))
    append!(yAxis,collect(range(tt[4], tt[5], 15)))

    append!(xAxis,collect(range(ss[5], ss[6], 15)))
    append!(yAxis,collect(range(tt[5], tt[6], 15)))

    append!(xAxis,collect(range(ss[6], ss[1], 15)))
    append!(yAxis,collect(range(tt[6], tt[1], 15)))
    # println(xAxis)
    # println(yAxis)
    figure = transposeMatrix(xAxis, yAxis)
    #在本地绘图
    plot_local(figure)
    return figure,table
end

@info "开始建模..."
function rankine(汽轮机出口压力,水泵出口压力,锅炉出口温度,工质)

	汽轮机出口压力 = 汽轮机出口压力 isa Number ? 汽轮机出口压力 : parse(Float64,汽轮机出口压力)
  水泵出口压力 = 水泵出口压力 isa Number ? 水泵出口压力 : parse(Float64,水泵出口压力)
	锅炉出口温度 = 锅炉出口温度 isa Number ? 锅炉出口温度 : parse(Float64,锅炉出口温度)


    @info "创建组件..."
      @named turbine = Turbine(P = 汽轮机出口压力,fluid = 工质)
      @named condenser = Condenser(fluid = 工质)
      @named pump = Pump(P = 水泵出口压力,fluid = 工质)
      @named boiler = Boiler(T = 锅炉出口温度,fluid = 工质)

    @info "创建系统..."
  # 构建连接关系
  rc_eqs = [
      connect(turbine.out, condenser.in)
      connect(condenser.out,pump.in)
      connect(pump.out,boiler.in)
      connect(boiler.out,turbine.in)
      D(x) ~ 0
  ]
  @named _rc_model = ODESystem(rc_eqs, t0) #连接关系也需要放到ODESystem中

  # 组件与组件连接关系一起构建系统
  @named rc_model = compose(_rc_model,[turbine, condenser , pump, boiler ])

  # 系统化简
  @info "系统化简..."
  sys = structural_simplify(rc_model)
  #equations(sys) # 查看方程

  # 求解
  @info "创建仿真..."
  prob = ODAEProblem(sys, [0], (0, 0.0))

  @info "仿真计算..."
  sol = solve(prob)

  @info "系统评价..."
  table = OrderedDict("汽轮机入口压力(pa)" => sol[turbine.in.p][1],
  "汽轮机入口温度(k)" => sol[turbine.in.t][1],
  "汽轮机出口温度(k)" => sol[turbine.out.t][1],
  "锅炉入口温度(k)"=> sol[boiler.in.t][1],
  "锅炉出口压力(pa)"=> sol[boiler.out.p][1],
  "锅炉入口压力(pa)"=> sol[boiler.in.p][1])

  plot_sys = [pump, boiler, turbine, condenser];
  propx = :s
  propy = :t

  ss = [sol[getproperty(i.out, propx)][1] for i in plot_sys]
  tt = [sol[getproperty(i.out, propy)][1] for i in plot_sys]

  xAxis = collect(range(ss[1], ss[2], 15))
  yAxis = CoolProp.PropsSI.("T", "P", sol[pump.out.p], "S", collect(range(ss[1], ss[2], 15)), 工质)

  append!(xAxis,collect(range(ss[2], ss[3], 15)))
  append!(yAxis,collect(range(tt[2], tt[3], 15)))

  append!(xAxis,collect(range(ss[3], ss[4], 15)))
  append!(yAxis,CoolProp.PropsSI.("T", "P", sol[turbine.out.p], "S", collect(range(ss[3], ss[4], 15)), 工质))

  append!(xAxis,collect(range(ss[4], ss[1], 15)))
  append!(yAxis,collect(range(tt[4], tt[1], 15)))

  figure = transposeMatrix(xAxis, yAxis)
  #在本地绘图
  plot_local(figure)

  return figure,table
end



