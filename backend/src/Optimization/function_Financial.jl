"""
设备的初始投资 = 每个设备的初始成本 * 每个设备的总装机容量

- `machine` 设备
"""
initialInvestment(machine::EnergyEquipment) = machine.cost_initial * machine.capacity

"""
设备的运维成本 = 每个设备的年运维成本 * 每个设备的总装机容量

- `machine` 设备
"""
annualOperationCost(machine::EnergyEquipment) = machine.cost_OM * machine.capacity

"""
设备的更换成本 = 更换成本 * (系统设计寿命/每个设备的使用年限)[向下取整]

- `machine` 设备
- `fin` 经济参数
"""
replacementCost(machine::EnergyEquipment, fin::Financial) = fin.n_sys > machine.life_year ? machine.cost_replace * machine.capacity * ceil(fin.n_sys / machine.life_year) : 0

"""
设备的总成本 = 设备的初始投资 + 设备的运维成本 + 设备的更换成本

- `machine` 设备
- `fin` 财务参数
"""
totalCost(machine::EnergyEquipment, fin::Financial) = initialInvestment(machine) + annualOperationCost(machine) + replacementCost(machine, fin)


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
每方氢气的成本 = 总成本/生产的氢气总量

- `capacity` 气量
- `cost` 成本
"""
costH2(capacity,cost) = cost/capacity



