# 离网风光制氢系统：仿真与容量优化案例

[中文 README](../README.md) · [English README](../README_EN.md) · [FAQ](PROJECT_FAQ.md) · [原始操作文档](src/Optimization/离网制氢.md)

## 问题与适用范围

此案例用于在给定风光资源、设备及经济参数下，比较离网制氢系统的运行和规模经济性，再选择待优化设备容量进行寻优。它是设计阶段的研究原型，涉及风电、光伏、天然气补充发电、电力转换、压缩空气储能、电解、氢气压缩及储氢；当前模型不考虑燃料电池参与，见[后端说明](../backend/src/Optimization/README.md)。

系统结构与运行逻辑见[原始案例](src/Optimization/离网制氢.md)。因含天然气补充发电，不能把“风光制氢”直接解释成全流程零碳制氢。

## 页面输入

| 输入 | 页面中的操作及依据 |
| --- | --- |
| 地区 | 选择地区，加载仓库配套的风光资源数据；当前页面不等同于已支持任意自定义数据上传 |
| 设备 | 选择设备型号、查看参数并设置机组数量；选择参与容量优化的设备 |
| 经济参数 | 设置运行天数、氢气和天然气相关价格，以及所选目标需要的约束 |
| 优化设置 | 选择目标及黑箱搜索方法；不同方法和运行条件可能产生不同候选结果 |

输入字段见[页面实现](../src/views/optimization/workbench/components/mode-choice/index.vue)及[原始操作文档](src/Optimization/离网制氢.md)；后端数据结构见 [structs.jl](../backend/src/Optimization/structs.jl)。

## 计算目标

[optimize.jl](../backend/src/Optimization/optimize.jl)为三种目标分别实现寻优分支：

1. 每方氢气成本最低。
2. 在投资约束下，制氢量最大。
3. 在最低制氢量约束下，总投资成本最低。

后端使用 BlackBoxOptim 对选定设备容量进行搜索，并对候选方案重新仿真。时间限制、搜索范围、运行规则和经济假设都会影响结果，不保证全局最优。

## 页面输出

| 输出 | 含义及依据 |
| --- | --- |
| 风光环境曲线 | 风速、辐射等输入资源的可视化；界面支持日/周查看 |
| 系统小时运行曲线 | 展示风电、光伏和补充发电的运行情况 |
| 制氢曲线 | 展示模型返回的逐小时制氢数据 |
| 规模与经济性表 | 设备数量/容量、模型成本和制氢结果；支持导出 Excel 表格 |

输出接口为 [backend/src/backend.jl](../backend/src/backend.jl) 中的 `/simulation_ies_h2` 和 `/optimization_ies_h2`。其中曲线使用固定 `1:8760` 坐标，实际选定运行期和资源数据长度是否一致需在复现时核对；不能据此宣称任意运行期均已验证。

![离网制氢案例系统小时运行曲线的日视图](src/assets/优化/优化__离网制氢/离网制氢__系统小时运行图（日）.png)

此图复用现有文档的历史界面，用于说明输出形式。本页没有重新运行算例或补充计算数值，也不将原始文档中特定算例的改善百分比推广为一般收益。

## 源码与复核路径

1. 从[前端页面](../src/views/optimization/workbench/components/mode-choice/index.vue)核对地区、目标、求解器和设备输入及 Excel 导出。
2. 从[接口](../backend/src/backend.jl)追踪请求到 [simulate.jl](../backend/src/Optimization/simulate.jl) 和 [optimize.jl](../backend/src/Optimization/optimize.jl)。
3. 从[设备定义](../backend/src/Optimization/structs.jl)、[发电函数](../backend/src/Optimization/function_Electricity.jl)、[产氢函数](../backend/src/Optimization/function_Gas.jl)及[经济函数](../backend/src/Optimization/function_Financial.jl)核对假设与单位。
4. 结合[原始操作文档](src/Optimization/离网制氢.md)与 [v.2.1 发布记录](https://github.com/ccchhhddd/IES-DOPT/releases/tag/v.2.1)对照历史功能。

## 当前限制

- 当前仅整理离网制氢这一公开优化场景；扩展场景和通用能源拓扑求解不能当作现有能力。
- 模型采用小时尺度和简化经济、运行假设；源码注释已指出成本与运行期处理的限制。结果用于给定假设下的研究分析，需独立核对工程适用性。
- 部分天气 CSV 引用与实际文件名的大小写不一致，区分大小写的系统可能无法读取。运行步骤与环境版本差异见[本地开发说明](../README.md#使用说明本地开发者模式)。
- 本次仅核对源码、文档和历史发布证据，未安装依赖、启动服务或重新生成计算结果。
