"""
    FieldProperties

`FieldProperties` provides an interface for creating method/property based
APIs that can be flexibly incorporated into Julia structures. This is predominantly
accomplished through the use of [`@defprop`](@ref) and [`@properties`](@ref).
These macros help in the creation of methods and mapping them to the fields of a
concrete type.
"""
module FieldProperties

using Markdown

export
    # Types
    AbstractMetadata,
    Metadata,
    NoopMetadata,
    AbstractProperty,
    # Macros
    @defprop,
    @properties,
    propdoc,
    propdoclist,
    propname,
    proptype

include("abstractproperty.jl")
include("macro_utilities.jl")
include("defprop.jl")
include("properties.jl")
include("general.jl")
include("metadata.jl")

end
