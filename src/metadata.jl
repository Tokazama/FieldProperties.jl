
"""
    Metadata{D}

Subtype of `AbstractMetadata` that provides `getproperty` syntax for accessing
the values of a dictionary.
"""
struct Metadata{D} <: AbstractMetadata{D}
    properties::D
end

ImageMetadata.properties(m::Metadata) = getfield(m, :properties)

function Metadata(; kwargs...)
    out = Metadata(Dict{Symbol,Any}())
    for (k,v) in kwargs
        out[k] = v
    end
    return out
end

Base.getproperty(m::Metadata, s::Symbol) = getindex(properties(m), s)

Base.setproperty!(m::Metadata, s::Symbol, val) = setindex!(properties(m), val, s)
