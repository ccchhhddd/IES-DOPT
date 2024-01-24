simulate_2!(paras,::Val{1}) = simulation_Venturi_Meter(Q = paras["仿真参数"]["流量(m^3/s)"], friction = true, Media = paras["仿真参数"]["流体种类"])

simulate_2!(paras,::Val{2}) = simulation_Venturi_Meter(Q = paras["仿真参数"]["流量(m^3/s)"], friction = false, Media = paras["仿真参数"]["流体种类"])

function simulation_Venturi_Meter(; Q,  friction::Bool = false, Media::String = "Water")
  Q = Q isa Number ? Q : parse(Float64, Q)
  #参数
  d = 0.1 #喉管直径
  D = 0.2 #直径
  T = 273.15 + 25 #温度
  P0 = 0.1*1e5 #压力
  ρ = PropsSI("D", "T", T, "P", P0, Media) #密度
  g = 9.8 #重力加速度
  function ΔP(x)
    if friction
      if 0<= x< 0.2
        return 0
      elseif 0.2<= x< 0.4
        return (0.5*ρ*(Q/(π*D^2/4))^2*0.04)*(x-0.2)/0.2
      elseif 0.4<= x< 0.6
        return 0.5*ρ*(Q/(π*D^2/4))^2*0.04
      elseif 0.6<= x< 0.8
        return 0.5*ρ*(Q/(π*D^2/4))^2*(0.04+0.45*(x-0.6)/0.2)
      elseif 0.8<= x<= 1.0
        return 0.5*ρ*(Q/(π*D^2/4))^2*(0.04+0.45)
      end
    else
      return 0
    end
  end

  p = [d, D, P0, ρ, g]

  function h_column(x,p)
    d_x = 0
    if 0<= x< 0.2
      d_x = p[2]
    elseif 0.2<= x< 0.4
      d_x = p[2]-(p[2]-p[1])/0.2*(x-0.2)
    elseif 0.4<= x< 0.6
      d_x = p[1]
    elseif 0.6<= x< 0.8
      d_x = p[1]+(p[2]-p[1])/0.2*(x-0.6)
    elseif 0.8<= x<= 1.0
      d_x = p[2]
    end
    V = Q/(π*d_x^2/4)
    P = 1/2*p[4]*(Q/(π*p[2]^2/4))^2 + p[3] - (1/2*p[4]*V^2 + ΔP(x))
    h = P/p[4]/p[5]
  end

  # 计算 h_column 函数的值
  function calculate_values(p)
    x_values = 0:0.01:1
    return [h_column(x, p) for x in x_values]
  end

  # 绘制图像
  x_values = 0:0.01:1
  y_values = calculate_values(p)
  figure = transposeMatrix(x_values, y_values)

  return figure
end


