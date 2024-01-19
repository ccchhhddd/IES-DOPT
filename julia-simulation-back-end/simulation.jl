using Plots
include("function.jl")
#朗肯循环
simulate!(paras,::Val{1}) = rankine(paras["朗肯循环参数"]["冷凝器冷却压力(pa)"],
                                    paras["朗肯循环参数"]["水泵供给压力(pa)"],
                                    paras["朗肯循环参数"]["锅炉出口温度(k)"],
							        paras["朗肯循环参数"]["工质"])

#有再热的朗肯循环
simulate!(paras,::Val{2}) = reheat_rankine(paras["再热循环参数"]["冷凝器冷却压力(pa)"],
                                           paras["再热循环参数"]["水泵供给压力(pa)"],
                                           paras["再热循环参数"]["锅炉出口温度(k)"],
                                           paras["再热循环参数"]["再热器出口温度(k)"],
                                           paras["再热循环参数"][ "汽轮机一级出口压力(pa)"],
										   paras["再热循环参数"][ "工质"])

#制冷循环
simulate!(paras,::Val{3}) = refrigeration(paras["制冷循环参数"]["压缩机出口压力(pa)"],
										  paras["制冷循环参数"]["节气门出口压力(pa)"],
										  paras["制冷循环参数"]["工质"])

simulate_1!(paras,::Val{1}) = simulation_Heat_exchanger(Th = paras["仿真参数"]["热流体入口温度(K)"],
														Tc = paras["仿真参数"]["冷流体入口温度(K)"],
														Qh = paras["仿真参数"]["热流体流量(kg/s)"],
														Qc = paras["仿真参数"]["冷流体流量(kg/s)"],
														L = paras["仿真参数"]["换热管长度(m)"],
														Media_h = paras["仿真参数"]["热流体种类"],
														Media_c = paras["仿真参数"]["冷流体种类"],
														Flow_type = "parallel")
simulate_1!(paras,::Val{2}) = simulation_Heat_exchanger(Th = paras["仿真参数"]["热流体入口温度(K)"],
														Tc = paras["仿真参数"]["冷流体入口温度(K)"],
														Qh = paras["仿真参数"]["热流体流量(kg/s)"],
														Qc = paras["仿真参数"]["冷流体流量(kg/s)"],
														L = paras["仿真参数"]["换热管长度(m)"],
														Media_h = paras["仿真参数"]["热流体种类"],
														Media_c = paras["仿真参数"]["冷流体种类"],
														Flow_type = "countercurrent")

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
	equations(sys) # 查看方程
	# 求解
	prob = ODAEProblem(sys, [0], (0, 0.0))
	sol = solve(prob)

	#println(sol)
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


