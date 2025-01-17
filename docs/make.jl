using Documenter, WiNDC, PATHSolver



const _PAGES = [
    "Introduction" => ["index.md"],
    #"Data" => ["data/core.md"],
    #"National Module" => ["national/overview.md"]
    #"Core Module" => ["core/overview.md","core/national_model.md","core/national_set_list.md","core/state_model.md","core/set_listing.md"]
    
]


makedocs(
    sitename="WiNDC.jl",
    format = Documenter.HTML(),
    modules = [WiNDC],
    pages = _PAGES
)



deploydocs(
    repo = "https://github.com/uw-windc/WiNDC.jl",
    target = "build",
    branch = "gh-pages",
    #versions = ["stable" => "v^", "v#.#" ],
)