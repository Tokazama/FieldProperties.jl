using Documenter, FieldProperties

makedocs(;
    modules=[FieldProperties],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
        "Manual" => Any[
            "creating_properties.md",
            "structures_with_properties.md"
            "internal_design.md"
        ],
        "Examples" => Any[
            "finicky_api.md",
            "adapting_existing_properties.md",
            "stacking_properties.md"
        ]
    ],
    repo="https://github.com/Tokazama/FieldProperties.jl/blob/{commit}{path}#L{line}",
    sitename="FieldProperties.jl",
    authors="Zachary P. Christensen",
)
