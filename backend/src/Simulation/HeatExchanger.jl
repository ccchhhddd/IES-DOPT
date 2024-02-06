
#换热器
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

	if Flow_type == "parallel"
		T_c_in = Tc
		p = [Qh,Qc,Ph,Media_h,Flow_type,d_i,d_o,T_c_in,Media_c]
		u0 = [Th;T_c_in]
		tspan = (0.0, L)
		#求解
		prob = ODEProblem(heat_exchanger!, u0, tspan, p)
		sol = solve(prob)
		plot(sol)
	elseif Flow_type == "countercurrent"
		u_0 = Tc
		u_1 = Th
		T_c_out = -1
		while abs(T_c_out-Tc) > 0.5
			T_c_in = (u_0 + u_1)/2
			p = [Qh,Qc,Ph,Media_h,Flow_type,d_i,d_o,T_c_in,Media_c]
			u0 = [Th;T_c_in]
			tspan = (0.0, L)
			#求解
			try
			  prob = ODEProblem(heat_exchanger!, u0, tspan, p)
				sol = solve(prob)
				T_c_out = sol.u[end][2]
				if T_c_out > Tc
					u_1 = T_c_in
				else
					u_0 = T_c_in
				end
			catch
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

