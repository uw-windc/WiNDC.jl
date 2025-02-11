using Documenter, WiNDC, PATHSolver



const _PAGES = [
    "Introduction" => ["index.md"],
    "Data" => ["data/core.md"],
    "National Module" => ["national/overview.md"],
    "API" => ["api.md"]
    
]


makedocs(
    sitename="WiNDC.jl",
    authors="WiNDC",
    format = Documenter.HTML(),
    modules = [WiNDC],
    pages = _PAGES
)



deploydocs(
    repo = "https://github.com/uw-windc/WiNDC.jl",
    target = "build",
    branch = "gh-pages",
    devbranch = "dev",
    versions = ["stable" => "v^", "v#.#", "dev" => "dev" ],
    push_preview = true
)