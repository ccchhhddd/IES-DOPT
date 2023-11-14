using CSV
data_weather = CSV.File("src/data/weather_lenghu_2018.csv"; select=["glob_hor_rad", "DBT", "wind_speed"])

const S1_DATA_GI = data_weather.glob_hor_rad
const S1_DATA_TA = data_weather.DBT
const S1_DATA_WS = data_weather.wind_speed
const S1_DATA_LOAD = 5285.41 * ones(Float64, 8760)

include("src/utils.jl")

wt = WindTurbine(input_v=S1_DATA_WS)
pv = PhotovoltaicCell(input_v=S1_DATA_WS, input_GI=S1_DATA_GI, input_Ta=S1_DATA_TA)
ec = ElectrolyticCell(load=S1_DATA_LOAD)
hc = HydrogenCompressor(load=S1_DATA_LOAD)
es = EnergyStorage()
fin = Financial()
cp = CoalPower(capacity=0.0)
gp = GasPower()

machines = (pv, wt, ec, hc, es, cp, gp)

@time simulate!(machines, fin, Val(1));
@time simulate!(machines, fin, Val(2));
@time simulate!(machines, fin, Val(3));
@time simulate!(machines, fin, Val(7));
@time simulate!(deepcopy(machines), fin, Val(8));

optimize!(deepcopy(machines), [1, 1, 0, 0], fin, Val(1));
optimize!(deepcopy(machines), [0, 0, 1, 1, 1], fin, Val(2));
optimize!(deepcopy(machines), [0, 0, 1, 1, 1], fin, Val(3));
optimize!(deepcopy(machines), [1, 1, 0, 0, 0], fin, Val(7));
optimize!(deepcopy(machines), [1, 1, 1, 1, 1, 1, 1], fin, Val(8));
