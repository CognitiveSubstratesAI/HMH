using Documenter
using HMH

DocMeta.setdocmeta!(HMH, :DocTestSetup, :(using FactorVSA, HMH); recursive=true)

makedocs(;
    modules=[HMH],
    authors="CognitiveSubstrates AI",
    repo=Remotes.GitHub("CognitiveSubstratesAI", "HMH"),
    sitename="HMH.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://cognitivesubstratesai.github.io/HMH/stable/",
        edit_link="main",
        assets=String[]
    ),
    pages=[
        "Home" => "index.md",
        "Guide" => "guide.md",
        "API" => "api.md"
    ],
    warnonly=true
)

deploydocs(; repo="github.com/CognitiveSubstratesAI/HMH", devbranch="main")
