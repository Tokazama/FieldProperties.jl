"""
    AbstractMetadata
"""
abstract type AbstractMetadata{D<:AbstractDict{Symbol,Any}} <: AbstractDict{Symbol,Any} end

Base.empty!(m::AbstractMetadata) = empty!(dictextension(m))

Base.get(m::AbstractMetadata, k, default) = get(dictextension(m), k, default)

Base.get!(m::AbstractMetadata, k, default) = get!(dictextension(m), k, default)

# TODO
#Base.in(k, m::AbstractMetadata) = in(k, propname(m))

#Base.pop!(m::AbstractMetadata, k) = pop!(dictextension(m), k)

#Base.pop!(m::AbstractMetadata, k, default) = pop!(dictextension(m), k, default)

Base.isempty(m::AbstractMetadata) = isempty(dictextension(m))

Base.delete!(m::AbstractMetadata, k) = delete!(dictextension(m), k)

@inline Base.getindex(x::AbstractMetadata, s::Symbol) = getindex(dictextension(x), s)

@inline function Base.setindex!(x::AbstractMetadata, val, s::Symbol)
    return setindex!(dictextension(x), val, s)
end

Base.length(m::AbstractMetadata) = length(propertynames(m))

Base.getkey(m::AbstractMetadata, k, default) = getkey(dictextension(m), k, default)

Base.keys(m::AbstractMetadata) = propertynames(m)

suppress(m::AbstractMetadata) = get(m, :suppress, ())

Base.show(io::IO, m::AbstractMetadata) = showdictlines(io, m, suppress(m))
Base.show(io::IO, ::MIME"text/plain", m::AbstractMetadata) = showdictlines(io, m, suppress(m))
function showdictlines(io::IO, m, suppress)
    print(io, summary(m))
    for (k, v) in m
        if !in(k, suppress)
            print(io, "\n    ", k, ": ")
            print(IOContext(io, :compact => true), v)
        else
            print(io, "\n    ", k, ": <suppressed>")
        end
    end
end

function Base.iterate(m::AbstractMetadata, state=1)
    out = iterate_struct(m, state)
    if isnothing(out)
        np = length(assigned_fields(m))
        out = iterate(dictextension(m), state - np)
        if isnothing(out)
            return nothing
        else
            k, i = out
            return k, i + np
        end
    else
        return out
    end
end

@inline function iterate_struct(m::AbstractMetadata, state = 1)
    pnames = assigned_fields(m)
    if state > length(pnames)
        return nothing
    else
        p = @inbounds(pnames[state])
        return Pair(p, getproperty(m, p)), state + 1
    end
end

"""
    NoopMetadata

Empty dictionary that indicates there is no metadata.
"""
struct NoopMetadata <: AbstractMetadata{Dict{Symbol,Any}} end

Base.isempty(::NoopMetadata) = true

Base.get(::NoopMetadata, k, default) = default

Base.length(::NoopMetadata) = 0

Base.haskey(::NoopMetadata, k) = false

Base.in(k, ::NoopMetadata) = false

Base.propertynames(::NoopMetadata) = ()

Base.iterate(m::NoopMetadata) = nothing

Base.iterate(m::NoopMetadata, state) = nothing

function Base.setindex!(m::NoopMetadata, val, s::Symbol)
    error("Cannot set property for NoopMetadata.")
end

"""
    Metadata{D}

Subtype of `AbstractMetadata` that provides `getproperty` syntax for accessing
the values of a dictionary.
"""
struct Metadata{D} <: AbstractMetadata{D}
    dictextension::D
end

function Metadata(; kwargs...)
    out = Metadata(Dict{Symbol,Any}())
    for (k,v) in kwargs
        out[k] = v
    end
    return out
end

@assignprops(Metadata, :dictextension => dictextension)
