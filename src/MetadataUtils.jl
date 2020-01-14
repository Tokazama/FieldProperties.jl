"""
    MetadataUtils

`MetadataUtils` provides an interface for creating method/property based
APIs that can be flexibly incorporated into Julia structures. This is predominantly
accomplished through the use of [`@defproperty`](@ref) and [`@assignprops`](@ref).
These macros help in the creation of methods and mapping them to the fields of a
concrete type. Additionally, customization is provided through the use of
[`propconvert`](@ref), [`propdefault`](@ref), and [`proptype`](@ref) which can
be overloaded to provide unique functionality given the unique combination of a
property and type.
"""
module MetadataUtils

using Markdown

export
    # Types
    AbstractMetadata,
    Description,
    DictProperty,
    Modality,
    NotProperty,
    NoopMetadata,
    NestedProperty,
    Property,
    Status,
    # Macros
    @defprop,
    @assignprops,
    # methods
    propconvert,
    propdefault,
    propdoc,
    property,
    propname,
    proptype

include("defprop.jl")
include("assignprops.jl")
include("properties.jl")
include("getter.jl")
include("setter.jl")
include("general.jl")
include("metadata.jl")

end
