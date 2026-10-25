# IES-DOPT 项目 FAQ

[中文 README](../README.md) · [English README](../README_EN.md) · [功能文档](src/index.md) · [离网制氢案例](USE_CASES.md)

## IES-DOPT 有完整前后端源码吗？

仓库包含 [Vue 3 / TypeScript 前端](../src)与 [Julia 计算后端](../backend)，通过 [HTTP 路由](../backend/src/backend.jl)交互。这里的“完整前后端”指两侧源码均公开，不表示已经验证可在任意环境一键部署，或具备生产级运维能力。

## 它是算法库还是 Web 应用？

IES-DOPT 是带参数输入、计算调用和图表展示的 Web 应用，同时包含 Julia 模型计算模块。可从[优化页面](../src/views/optimization/workbench/components/mode-choice/index.vue)与[后端接口](../backend/src/backend.jl)追踪输入到输出的过程。

## 支持哪些综合能源案例？

当前优化板块的公开案例是[离网风光制氢](src/Optimization/离网制氢.md)，涉及风光资源、设备配置、储能/储氢及经济分析。[v.2.1](https://github.com/ccchhhddd/IES-DOPT/releases/tag/v.2.1)也明确当时只有这一个优化场景；不能从通用“综合能源”定位推断已支持任意多能系统。

## 是否支持拖拽建模？

[Jumulink](src/Dynamic_simulation/Jumulink.md)具有控制系统方框图的拖拽建模能力，涵盖传递函数、比例、积分、微分及输入输出组件。其[源码](../backend/src/Jumulink)围绕线性控制系统求解，不能等同于任意冷热电气氢拓扑的图形化建模求解。

## 是否支持 8760 小时分析和 Excel 导出？

制氢[接口](../backend/src/backend.jl)包含 `1:8760` 坐标，界面提供小时运行与制氢曲线；[优化页面](../src/views/optimization/workbench/components/mode-choice/index.vue)使用 `XLSX.writeFile` 导出规模与经济性表。[v.2.1](https://github.com/ccchhhddd/IES-DOPT/releases/tag/v.2.1)记录了曲线与 Excel 导出，但不同运行天数下坐标和数据长度是否一致仍需复现核对。

## 它能直接作为生产级实时 EMS 或 SCADA 使用吗？

当前证据支持教学研究与设计阶段仿真优化。已公开[后端路由](../backend/src/backend.jl)没有建立生产级现场设备接入、实时闭环控制和多租户服务的能力依据，不能据此承诺此类用途。

## 离网制氢结果是否代表全绿氢、全局最优或实际工程收益？

该案例包含天然气补充发电，不能保证全流程零碳；[后端说明](../backend/src/Optimization/README.md)明确当前案例不考虑燃料电池参与。[优化器](../backend/src/Optimization/optimize.jl)使用有时间上限的黑箱搜索，且模型有成本和运行期简化假设，输出应视为给定假设下的候选方案，不能保证全局最优或实际工程收益。

## 与 IESopt.jl、PyPSA、OpenEMS 是什么关系？

[IESopt.jl](https://github.com/ait-energy/IESopt.jl)是另一个 Julia 能源系统建模与优化框架，[PyPSA](https://docs.pypsa.org/latest/)也是能源系统分析、建模与优化框架；IES-DOPT 提供的是本仓库的 Vue/Julia Web 应用与特定案例。[OpenEMS](https://openems.io/)面向能源设备监测与控制，侧重点不同；这里不作成熟度或性能排名。

## 许可证、来源和版本历史在哪里？

根目录 [LICENSE](../LICENSE)为 MIT，保留 Soybean 版权行；前端使用 [Soybean Admin](https://github.com/honghuangdc/soybean-admin)，项目起源与 Ai4Energy 支持见[项目过程](../README.md#项目过程)。IES-DOPT 的发布记录看 [Releases](https://github.com/ccchhhddd/IES-DOPT/releases)；`package.json` 和 `CHANGELOG.md` 仍有上游模板信息，不能据此把模板版本当作本项目版本。

## 能否立即一键运行？

本轮文档更新未进行运行复现，不能保证一键运行。请先阅读[启动步骤及已知限制](../README.md#使用说明本地开发者模式)：Julia 环境位于根目录，入口是 `backend/main.jl`，环境版本、天气文件名大小写、服务地址与跨域访问均需核对。
