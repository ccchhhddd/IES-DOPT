"""
设备的初始投资 = 每种设备的初始成本 * 每种设备的总装机容量

- `machine` 设备
"""
initialInvestment(machine::EnergyEquipment) = machine.cost_initial * machine.capacity

"""
设备的运维成本 = 每种设备的年运维成本 * 每种设备的总装机容量 * 系统运行年限[向上取整]

- `machine` 设备
"""
annualOperationCost(machine::EnergyEquipment,fin::Financial) = machine.cost_OM * machine.capacity * ceil(fin.n_sys)

"""
设备的更换成本 = 每种设备的年更换成本 * 每种设备的总装机容量 * 设备更换次数[设备使用年限/每个设备的使用年限,向下取整]

- `machine` 设备
- `fin` 经济参数
"""
replacementCost(machine::EnergyEquipment, fin::Financial) =  machine.cost_replace * machine.capacity * floor(fin.n_sys / machine.life_year) 

"""
设备的总成本 = 设备的初始投资 + 设备的运维成本 + 设备的更换成本

- `machine` 设备
- `fin` 财务参数
"""
totalCost(machine::EnergyEquipment, fin::Financial) = initialInvestment(machine) + annualOperationCost(machine,fin) + replacementCost(machine, fin)


"""
用水成本 = 氢气生产用水成本 * 这段时间内用水总量

- `capacity` 水量
- `fin` 财务参数
"""
costWater(capacity, fin::Financial) = fin.cost_water_per_kg_H2 * capacity

"""
用气成本 = 天然气价格 * 燃气轮机在这段时间的消耗的天然气量

- `capacity` 气电发电量
- `fin` 财务参数
"""
costGas(capacity,fin::Financial) = fin.price_gas_per_Nm3 * capacity

"""
氢气运输成本 = 运输次数[总产氢量/储氢罐总装机容量,向上取整] * 单次运输费用

- `capacity` 总产氢量
- `hs` 储氢罐参数
"""
costH2Transport(capacity,hs::HydrogenStorage,fin::Financial) = ceil(capacity / (hs.capacity))*fin.cost_unit_transport


"""
每方氢气的成本 = 总成本/生产的氢气总量

- `capacity` 气量
- `cost` 成本
"""
costH2(capacity,cost) = cost/capacity



