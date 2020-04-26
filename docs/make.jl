
using Documenter, FieldProperties, DocStringExtensions
include("ExampleModule/src/ExampleModule.jl")
import .ExampleModule

makedocs(;
    modules=[FieldProperties, ExampleModule],
    format=Documenter.HTML(),
    pages=[
        "Introduction" => "index.md",
        "Manual" => Any[
            "creating_properties.md",
            "assign_properties.md",
            "metadata.md",
        ],
        "Examples" => Any[
            "The `onset` Property" => "onset.md",
            "Finding Jeff" => "finding_jeff.md",
            "Example Module" => "example_module.md",
        ],
    ],
    repo="https://github.com/Tokazama/FieldProperties.jl/blob/{commit}{path}#L{line}",
    sitename="FieldProperties.jl",
    authors="Zachary P. Christensen",
)

deploydocs(
    repo = "github.com/Tokazama/FieldProperties.jl.git",
)
