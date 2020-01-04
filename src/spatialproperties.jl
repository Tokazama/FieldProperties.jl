
struct SpatialProperties{M,S<:Tuple} <: AbstractMetadata{M}
    spacedirections::S
    properties::M
end

function SpatialProperties(; spacedirections::Tuple, kwargs...)
    out = SpatialProperties(spacedirections, Dict{Symbol,Any}())
    for (k,v) in kwargs
        out[k] = v
    end
    return out
end

ImageMetadata.properties(m::SpatialProperties) = getfield(m, :properties)

ImageCore.spacedirections(m::SpatialProperties) = getfield(m, :spacedirections)

Base.getproperty(m::SpatialProperties, s::Symbol) = get_property(m, s)

Base.setproperty!(m::SpatialProperties, s::Symbol, val) = set_property!(m, s, val)

struct_properties(::Type{<:SpatialProperties}) = (:spacedirections,)

const SpatialImage{T,N,A,M<:SpatialProperties} = ImageMeta{T,N,A,M}

function SpatialImage(
    img::AbstractArray;
    spacedirections=spacedirections(img),
    kwargs...
   )
    return ImageMeta(img, SpatialProperties(;
        spacedirections=spacedirections,
        kwargs...)
    )
end

function ImageCore.spacedirections(img::ImageMeta{T,N,<:AbstractArray{T,N},<:SpatialProperties}) where {T,N}
    return spacedirections(properties(img))
end
