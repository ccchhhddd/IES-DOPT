import JSON

#using DataFrames

include("head.jl")
include("Controler/Polynomial.jl")
include("Controler/Controler.jl")
include("Simulation/HeatExchanger.jl")
include("Simulation/Thermodynamics.jl")
include("Simulation/VenturiMeter.jl")
include("Optimization/structs.jl")
include("Optimization/function_Electricity.jl")
include("Optimization/function_Financial.jl")
include("Optimization/function_Gas.jl")
include("Optimization/simulate.jl")
include("Optimization/optimize.jl")
include("Jumulink/Controler.jl")
include("function.jl")

# 跨域解决方案
const CORS_HEADERS = [
  "Access-Control-Allow-Origin" => "*",
  "Access-Control-Allow-Headers" => "*",
  "Access-Control-Allow-Methods" => "POST, GET, OPTIONS"
]

function CorsMiddleware(handler)
  return function (req::HTTP.Request)
    # println("CORS middleware")
    # determine if this is a pre-flight request from the browser
    if HTTP.method(req) ∈ ["POST", "GET", "OPTIONS"]
      return HTTP.Response(200, CORS_HEADERS, HTTP.body(handler(req)))
    else
      return handler(req) # passes the request to the AuthMiddleware
    end
  end
end

@post "/simulation" function (req)
  # 将HTTP请求的正文（request body）转换为 Julia 中的字典（Dict）数据结构
  paras = json(req)
  # 调用后端模型获得数据
  #table = simulate!(paras["inputdata"], Val(paras["mode"]))
  #println(paras)
  figure, table = simulate_0!(paras["inputdata"], Val(paras["mode"]))
  #println(figure)
  # 返回数据，匹配前端request要求的格式
  return Dict(
    "code" => 200,
    "message" => "success",
    "data" => Dict(
      # "table" => getTableData(table),
      "table" => OrderedDict(k => round(v, digits=2) for (k, v) in table),
      "figure" => Dict(
        "xyAxis" => figure,
      )
    ))
end

@post "/simulation_1" function (req)
  paras = json(req)
  # 调用后端模型获得数据
  #println(paras)
  table, figure1, figure2 = simulate_1!(paras["inputdata"], Val(paras["mode"]))
  #println(figure)
  # 返回数据，匹配前端request要求的格式
  return Dict(
    "code" => 200,
    "message" => "success",
    "data" => Dict(
      # "table" => getTableData(table),
      "table" => table,
      "figure" => Dict(
        "xyAxis" => figure1,
        "xyAxis1" => figure2
      )
    ))
end

@post "/simulation_2" function (req)
  paras = json(req)
  # 调用后端模型获得数据
  figure = simulate_2!(paras["inputdata"],Val(paras["mode"]))
  # 返回数据，匹配前端request要求的格式
  return Dict(
    "code" => 200,
    "message" => "success",
    "data" => Dict(
    "figure" => Dict(
      "xyAxis" => figure
      )
    ))
end

@post "/simulation_pid" function (req)
  # 理想PID控制器
  paras = json(req)
  # 调用后端模型获得数据
  println(paras)
  figure1 = solve_pid_I(paras["inputdata"])
  figure2 = solve_pid_A(paras["inputdata"])


  return Dict(
    "code" => 200,
    "message" => "success",
    "data" => Dict(
      # "table" => getTableData(table),
      "figure" => Dict(
        "xyAxis" => figure1[:r],
        "xyAxis1" => figure1[:d],
        "xyAxis2" => figure2[:r],
        "xyAxis3" => figure2[:d]
      )
    )
  )
end

@post "/jumulink" function (req::HTTP.Request)
	# 理想PID控制器
	input = json(req, Dict)
	return ControlSystem(input)
end

@post "/simulation_ies_h2" function (req)
  # 将HTTP请求的正文（request body）转换为 Julia 中的字典（Dict）数据结构
  paras = json(req)
  println(paras)
  # 调用后端模型获得数据
  figure,figure1,figure2,table = simulate!(paras["inputdata"],paras["area"], Val(paras["mode"]))
  # 返回数据，匹配前端request要求的格式
  return Dict(
    "code" => 200,
    "message" => "success",
    "data" => Dict(
      "table" => OrderedDict(k => (v isa Number ? round(v, digits=4) : v) for (k, v) in table),
      "figure" => Dict(
        "xAxis" => collect(1:8760),
        "yAxis" => figure,
        ),
      "envFigure" => Dict(
        "xAxis" => collect(1:8760),
        "yAxis" => figure1,
        ),
      "H2Figure" => Dict(
          "xAxis" => collect(1:8760),
          "yAxis" => figure2,
          ),

    )
)
end

@post "/optimization_ies_h2" function (req)
  # 将HTTP请求的正文（request body）转换为 Julia 中的字典（Dict）数据结构
  paras = json(req)
  println(paras)
  # 调用后端模型获得数据
  figure,figure1,figure2,table = optimize!(paras["inputdata"],paras["opt_paras"],paras["isOpt"],paras["area"], Val(paras["mode"]))
  #println(figure)
  # 返回数据，匹配前端request要求的格式
  return Dict(
    "code" => 200,
    "message" => "success",
    "data" => Dict(
      # "table" => getTableData(table),
      "table" => OrderedDict(k => round(v, digits=2) for (k, v) in table),
      "figure" => Dict(
        "xAxis" => collect(1:8760),
        "yAxis" => figure,
        ),
      "envFigure" => Dict(
        "xAxis" => collect(1:8760),
        "yAxis" => figure1,
        ),
      "H2Figure" => Dict(
          "xAxis" => collect(1:8760),
          "yAxis" => figure2,
          ),
        )
      )
end

@get "/hello" function (req)
  return Dict(
    "code" => 200,
    "message" => "success",
    "data" => "hello world"
  )
end
# 本地测试 async=true，服务器上 async=false。同步测试便于调试
serve(host="0.0.0.0", port=8080, async=true,middleware=[CorsMiddleware])
# serve(port=8080, async=true)

