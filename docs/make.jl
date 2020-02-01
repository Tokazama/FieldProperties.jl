using Documenter, FieldProperties

makedocs(;
    modules=[FieldProperties],
    format=Documenter.HTML(),
    pages=[
        "Introduction" => "index.md",
        "Manual" => Any[
            "creating_properties.md",
            "assign_properties.md"
        ],
    ],
    repo="https://github.com/Tokazama/FieldProperties.jl/blob/{commit}{path}#L{line}",
    sitename="FieldProperties.jl",
    authors="Zachary P. Christensen",
)

