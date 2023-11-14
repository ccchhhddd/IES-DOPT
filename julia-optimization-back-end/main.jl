using CSV
import ActuaryUtilities.FinanceCore.rate
data_weather = CSV.File("src/data/weather_lenghu_2018.csv"; select=["glob_hor_rad", "DBT", "wind_speed"])
const S1_DATA_GI = data_weather.glob_hor_rad
const S1_DATA_TA = data_weather.DBT
const S1_DATA_WS = data_weather.wind_speed
const S1_DATA_LOAD = 5285.41 * ones(Float64, 8760)

data_weather = CSV.File("src/data/weather_lenghu_2018.csv"; select=["glob_hor_rad", "DBT", "wind_speed"])

const S2_DATA_GI = data_weather.glob_hor_rad
const S2_DATA_TA = data_weather.DBT
const S2_DATA_WS = data_weather.wind_speed

data_weather = CSV.File("src/data/weather_yulin_2005.csv"; select=["glob_hor_rad", "DBT", "wind_speed"])

const S3_DATA_GI = data_weather.glob_hor_rad
const S3_DATA_TA = data_weather.DBT
const S3_DATA_WS = data_weather.wind_speed
const S3_DATA_LOAD = 0 * ones(Float64, 8760)

include("src/utils.jl")

using Oxygen, HTTP
import JSON

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
  # this will convert the request body into a Julia Dict
  paras = json(req)
  # 调用后端模型获得数据
  println(paras)
  figure, table = simulate!(paras["inputdata"], Val(paras["mode"]))
  # 返回数据，匹配前端request要求的格式
	# println(table)
	# println(figure)
  return Dict(
    "code" => 200,
    "message" => "success",
    "data" => Dict(
      # "table" => getTableData(table),
      "table" => OrderedDict(k => round(v, digits=2) for (k, v) in table),
      "figure" => Dict(
        "xAxis" => collect(1:8760),
        "yAxis" => figure
      )
    ))
end

@post "/optimization" function (req)
  # this will convert the request body into a Julia Dict
  paras = json(req)
  # println(paras)
  # 调用后端模型获得数据
  figure, table = optimize!(paras["inputdata"], Vector{Int}(paras["isopt"]), Val(paras["mode"]))
  # 返回数据，匹配前端request要求的格式
  return Dict(
    "code" => 200,
    "message" => "success",
    "data" => Dict(
      "table" => OrderedDict(k => round(v, digits=2) for (k, v) in table),
      "figure" => Dict(
        "xAxis" => collect(1:8760),
        "yAxis" => figure
      )
    ))
end

@get "hello" function (req)
  return Dict(
    "code" => 200,
    "message" => "success",
    "data" => "hello world"
  )
end

# 本地测试 async=true，服务器上 async=false。同步测试便于调试
serve(host="0.0.0.0", port=8080, async=true, middleware=[CorsMiddleware])

# serve(port=8080, async=true)


