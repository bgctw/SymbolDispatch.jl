using SymbolDispatch
using Documenter

DocMeta.setdocmeta!(SymbolDispatch, :DocTestSetup, :(using SymbolDispatch); recursive=true)

makedocs(;
    #modules=[SymbolDispatch],
    authors="Thomas Wutzler <twutz@bgc-jena.mpg.de> and contributors",
    repo="https://github.com/bgctw/SymbolDispatch.jl/blob/{commit}{path}#{line}",
    sitename="SymbolDispatch.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://bgctw.github.io/SymbolDispatch.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/bgctw/SymbolDispatch.jl",
    devbranch="main",
)
