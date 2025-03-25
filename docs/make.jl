using Documenter
format = Documenter.HTML(assets=["assets/css/notes.css"])

Static_simulation = map(file -> joinpath("Static_simulation", file), readdir(joinpath(@__DIR__, "src", "Static_simulation")))
Dynamic_simulation = map(file -> joinpath("Dynamic_simulation", file), readdir(joinpath(@__DIR__, "src", "Dynamic_simulation")))
Optimization = map(file -> joinpath("Optimization", file), readdir(joinpath(@__DIR__, "src", "Optimization")))

makedocs(
    sitename="综合能源系统仿真优化平台",
    strict=[
             :doctest,
             :linkcheck,
             :parse_error,
             :example_block,
             # Other available options are
             # :autodocs_block, :cross_references, :docs_block, :eval_block, :example_block, :footnote, :meta_block, :missing_docs, :setup_block
    ],
    pages=[
        "主页" => "index.md",
        "静态仿真"=>Static_simulation,
        "动态仿真"=>Dynamic_simulation,
        "优化" => Optimization,
    ],
    format=format,
)


deploydocs(
    repo="https://github.com/ccchhhddd/IES-DOPT";
    push_preview=true
    #    target = "../build",
)
