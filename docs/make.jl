
let doclib = abspath(joinpath(@__DIR__, "ExampleModule", "src"))
    doclib in LOAD_PATH || pushfirst!(LOAD_PATH, doclib)
end

using Documenter
using FieldProperties
using DocStringExtensions
#include("ExampleModule/src/ExampleModule.jl")
import ExampleModule

makedocs(;
    modules=[FieldProperties, ExampleModule],
    format=Documenter.HTML(),
    pages=[
        "Introduction" => "index.md",
        "Properties" => "properties.md",
        "Examples" => Any[
            "The `onset` Property" => "onset.md",
            "Finding Jeff" => "finding_jeff.md",
            "Example Module" => "example_module.md",
        ],
        "Reference" => "reference.md"
    ],
    repo="https://github.com/Tokazama/FieldProperties.jl/blob/{commit}{path}#L{line}",
    sitename="FieldProperties.jl",
    authors="Zachary P. Christensen",
)

deploydocs(
    repo = "github.com/Tokazama/FieldProperties.jl.git",
)
