module FieldProperties

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end FieldProperties

using Markdown
using DocStringExtensions
using MetadataArrays

export
    # Types
    AbstractPropertyList,
    PropertyList,
    NoopPropertyList,
    AbstractProperty,
    GETPROPERTY,
    SETPROPERTY,
    # Macros
    @defprop,
    @properties,
    propconvert,
    # general properties
    description,
    description!,
    description_list,
    status,
    status!,
    name,
    name!,
    label,
    label!,
    calmax,
    calmax!,
    calmin,
    calmin!

include("abstractproperty.jl")
include("macro_utilities.jl")
include("defprop.jl")
include("documentation.jl")
include("properties.jl")
include("general.jl")
include("propertylist.jl")

end
