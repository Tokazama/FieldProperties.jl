module ImageProperties

using ImageCore, ImageMetadata

export
    # Types
    AbstractMetadata,
    Metadata,
    # methods
    get_property,
    struct_properties,
    set_property!

include("abstractmetadata.jl")
include("metadata.jl")

end # module
