using Documenter, WiNDC, GamsStructure, PATHSolver



const _PAGES = [
    "Introduction" => ["index.md"],
    "Data" => ["data/core.md"],
    "Core Module" => ["core/overview.md","core/set_listing.md"]
    
]


makedocs(
    sitename="WiNDC.jl",
    authors="WiNDC",
    #format = Documenter.HTML(
    #    # See https://github.com/JuliaDocs/Documenter.jl/issues/868
    #    prettyurls = get(ENV, "CI", nothing) == "true",
    #    analytics = "UA-44252521-1",
    #    collapselevel = 1,
    #    assets = ["assets/extra_styles.css"],
    #    sidebar_sitename = false,
    #),
    #strict = true,
    pages = _PAGES
)



deploydocs(
    repo = "https://github.com/uw-windc/WiNDC.jl",
    target = "build",
    branch = "gh-pages",
    versions = ["stable" => "v^", "v#.#" ],
)