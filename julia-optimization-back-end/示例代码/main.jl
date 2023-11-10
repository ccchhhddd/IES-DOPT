using Oxygen, HTTP
import JSON

include("src/src/HRESDesign.jl")
include("src/pre-run.jl")
include("src/funcAPIs.jl")

#= 跨域解决方案
const CORS_HEADERS = [
  "Access-Control-Allow-Origin" => "*",
  "Access-Control-Allow-Headers" => "*",
  "Access-Control-Allow-Methods" => "POST, GET, OPTIONS"
]

function CorsMiddleware(handler)
  return function (req::HTTP.Request)
    println("CORS middleware")
    # determine if this is a pre-flight request from the browser
    if HTTP.method(req) ∈ ["POST", "GET", "OPTIONS"]
      return HTTP.Response(200, CORS_HEADERS, HTTP.body(handler(req)))
    else
      return handler(req) # passes the request to the AuthMiddleware
    end
  end
end =#



@post "/optimization" function (req)
  # this will convert the request body into a Julia Dict
  paras = json(req)
  println(paras)
  # 调用后端模型获得数据
  sol, table = optimization(paras["inputdata"], Vector{Int}(paras["isopt"]), Val(paras["mode"]))
  # 返回数据，匹配前端request要求的格式
  return Dict(
    "code" => 200,
    "message" => "success",
    "data" => Dict(
      "table" => getTableData(table),
      "figure" => Dict(
        "xAxis" => collect(1:8760),
        "yAxis" => getFigureData(sol, Val(paras["mode"]))
      )
    ))
end

# serve(port=8080, async=false, middleware=[CorsMiddleware])

serve(port=8080, async=true)


