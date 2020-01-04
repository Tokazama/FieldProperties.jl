module ImageProperties

using ImageCore, ImageMetadata

export
    # Types
    AbstractMetadata,
    SpatialImage,
    Metadata,
    SpatialProperties,
    # methods
    get_property,
    struct_properties,
    set_property!

include("abstractmetadata.jl")
include("metadata.jl")
include("spatialproperties.jl")

end # module
