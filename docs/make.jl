using FlatGeobuf
using Documenter

makedocs(;
    modules=[FlatGeobuf],
    authors="Maarten Pronk <git@evetion.nl> and contributors",
    repo="https://github.com/evetion/FlatGeobuf.jl/blob/{commit}{path}#L{line}",
    sitename="FlatGeobuf.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://evetion.github.io/FlatGeobuf.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/evetion/FlatGeobuf.jl",
)