function simulation_Heat_exchanger(;Th,Tc, Qh, Qc, L, Media_h::String,Media_c::String, Flow_type::String)
	Th = Th isa Number ? Th : parse(Float64,Th)
	Tc = Tc isa Number ? Tc : parse(Float64,Tc)
	Qh = Qh isa Number ? Qh : parse(Float64,Qh)
	Qc = Qc isa Number ? Qc : parse(Float64,Qc)
	L = L isa Number ? L : parse(Float64,L)
	a = 0.5
	d_i = 0.15*a #管内径
	d_o = 0.2*a #管外径
	Ph = 101325 #压力

	#u[1] = T_h,u[2] = T_c
	#p[1] = Qh,p[2] = Qc,p[3] = Ph,p[4] = Media_h,p[5] = Flow_type,p[6] = d_i,p[7] = d_o,p[8] = T_c,p[9] = Media_c
	function heat_exchanger!(du,u,p,t)
		#比热容
		Cp_h = CoolProp.PropsSI("C", "T", u[1], "P", p[3],p[4])
		Cp_c = CoolProp.PropsSI("C", "T", u[2], "P", p[3],p[9])
		#计算动态粘度
		μ_h = CoolProp.PropsSI("V", "T", u[1], "P", p[3], p[4])
		μ_c = CoolProp.PropsSI("V", "T", u[2], "P", p[3], p[9])

		#计算普朗特数
		Pr_h = CoolProp.PropsSI("Prandtl", "T", u[1], "P", p[3], p[4])
		Pr_c = CoolProp.PropsSI("Prandtl", "T", u[2], "P", p[3], p[9])

		#计算雷诺数
		Re_h = 4*p[1]/p[6]/μ_h/π
		Re_c = 4*p[2]/p[7]/μ_c/π

		#计算努塞尔数
		if Re_c > 10000
			Nu_c = 0.023*(Re_c^0.8)*(Pr_c^0.4)
		else
			Nu_c = 4.36
		end
		if Re_h > 10000
			Nu_h = 0.023*(Re_h^0.8)*(Pr_h^0.3)
		else
			Nu_h = 4.36
		end

		#计算传热系数
		k_h = CoolProp.PropsSI("L", "T", u[1], "P", p[3], p[4])
		k_c = CoolProp.PropsSI("L", "T", u[2], "P", p[3], p[9])

		η_h = Nu_h*k_h/p[6]
		η_c = Nu_c*k_c/p[7]
		#计算传热系数U
		U = (1/η_h+1/η_c)^(-1)
		#计算热传导方程 [1]为热流 [2]为冷流
		du[1] = U*π*p[6]*(u[2]-u[1])/(Cp_h*p[1])
		if Flow_type == "parallel"
			du[2] = U*π*p[7]*(u[1]-u[2])/(Cp_c*p[2])
		elseif Flow_type == "countercurrent"
			du[2] = -U*π*p[7]*(u[1]-u[2])/(Cp_c*p[2])
		end
	end
	T_c_in = Tc
	p = [Qh,Qc,Ph,Media_h,Flow_type,d_i,d_o,T_c_in,Media_c]
	u0 = [Th;p[8]]
	tspan = (0.0, L)
	#求解
	prob = ODEProblem(heat_exchanger!, u0, tspan, p)
	sol = solve(prob)
	plot(sol)
	if Flow_type == "countercurrent"
		T_c_in = T_c_in + (sol.u[1][2] - sol.u[end][2])
		u_0 = Tc
		u_1 = Tc + sol.u[1][2]-sol.u[end][2]
		while abs(sol.u[end][2]-Tc) > 0.5
			T_c_in = (u_0 + u_1)/2
			p = [Qh,Qc,Ph,Media_h,Flow_type,d_i,d_o,T_c_in,Media_c]
			u0 = [Th;p[8]]
			tspan = (0.0, L)
			#求解
			prob = ODEProblem(heat_exchanger!, u0, tspan, p)
			sol = solve(prob)
			println()
			if sol.u[end][2] > Tc
				u_1 = T_c_in
			else
				u_0 = T_c_in
			end
		end
	end

	#绘图
	display(plot(sol))

	# 计算 Re
	T_c = Tc
	μ_c = CoolProp.PropsSI("V", "T", T_c, "P", p[3], p[9])
	Re_c = 4 * p[2] / p[7] / μ_c / π
	T_h = Th
	μ_h = CoolProp.PropsSI("V", "T", T_h, "P", p[3], p[4])
	Re_h = 4 * p[1] / p[6] / μ_h / π
	if Re_c > 10000
		Status_c = "湍流"
		println("Re_c =", Re_c, ",冷流是湍流")
	else
		Status_c = "层流"
		println("Re_c =", Re_c, ",冷流是层流")
	end
	if Re_h > 10000
		Status_h = "湍流"
		println("Re_h =", Re_h, ",热流是湍流")
	else
		Status_h = "层流"
		println("Re_h =", Re_h, ",热流是层流")
	end
	# 计算传热率
	Φ = (sol.u[1][1] - sol.u[end][1])*CoolProp.PropsSI("C", "T", sol.u[1][1], "P", p[3],p[4])*p[1]
	println("换热效率Φ =", Φ," W")

    if Flow_type == "parallel"
	  table = OrderedDict("换热效率Φ(w)" => Φ,
						"换热管长度(m)" => L,
	          "热流雷诺数" => Re_h,
						"热流状态" => Status_h,
						"热流体出口温度(K)" => sol.u[end][1],
	          "冷流雷诺数" => Re_c,
						"冷流状态" => Status_c,
						"冷流体出口温度(K)" => sol.u[end][2])
	else
	  table = OrderedDict("换热效率Φ(w)" => Φ,
							"换热管长度(m)" => L,
		          "热流雷诺数" => Re_h,
							"热流状态" => Status_h,
							"热流体出口温度(K)" => sol.u[end][1],
		          "冷流雷诺数" => Re_c,
							"冷流状态" => Status_c,
							"冷流体出口温度(K)" => sol.u[1][2])
	end

	y1 = [sol.u[i][1] for i in 1:length(sol.t)]
	y2 = [sol.u[i][2] for i in 1:length(sol.t)]
	figure1 = transposeMatrix(sol.t, y1)
	figure2 = transposeMatrix(sol.t, y2)
	#在本地绘图
	plot_local(figure1)
	plot_local(figure2)
	return table,figure1,figure2
end
