@info "Pre-run..."
using CSV, Test
using .HRESDesign.Scenarios
using .HRESDesign
using .HRESDesign.EnergyFlowComponents

@info "导入气象数据..."
# 数据导入
data_weather = CSV.File("src/data/weather_lenghu_2018.csv"; select=["glob_hor_rad", "DBT", "wind_speed"])
const S3_data_GI = data_weather.glob_hor_rad
const S3_data_Ta = data_weather.DBT
const S3_data_WS = data_weather.wind_speed
const S3_data_H2L = [5285.41 for _ in 1:8760]

const param_PV = Dict(:E_rated => 5e5, :E_device_rated => 0.65 * 1000, :η_inverter => 1.0,
    :life_year => 20.0, :cost_initial => 3800.0, :cost_OM => 190.0, :cost_replace => 3800.0) # 50万kW
const param_WT = Dict(:E_rated => 5e5, :E_device_rated => 5000.0, :η_inverter => 0.95,
    :life_year => 20.0, :cost_initial => 4800.0 + 100.0, :cost_OM => 720.0, :cost_replace => 4800.0 + 100.0)# 50万kW, 成本+逆变器
const param_AEC = Dict(:E_rated => 5e5, :E_device_rated => 5000.0, :η_inverter => 1.0,
    :life_year => 20.0, :cost_initial => 2000.0, :cost_OM => 100.0, :cost_replace => 2000.0) # 50万kW; 9000kg H2
const param_HT = Dict(:E_rated => 14240.0, :SoC_cha_thre => 0.0, :E_device_rated => 1000.0,
    :life_year => 20.0, :cost_initial => 2300.0, :cost_OM => 46.0, :cost_replace => 2300.0) # 16万立方米
const param_BAT = Dict(:E_rated => 10e5, :SoC_cha_thre => 0.0, :E_device_rated => 1000.0,
    :life_year => 20.0, :cost_initial => 1000.0, :cost_OM => 50.0, :cost_replace => 1000.0) # 100万kWh


const n_sys = 20.0 # 系统设计寿命（年）
const r = 0.03    # 实际利率
const cost_water_per_kg_H2 = 0.021
const eprice_to_grid = 0.2277
const eprice_from_grid = 0.355
const H2price_sale = 25.58 # ￥/kg
const rate_depreciation = 1 / 20
const rate_discount = 0.08  # 目标收益率
const rate_tax = 0.0        # 综合税率

const S3_opt_var_components = [0, 0, 1, 1, 1] # PV,WT,AEC,HT,SoC_HT_cha_thre是否优化

const S3_opt_var_lower_boundary = [1e5, 1e5, 0.1]
const S3_opt_var_upper_boundary = [1e6, 1e6, 0.9]

# res, _ = simulation_RE2H2(S3_data_GI, S3_data_Ta, S3_data_WS, S3_data_H2L,
#     param_PV, param_WT, param_AEC, param_HT,
#     eprice_to_grid;
# );

# PV = res["PV₊W(t)"]
# WT = res["WT₊W(t)"]
# AEC = res["AEC₊W(t)"]
# GRID = res["GRID₊ΔE(t)"]
# HT = [max(0, i) for i in res["HT₊ΔE(t)"]]
# ΔW = @. PV + WT - (AEC + GRID + HT)

# @test isapprox(ΔW, zeros(length(ΔW)), atol=1e-3)

# simulation_RE2H2(S3_data_GI, S3_data_Ta, S3_data_WS, S3_data_H2L,
#     param_PV, param_WT, param_AEC, param_HT
# );

# simulation_RE2H2(S3_data_GI, S3_data_Ta, S3_data_WS, S3_data_H2L,
#     param_PV, param_WT, param_AEC, param_HT, param_BAT
# );

# optimization_RE2H2(S3_data_GI, S3_data_Ta, S3_data_WS, S3_data_H2L,
#     param_PV, param_WT, param_AEC, param_HT,
#     eprice_to_grid,
#     opt_var_components,
#     opt_var_lower_boundary,
#     opt_var_upper_boundary,
#     max_opt_time=1
# );

# optimization_RE2H2(S3_data_GI, S3_data_Ta, S3_data_WS, S3_data_H2L,
#     param_PV, param_WT, param_AEC, param_HT,
#     opt_var_components,
#     opt_var_lower_boundary,
#     opt_var_upper_boundary,
#     max_opt_time=1
# );

optimization_RE2H2(S3_data_GI, S3_data_Ta, S3_data_WS, S3_data_H2L,
    param_PV, param_WT, param_AEC, param_HT, param_BAT,
    S3_opt_var_components,
    S3_opt_var_lower_boundary,
    S3_opt_var_upper_boundary,
    max_opt_time=1
);

function generateChannelConstrainData(
    EL_data_24h_1=1e6 .* [3, 3, 3, 3, 3, 3, 3, 3, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 5.6, 3, 3, 3, 3, 3, 3],
    EL_data_24h_2=1e6 .* [4, 4, 4, 4, 4, 4, 4, 5.6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 4, 4, 4, 4, 4]
)
    day_1 = (31 + 28 + 31) #1-3 month
    day_2 = day_1 + (30 + 31 + 30 + 31 + 31 + 30) #4-9 month
    day_3 = day_2 + (31 + 30 + 31) #10-12 month
    EL_data = []
    for i in 1:365
        if 1 <= i <= day_1
            append!(EL_data, EL_data_24h_1)
        elseif day_1 < i <= day_2
            append!(EL_data, EL_data_24h_2)
        else
            append!(EL_data, EL_data_24h_1)
        end
    end
    return EL_data
end


data_weather = CSV.File("src/data/weather_Haixi_Delingha_2021.csv"; select=["glob_hor_rad", "DBT", "wind_speed"])
const S1_data_GI = data_weather.glob_hor_rad
const S1_data_Ta = data_weather.DBT
const S1_data_WS = data_weather.wind_speed
const S1_data_EL = generateChannelConstrainData()

const param_GT = Dict(:E_rated => 4e6, :E_device_rated => 1000.0, :η_inverter => 0.95,
    :life_year => 25.0, :cost_initial => 4800.0 + 100.0, :cost_OM => 160.0, :cost_replace => 4800.0 + 100.0) # 
const param_CP = Dict(:E_rated => 4e6, :E_device_rated => 1000.0, :η_inverter => 0.95,
    :life_year => 25.0, :cost_initial => 15200.0 + 100.0, :cost_OM => 248.0, :cost_replace => 15200.0 + 100.0) # 

# sol_simu, dict_res_simu = simulation_RE2Channel(
#     S1_data_GI, S1_data_Ta, S1_data_WS, S1_data_EL,
#     param_PV, param_WT, param_BAT)

# PV_W = sol_simu["PV₊W(t)"]
# WT_W = sol_simu["WT₊W(t)"]
# BAT_ΔW = sol_simu["BAT₊ΔE(t)"]
# ELBUS_ΔE = sol_simu["ELBUS₊ΔE(t)"]
# EL = sol_simu["EL₊u₊u(t)"]

# ΔW = PV_W + WT_W - (ELBUS_ΔE + EL + BAT_ΔW)
# println(minimum(ΔW))#: -1.1641532182693481e-10
# println(maximum(ΔW))#: 2.9103830456733704e-11