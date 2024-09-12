using PhyLiNC
using Documenter

DocMeta.setdocmeta!(PhyLiNC, :DocTestSetup, :(using PhyLiNC); recursive=true)

makedocs(;
    modules=[PhyLiNC],
    authors="Cecile Ane <cecileane@users.noreply.github.com>, Cora Allen-Savietta <coraallensavietta@users.noreply.github.com>, and contributors",
    sitename="PhyLiNC.jl",
    format=Documenter.HTML(;
        canonical="https://JuliaPhylo.github.io/PhyLiNC.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaPhylo/PhyLiNC.jl",
    devbranch="main",
)
