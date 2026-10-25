# IES-DOPT — Integrated Energy System Simulation & Optimization Platform

IES-DOPT is an **open-source full-stack web platform** for integrated energy system simulation and design optimization. It combines a **Vue 3 / TypeScript frontend** with a **Julia scientific-computing backend**. Documented applications include engineering simulations, Jumulink block-diagram control-system simulation, and off-grid wind/solar-to-hydrogen capacity optimization.

[English](README_EN.md) · [中文](README.md) · [Documentation](https://ccchhhddd.github.io/IES-DOPT/) · [Releases](https://github.com/ccchhhddd/IES-DOPT/releases) · [FAQ (Chinese)](docs/PROJECT_FAQ.md) · [Hydrogen case study (Chinese)](docs/USE_CASES.md)

## Features and evidence

| Capability | Implemented scope and evidence |
| --- | --- |
| Engineering simulation | Rankine, reheat and refrigeration cycles; parallel/counterflow heat exchangers; Venturi pressure distribution; PID experiments. See the [model code](backend/src/Simulation), [PID code](backend/src/Controler) and [documentation](docs/src/index.md). |
| Graphical dynamic simulation | Jumulink provides drag-and-drop control-system blocks, transfer functions and response plots. See the [guide](docs/src/Dynamic_simulation/Jumulink.md), [frontend](src/views/controler/scenario) and [Julia backend](backend/src/Jumulink). |
| Energy system design optimization | The documented case is off-grid hydrogen production, with equipment capacity selection, three optimization objectives and a choice of black-box search methods. See the [case documentation](docs/src/Optimization/离网制氢.md) and [optimizer](backend/src/Optimization/optimize.jl). |
| Visualization and export | Weather/resource, hourly operation and hydrogen-production plots, plus Excel export of scale/economics tables. The [API](backend/src/backend.jl) exposes 8760-hour axes; the [frontend](src/views/optimization/workbench/components/mode-choice/index.vue) implements table export. |

## Architecture

```text
Vue 3 / TypeScript frontend (src/)
              ↕ HTTP / JSON
Julia / Oxygen computation backend (backend/)
  ├─ Engineering simulation and PID experiments
  ├─ Jumulink linear control-system simulation
  └─ Off-grid hydrogen simulation and capacity optimization
```

The frontend uses Vite, Naive UI, ECharts and Vue Flow, building on Soybean Admin. The backend includes ModelingToolkit, DifferentialEquations, CoolProp and BlackBoxOptim. Both sides of the web application are available in this repository; [backend routes](backend/src/backend.jl) connect user inputs to model outputs.

## Project status and limits

| Status | Meaning |
| --- | --- |
| Implemented | The models, UI, APIs and exports above are supported by source, documentation and historical releases. This does not mean the application was run and reproduced during this documentation update. |
| Partial or experimental | The hydrogen case is a research prototype with simplified operating logic and economic assumptions. Black-box search does not guarantee a global optimum. The fixed 8760-hour API axes need validation against the chosen duration and data lengths. |
| Planned | Additional optimization scenarios and improvements to equipment/operating logic are listed in [v.2.1](https://github.com/ccchhhddd/IES-DOPT/releases/tag/v.2.1); they are not current capabilities. |

IES-DOPT focuses on research, education and design-time analysis. Jumulink models control-system block diagrams; arbitrary integrated-energy topology solving has not been established. Production-ready device integration, real-time EMS/SCADA and multi-tenant services are not verified capabilities. The hydrogen case includes natural-gas backup generation, so it does not establish zero-carbon hydrogen production. Fuel-cell participation is excluded from the current case in the [backend notes](backend/src/Optimization/README.md).

As of 2026-10-25, the latest published release is **v.2.1 (2024-03-16)**. Use [IES-DOPT Releases](https://github.com/ccchhhddd/IES-DOPT/releases) for this project's release history; the root `CHANGELOG.md` retains Soybean Admin template history.

## Getting started

The [Chinese README](README.md#使用说明本地开发者模式) contains the maintained setup notes and [historical Docker deployment procedure](README.md#部署服务器). A complete English tutorial is not yet available. The source-based local commands are:

```shell
git clone https://github.com/ccchhhddd/IES-DOPT.git
cd IES-DOPT
npm install
npm run dev
```

In a separate terminal, starting at the repository root:

```shell
julia --project=. -e 'using Pkg; Pkg.instantiate()'
cd backend
julia --project=.. main.jl
```

These commands were checked against repository files, not executed in this update. The root `Manifest.toml` records Julia 1.11.2, whereas the backend Dockerfile uses Julia 1.9.2; the supported range needs reproduction. Some weather-data references differ in filename case, and service addresses/cross-origin access need checking for the chosen environment. One-click startup is not promised.

## Related project scope

IES-DOPT supplies a Vue/Julia web application with specific educational and design examples. [PyPSA](https://docs.pypsa.org/latest/) and [IESopt.jl](https://github.com/ait-energy/IESopt.jl) focus on energy-system modeling and optimization frameworks; IESopt.jl is a separate project. [OpenEMS](https://openems.io/) focuses on energy-device monitoring and control. These scope differences do not imply a feature-completeness or performance ranking.

## Documentation, history and license

- [Source documentation (Chinese)](docs/src/index.md) and [online documentation](https://ccchhhddd.github.io/IES-DOPT/) — the website is a documentation site.
- [Releases](https://github.com/ccchhhddd/IES-DOPT/releases) and [project history](README.md#项目过程).
- [MIT license](LICENSE), retaining `Copyright (c) 2021 Soybean`. The frontend builds on [Soybean Admin](https://github.com/honghuangdc/soybean-admin); preserve upstream attribution and check individual dependency licenses.

The original project history records its origin in a 2023 student innovation project at Xi'an Jiaotong University and support from [Ai4Energy](https://github.com/ai4energy).
