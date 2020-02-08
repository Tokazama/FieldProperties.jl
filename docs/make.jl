using Documenter, FieldProperties

makedocs(;
    modules=[FieldProperties],
    format=Documenter.HTML(),
    pages=[
        "Introduction" => "index.md",
        "Manual" => Any[
            "creating_properties.md",
            "assign_properties.md",
            "metadata.md",
            "general_properties.md",
            "property_documentation.md",
        ],
        "Examples" => Any[
            "The `onset` Property" => "onset.md",
            "Finding Jeff" => "finding_jeff.md",
        ]
    ],
    repo="https://github.com/Tokazama/FieldProperties.jl/blob/{commit}{path}#L{line}",
    sitename="FieldProperties.jl",
    authors="Zachary P. Christensen",
)

deploydocs(
    repo = "github.com/Tokazama/FieldProperties.jl.git",
)
